import uuid

from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, Response, status
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.dependencies import get_current_user
from app.models.khata import Customer, KhataEntry, TranscriptInsightBatch
from app.models.user import User
from app.schemas.khata import (
    CustomerCreate,
    CustomerResponse,
    KhataDashboard,
    KhataEntryCreate,
    KhataEntryResponse,
    KhataEntryUpdate,
    TranscriptAnalyzeRequest,
    TranscriptAnalyzeResponse,
)
from app.services.analytics import build_dashboard
from app.services.gemini import (
    GeminiConfigurationError,
    GeminiResponseError,
    GeminiUpstreamError,
)
from app.services.notifications import notify_restock_if_needed, notify_vendor_if_needed
from app.services.khata import (
    batch_response,
    entry_response,
    get_or_create_customer,
    get_user_entry,
    process_transcript,
    soft_delete_entry,
)


router = APIRouter(prefix="/khata", tags=["khata"])


@router.get("/dashboard", response_model=KhataDashboard)
async def dashboard(
    background_tasks: BackgroundTasks,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> KhataDashboard:
    data = await build_dashboard(db, current_user.id)
    await db.commit()
    background_tasks.add_task(
        notify_restock_if_needed,
        current_user.id,
        current_user.telegram_chat_id,
        data.restock_alerts,
    )
    background_tasks.add_task(
        notify_vendor_if_needed,
        current_user.id,
        data.restock_alerts,
        data.vendor_recommendations,
    )
    return data


@router.post("/transcripts/analyze", response_model=TranscriptAnalyzeResponse)
async def analyze_transcript_batch(
    body: TranscriptAnalyzeRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> TranscriptAnalyzeResponse:
    try:
        batch, created, duplicate = await process_transcript(db, current_user.id, body)
        result = TranscriptAnalyzeResponse(
            batch=batch_response(batch, duplicate),
            created_entries=[
                entry_response(entry, customer_name)
                for entry, customer_name in created
            ],
            dashboard=await build_dashboard(db, current_user.id),
        )
        await db.commit()
        return result
    except GeminiConfigurationError as exc:
        await db.rollback()
        raise HTTPException(status_code=503, detail=str(exc)) from exc
    except (GeminiUpstreamError, GeminiResponseError) as exc:
        await db.rollback()
        raise HTTPException(status_code=502, detail=str(exc)) from exc
    except IntegrityError:
        # A concurrent request may have reserved and completed this user/batch UUID.
        await db.rollback()
        existing = (
            await db.execute(
                select(TranscriptInsightBatch).where(
                    TranscriptInsightBatch.user_id == current_user.id,
                    TranscriptInsightBatch.batch_id == body.batch_id,
                )
            )
        ).scalar_one_or_none()
        if existing is None:
            raise
        return TranscriptAnalyzeResponse(
            batch=batch_response(existing, duplicate=True),
            created_entries=[],
            dashboard=await build_dashboard(db, current_user.id),
        )
    except Exception:
        await db.rollback()
        raise


@router.get("/customers", response_model=list[CustomerResponse])
async def list_customers(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> list[Customer]:
    return list(
        (
            await db.execute(
                select(Customer)
                .where(Customer.user_id == current_user.id)
                .order_by(Customer.name.asc())
            )
        ).scalars()
    )


@router.post(
    "/customers", response_model=CustomerResponse, status_code=status.HTTP_201_CREATED
)
async def create_customer(
    body: CustomerCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> Customer:
    customer = await get_or_create_customer(db, current_user.id, body)
    await db.commit()
    return customer


@router.post(
    "/entries", response_model=KhataEntryResponse, status_code=status.HTTP_201_CREATED
)
async def create_entry(
    body: KhataEntryCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> KhataEntryResponse:
    customer = (
        await db.execute(
            select(Customer).where(
                Customer.id == body.customer_id, Customer.user_id == current_user.id
            )
        )
    ).scalar_one_or_none()
    if customer is None:
        raise HTTPException(status_code=404, detail="Customer not found")
    entry = KhataEntry(
        user_id=current_user.id,
        customer_id=customer.id,
        entry_type=body.entry_type,
        amount=body.amount,
        description=body.description,
        due_date=body.due_date,
        source="manual",
    )
    db.add(entry)
    await db.commit()
    await db.refresh(entry)
    return entry_response(entry, customer.name)


@router.patch("/entries/{entry_id}", response_model=KhataEntryResponse)
async def update_entry(
    entry_id: uuid.UUID,
    body: KhataEntryUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> KhataEntryResponse:
    entry = await get_user_entry(db, current_user.id, entry_id)
    if entry is None:
        raise HTTPException(status_code=404, detail="Khata entry not found")
    if entry.source == "sale":
        raise HTTPException(status_code=409, detail="Sale ledger entries cannot be edited")
    for field, value in body.model_dump(exclude_unset=True).items():
        setattr(entry, field, value)
    if body.is_deleted is False:
        entry.deleted_at = None
    customer_name = (
        await db.execute(select(Customer.name).where(Customer.id == entry.customer_id))
    ).scalar_one()
    await db.commit()
    await db.refresh(entry)
    return entry_response(entry, customer_name)


@router.delete("/entries/{entry_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_entry(
    entry_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> Response:
    entry = await get_user_entry(db, current_user.id, entry_id)
    if entry is None:
        raise HTTPException(status_code=404, detail="Khata entry not found")
    if entry.source == "sale":
        raise HTTPException(status_code=409, detail="Sale ledger entries cannot be deleted")
    soft_delete_entry(entry)
    await db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)
