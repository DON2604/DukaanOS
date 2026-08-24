import unittest
import uuid
from datetime import datetime, timezone
from decimal import Decimal
from unittest.mock import AsyncMock, patch

from pydantic import ValidationError

from app.models.khata import Customer, KhataEntry, TranscriptInsightBatch
from app.models.inventory import InventoryItem
from app.models.sales import InventoryMovement, Sale, SaleLine
from app.schemas.khata import TranscriptExtraction
from app.schemas.sales import CheckoutRequest
from app.services.gemini import GeminiResponseError, parse_transcript_response
from app.services.analytics import build_dashboard
from app.services.khata import (
    AUTO_CREATE_CONFIDENCE,
    is_explicit_valid_obligation,
    persist_extraction,
    process_transcript,
)
from app.services.sales import checkout


class TranscriptParsingTests(unittest.TestCase):
    def test_parses_multilingual_explicit_obligations(self):
        result = parse_transcript_response(
            """```json
            {
              "language": "hi-en",
              "insights": ["Ravi ka ₹500 baki hai"],
              "obligations": [{
                "person": "Ravi",
                "amount": 500,
                "item": "चावल",
                "quantity": 5,
                "type": "credit",
                "due_date": "2026-08-30",
                "evidence": "Ravi ke 500 rupaye baki",
                "confidence": 0.97
              }]
            }```"""
        )
        self.assertEqual(result.obligations[0].amount, Decimal("500"))
        self.assertEqual(result.obligations[0].item, "चावल")

    def test_rejects_invalid_obligation_type(self):
        with self.assertRaises(GeminiResponseError):
            parse_transcript_response(
                '{"language":"hi","insights":[],"obligations":[{"person":"A",'
                '"amount":10,"item":null,"quantity":null,"type":"guess",'
                '"due_date":null,"evidence":"x","confidence":1}]}'
            )

    def test_only_explicit_high_confidence_amounts_are_auto_created(self):
        base = {
            "person": "Ravi",
            "amount": Decimal("10"),
            "item": None,
            "quantity": None,
            "type": "credit",
            "due_date": None,
            "evidence": "Ravi owes ten",
            "confidence": AUTO_CREATE_CONFIDENCE,
        }
        valid = TranscriptExtraction.model_validate(
            {"obligations": [base]}
        ).obligations[0]
        self.assertTrue(is_explicit_valid_obligation(valid))
        for change in (
            {"amount": None},
            {"type": "promise"},
            {"confidence": Decimal("0.69")},
        ):
            obligation = TranscriptExtraction.model_validate(
                {"obligations": [{**base, **change}]}
            ).obligations[0]
            self.assertFalse(is_explicit_valid_obligation(obligation))


class _Result:
    def __init__(self, value):
        self.value = value

    def scalar_one_or_none(self):
        return self.value

    def scalar_one(self):
        return self.value

    def one(self):
        return self.value

    def all(self):
        return self.value

    def scalars(self):
        return _ScalarValues(self.value)


class _ScalarValues:
    def __init__(self, values):
        self.values = values

    def all(self):
        return self.values

    def __iter__(self):
        return iter(self.values)


class _FakeSession:
    def __init__(self, execute_values=()):
        self.execute_values = list(execute_values)
        self.added = []
        self.flush_count = 0

    async def execute(self, _statement):
        return _Result(self.execute_values.pop(0))

    def add(self, value):
        if getattr(value, "id", None) is None:
            value.id = uuid.uuid4()
        self.added.append(value)

    async def flush(self):
        self.flush_count += 1
        now = datetime.now(timezone.utc)
        for value in self.added:
            if hasattr(value, "created_at") and value.created_at is None:
                value.created_at = now
            if hasattr(value, "occurred_at") and value.occurred_at is None:
                value.occurred_at = now
            if hasattr(value, "is_deleted") and value.is_deleted is None:
                value.is_deleted = False


class KhataPersistenceTests(unittest.IsolatedAsyncioTestCase):
    async def test_duplicate_batch_is_returned_without_gemini_call(self):
        user_id = uuid.uuid4()
        existing = TranscriptInsightBatch(
            id=uuid.uuid4(),
            user_id=user_id,
            batch_id=uuid.uuid4(),
            created_at=datetime.now(timezone.utc),
        )
        session = _FakeSession([existing])
        body = type(
            "Body",
            (),
            {
                "batch_id": existing.batch_id,
                "transcript": "raw text",
                "language_hint": None,
            },
        )()
        with patch("app.services.khata.analyze_transcript", new=AsyncMock()) as analyze:
            batch, created, duplicate = await process_transcript(session, user_id, body)
        self.assertIs(batch, existing)
        self.assertEqual(created, [])
        self.assertTrue(duplicate)
        analyze.assert_not_awaited()

    async def test_persists_valid_entry_and_keeps_ambiguous_as_unresolved(self):
        user_id = uuid.uuid4()
        batch = TranscriptInsightBatch(
            id=uuid.uuid4(), user_id=user_id, batch_id=uuid.uuid4()
        )
        extraction = TranscriptExtraction.model_validate(
            {
                "language": "hinglish",
                "insights": ["One explicit debt"],
                "obligations": [
                    {
                        "person": "Ravi",
                        "amount": 250,
                        "type": "credit",
                        "evidence": "Ravi ka 250 baki",
                        "confidence": 0.9,
                    },
                    {
                        "person": "Sita",
                        "amount": None,
                        "type": "ambiguous",
                        "evidence": "Sita ka kuch baki",
                        "confidence": 0.8,
                    },
                ],
            }
        )
        customer = Customer(
            id=uuid.uuid4(),
            user_id=user_id,
            name="Ravi",
            normalized_name="ravi",
        )
        session = _FakeSession()
        with patch(
            "app.services.khata.get_or_create_customer",
            new=AsyncMock(return_value=customer),
        ):
            created = await persist_extraction(
                session, user_id, batch, extraction
            )
        entries = [value for value in session.added if isinstance(value, KhataEntry)]
        self.assertEqual(len(entries), 1)
        self.assertEqual(entries[0].amount, Decimal("250"))
        self.assertEqual(batch.obligation_count, 1)
        self.assertEqual(len(batch.unresolved), 1)
        self.assertFalse(hasattr(batch, "transcript"))


class DashboardAnalyticsTests(unittest.IsolatedAsyncioTestCase):
    async def test_exact_deterministic_analytics_and_dashboard_contract(self):
        now = datetime.now(timezone.utc)
        user_id = uuid.uuid4()
        debtor = Customer(
            id=uuid.uuid4(),
            user_id=user_id,
            name="Ravi",
            normalized_name="ravi",
            created_at=now,
            updated_at=now,
        )
        prepaid = Customer(
            id=uuid.uuid4(),
            user_id=user_id,
            name="Sita",
            normalized_name="sita",
            created_at=now,
            updated_at=now,
        )
        entry = KhataEntry(
            id=uuid.uuid4(),
            user_id=user_id,
            customer_id=debtor.id,
            entry_type="credit",
            amount=Decimal("30"),
            source="manual",
            occurred_at=now,
            is_deleted=False,
        )
        batch = TranscriptInsightBatch(
            id=uuid.uuid4(),
            user_id=user_id,
            batch_id=uuid.uuid4(),
            insights=["Follow up"],
            unresolved=[],
            obligation_count=0,
            created_at=now,
        )
        session = _FakeSession(
            [
                (Decimal("100"), Decimal("60")),
                Decimal("3"),
                Decimal("200"),
                Decimal("40"),
                [(debtor, Decimal("30")), (prepaid, Decimal("-5"))],
                [(entry, debtor.name)],
                [batch],
            ]
        )
        dashboard = await build_dashboard(session, user_id)
        self.assertEqual(
            dashboard.summary.model_dump(),
            {
                "revenue": Decimal("100"),
                "purchases": Decimal("200"),
                "gain": Decimal("40"),
                "items_sold": Decimal("3"),
                "stock_value": Decimal("40"),
                "receivables": Decimal("30"),
            },
        )
        self.assertEqual(
            set(dashboard.model_dump()),
            {"summary", "customer_balances", "recent_entries", "insights"},
        )


class CheckoutContractTests(unittest.TestCase):
    def test_rejects_duplicate_inventory_lines(self):
        item_id = uuid.uuid4()
        with self.assertRaises(ValidationError):
            CheckoutRequest.model_validate(
                {
                    "checkout_id": str(uuid.uuid4()),
                    "payment_type": "cash",
                    "items": [
                        {"inventory_item_id": item_id, "quantity": 1, "unit_price": 10},
                        {"inventory_item_id": item_id, "quantity": 1, "unit_price": 10},
                    ],
                }
            )

    def test_credit_contract_accepts_inline_customer(self):
        body = CheckoutRequest.model_validate(
            {
                "checkout_id": str(uuid.uuid4()),
                "payment_type": "credit",
                "customer": {"name": "Ravi"},
                "items": [
                    {
                        "inventory_item_id": str(uuid.uuid4()),
                        "quantity": "2.5",
                        "unit_price": "12.00",
                    }
                ],
            }
        )
        self.assertEqual(body.items[0].quantity, Decimal("2.5"))


class CheckoutTransactionTests(unittest.IsolatedAsyncioTestCase):
    async def test_checkout_snapshots_cost_and_deducts_inventory(self):
        user_id = uuid.uuid4()
        item = InventoryItem(
            id=uuid.uuid4(),
            user_id=user_id,
            name="Rice",
            normalized_name="rice",
            quantity=Decimal("5"),
            unit="kg",
            normalized_unit="kg",
            purchase_unit_price=Decimal("8"),
            selling_price=Decimal("12"),
        )
        body = CheckoutRequest.model_validate(
            {
                "checkout_id": str(uuid.uuid4()),
                "payment_type": "cash",
                "discount": "5",
                "items": [
                    {
                        "inventory_item_id": str(item.id),
                        "quantity": "2",
                        "unit_price": "12",
                    }
                ],
            }
        )
        session = _FakeSession([None, [item]])
        result = await checkout(session, user_id, body)
        self.assertEqual(item.quantity, Decimal("3"))
        self.assertEqual(result.discount, Decimal("5"))
        self.assertEqual(result.total, Decimal("19.00"))
        self.assertEqual(result.total_cost, Decimal("16.00"))
        movement = next(
            value for value in session.added if isinstance(value, InventoryMovement)
        )
        line = next(value for value in session.added if isinstance(value, SaleLine))
        self.assertEqual(movement.quantity_delta, Decimal("-2"))
        self.assertEqual(line.unit_cost, Decimal("8"))
        self.assertEqual(len([v for v in session.added if isinstance(v, Sale)]), 1)


if __name__ == "__main__":
    unittest.main()
