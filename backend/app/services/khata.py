import uuid
from datetime import datetime, timezone
from decimal import Decimal

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.khata import Customer, KhataEntry, TranscriptInsightBatch
from app.schemas.khata import (
    CustomerCreate,
    InsightBatchResponse,
    KhataEntryResponse,
    TranscriptAnalyzeRequest,
    TranscriptExtraction,
)
from app.services.gemini import analyze_transcript
from app.services.inventory import normalize_product_text


AUTO_CREATE_CONFIDENCE = Decimal("0.70")


async def get_or_create_customer(
    db: AsyncSession, user_id: uuid.UUID, body: CustomerCreate
) -> Customer:
    normalized = normalize_product_text(body.name)
    result = await db.execute(
        select(Customer).where(
            Customer.user_id == user_id, Customer.normalized_name == normalized
        )
    )
    customer = result.scalar_one_or_none()
    if customer is None:
        customer = Customer(
            user_id=user_id,
            name=body.name.strip(),
            normalized_name=normalized,
            phone=body.phone,
        )
        db.add(customer)
        await db.flush()
    elif body.phone and not customer.phone:
        customer.phone = body.phone
    return customer


def entry_response(entry: KhataEntry, customer_name: str) -> KhataEntryResponse:
    return KhataEntryResponse(
        id=entry.id,
        customer_id=entry.customer_id,
        customer_name=customer_name,
        entry_type=entry.entry_type,
        amount=entry.amount,
        description=entry.description,
        item_name=entry.item_name,
        quantity=entry.quantity,
        due_date=entry.due_date,
        source=entry.source,
        evidence_text=entry.evidence_text,
        confidence=entry.confidence,
        occurred_at=entry.occurred_at,
        is_deleted=entry.is_deleted,
    )


def batch_response(
    batch: TranscriptInsightBatch, duplicate: bool = False
) -> InsightBatchResponse:
    return InsightBatchResponse(
        batch_id=batch.batch_id,
        language=batch.language,
        insights=batch.insights or [],
        unresolved=batch.unresolved or [],
        obligation_count=batch.obligation_count,
        created_at=batch.created_at,
        duplicate=duplicate,
    )


def is_explicit_valid_obligation(obligation, transcript: str | None = None) -> bool:
    valid = (
        obligation.type in {"credit", "payment"}
        and obligation.amount is not None
        and obligation.amount > 0
        and bool(obligation.person.strip())
        and obligation.confidence >= AUTO_CREATE_CONFIDENCE
    )
    if transcript is not None:
        evidence = normalize_product_text(obligation.evidence)
        valid = valid and bool(evidence) and evidence in normalize_product_text(transcript)
    return valid


async def persist_extraction(
    db: AsyncSession,
    user_id: uuid.UUID,
    batch: TranscriptInsightBatch,
    extraction: TranscriptExtraction,
    transcript: str | None = None,
) -> list[tuple[KhataEntry, str]]:
    created: list[tuple[KhataEntry, str]] = []
    unresolved: list[dict] = []
    for obligation in extraction.obligations:
        if not is_explicit_valid_obligation(obligation, transcript):
            unresolved.append(obligation.model_dump(mode="json"))
            continue
        customer = await get_or_create_customer(
            db, user_id, CustomerCreate(name=obligation.person)
        )
        entry = KhataEntry(
            user_id=user_id,
            customer_id=customer.id,
            entry_type=obligation.type,
            amount=obligation.amount,
            description=(
                f"{obligation.item or 'Business obligation'}"
                + (f" × {obligation.quantity}" if obligation.quantity else "")
            ),
            item_name=obligation.item,
            quantity=obligation.quantity,
            due_date=obligation.due_date,
            source="transcript",
            transcript_batch_id=batch.id,
            evidence_text=obligation.evidence,
            confidence=obligation.confidence,
        )
        db.add(entry)
        created.append((entry, customer.name))
    batch.language = extraction.language
    normalized_transcript = normalize_product_text(transcript)
    batch.insights = [
        insight
        for insight in extraction.insights
        if not transcript
        or normalize_product_text(insight) != normalized_transcript
    ]
    batch.unresolved = unresolved
    batch.obligation_count = len(created)
    await db.flush()
    return created


async def process_transcript(
    db: AsyncSession, user_id: uuid.UUID, body: TranscriptAnalyzeRequest
) -> tuple[TranscriptInsightBatch, list[tuple[KhataEntry, str]], bool]:
    result = await db.execute(
        select(TranscriptInsightBatch).where(
            TranscriptInsightBatch.user_id == user_id,
            TranscriptInsightBatch.batch_id == body.batch_id,
        )
    )
    existing = result.scalar_one_or_none()
    if existing is not None:
        return existing, [], True

    # Reserve the idempotency key before the upstream call. The raw transcript is
    # only passed in memory and is never assigned to a model.
    batch = TranscriptInsightBatch(user_id=user_id, batch_id=body.batch_id)
    db.add(batch)
    await db.flush()
    extraction = await analyze_transcript(body.transcript, body.language_hint)
    created = await persist_extraction(db, user_id, batch, extraction, body.transcript)
    return batch, created, False


async def get_user_entry(
    db: AsyncSession, user_id: uuid.UUID, entry_id: uuid.UUID
) -> KhataEntry | None:
    result = await db.execute(
        select(KhataEntry).where(
            KhataEntry.id == entry_id, KhataEntry.user_id == user_id
        )
    )
    return result.scalar_one_or_none()


def soft_delete_entry(entry: KhataEntry) -> None:
    entry.is_deleted = True
    entry.deleted_at = datetime.now(timezone.utc)
