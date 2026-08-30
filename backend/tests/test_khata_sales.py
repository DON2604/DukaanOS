import unittest
import uuid
from datetime import date, datetime, timezone
from decimal import Decimal
from unittest.mock import AsyncMock, patch

from pydantic import ValidationError

from app.models.khata import Customer, KhataEntry, TranscriptInsightBatch
from app.models.inventory import InventoryItem
from app.models.sales import InventoryMovement, Sale, SaleLine
from app.schemas.khata import TranscriptExtraction
from app.schemas.sales import CheckoutRequest
from app.services.gemini import GeminiResponseError, parse_transcript_response
from app.services.notifications import (
    format_restock_telegram,
    format_sale_receipt_telegram,
    notify_sale_receipt,
)
from app.services.analytics import build_dashboard
from app.services.scoring import calculate_customer_score
from app.services.vendor_recommendations import (
    build_vendor_recommendations,
    format_vendor_telegram_message,
)
from app.services.khata import (
    AUTO_CREATE_CONFIDENCE,
    is_explicit_valid_obligation,
    persist_extraction,
    process_transcript,
)
from app.services.restock import classify_item
from app.services.sales import checkout


class VendorRecommendationTests(unittest.IsolatedAsyncioTestCase):
    def test_build_vendor_recommendations_ranks_by_discount_and_price(self):
        recommendations = build_vendor_recommendations(
            item_name="Apples",
            required_quantity=Decimal("50"),
            unit="kg",
        )

        self.assertEqual(recommendations[0].vendor_name, "Green Valley Farms")
        self.assertGreaterEqual(recommendations[0].rank, 1)
        self.assertEqual(recommendations[0].required_quantity, Decimal("50"))
        self.assertIn("discount_pct", recommendations[0].model_dump())

    def test_format_vendor_telegram_message_mentions_requested_quantity(self):
        recommendations = build_vendor_recommendations(
            item_name="Apples",
            required_quantity=Decimal("50"),
            unit="kg",
        )
        message = format_vendor_telegram_message(recommendations)

        self.assertIn("Apples", message)
        self.assertIn("50 kg", message)
        self.assertIn("Green Valley Farms", message)
        self.assertTrue(recommendations[0].is_notification_target)
        self.assertIn("notification recipient", message.lower())

    def test_format_sale_receipt_telegram_contains_billing_details(self):
        message = format_sale_receipt_telegram(
            receipt_number="RCP-123456",
            items=[
                {"name": "Apples", "quantity": Decimal("2"), "unit": "kg", "unit_price": Decimal("40.00"), "line_total": Decimal("80.00")},
                {"name": "Milk", "quantity": Decimal("1"), "unit": "ltr", "unit_price": Decimal("45.00"), "line_total": Decimal("45.00")},
            ],
            subtotal=Decimal("125.00"),
            discount=Decimal("5.00"),
            total=Decimal("120.00"),
            payment_type="cash",
            customer_name="Ravi",
        )

        self.assertIn("RCP-123456", message)
        self.assertIn("Apples", message)
        self.assertIn("₹120.00", message)
        self.assertIn("cash", message.lower())
        self.assertIn("Ravi", message)

    async def test_notify_sale_receipt_sends_directly_to_fixed_chat_id(self):
        with patch("app.services.notifications.send_telegram_message", new=AsyncMock(return_value=True)) as send_mock:
            sent = await notify_sale_receipt(
                receipt_number="RCP-654321",
                items=[
                    {"name": "Apples", "quantity": Decimal("2"), "unit": "kg", "unit_price": Decimal("40.00"), "line_total": Decimal("80.00")},
                ],
                subtotal=Decimal("80.00"),
                discount=Decimal("0.00"),
                total=Decimal("80.00"),
                payment_type="credit",
                customer_name="Sita",
            )

        self.assertTrue(sent)
        send_mock.assert_awaited_once()
        self.assertEqual(send_mock.await_args.args[0], 5791840162)


class CustomerScoringTests(unittest.TestCase):
    def test_good_customer_with_perfect_payment_history(self):
        user_id = uuid.uuid4()
        customer_id = uuid.uuid4()
        entries = [
            KhataEntry(
                id=uuid.uuid4(),
                user_id=user_id,
                customer_id=customer_id,
                entry_type="credit",
                amount=Decimal("500.00"),
            ),
            KhataEntry(
                id=uuid.uuid4(),
                user_id=user_id,
                customer_id=customer_id,
                entry_type="payment",
                amount=Decimal("500.00"),
            ),
            KhataEntry(
                id=uuid.uuid4(),
                user_id=user_id,
                customer_id=customer_id,
                entry_type="credit",
                amount=Decimal("1000.00"),
            ),
            KhataEntry(
                id=uuid.uuid4(),
                user_id=user_id,
                customer_id=customer_id,
                entry_type="payment",
                amount=Decimal("1000.00"),
            ),
        ]
        score_res = calculate_customer_score(entries, Decimal("0.00"))
        self.assertEqual(score_res.category, "good")
        self.assertGreaterEqual(score_res.score, 85)
        self.assertGreaterEqual(score_res.payment_probability_pct, 85)
        self.assertEqual(score_res.payment_count, 2)
        self.assertEqual(score_res.credit_count, 2)
        self.assertEqual(score_res.repayment_rate, Decimal("100"))

    def test_bad_customer_with_zero_payments(self):
        user_id = uuid.uuid4()
        customer_id = uuid.uuid4()
        entries = [
            KhataEntry(
                id=uuid.uuid4(),
                user_id=user_id,
                customer_id=customer_id,
                entry_type="credit",
                amount=Decimal("800.00"),
            ),
            KhataEntry(
                id=uuid.uuid4(),
                user_id=user_id,
                customer_id=customer_id,
                entry_type="credit",
                amount=Decimal("1200.00"),
            ),
        ]
        score_res = calculate_customer_score(entries, Decimal("2000.00"))
        self.assertEqual(score_res.category, "bad")
        self.assertLess(score_res.score, 50)
        self.assertLess(score_res.payment_probability_pct, 50)
        self.assertEqual(score_res.payment_count, 0)
        self.assertEqual(score_res.credit_count, 2)
        self.assertEqual(score_res.repayment_rate, Decimal("0"))

    def test_moderate_customer_with_partial_payment(self):
        user_id = uuid.uuid4()
        customer_id = uuid.uuid4()
        entries = [
            KhataEntry(
                id=uuid.uuid4(),
                user_id=user_id,
                customer_id=customer_id,
                entry_type="credit",
                amount=Decimal("1000.00"),
            ),
            KhataEntry(
                id=uuid.uuid4(),
                user_id=user_id,
                customer_id=customer_id,
                entry_type="payment",
                amount=Decimal("600.00"),
            ),
        ]
        score_res = calculate_customer_score(entries, Decimal("400.00"))
        self.assertEqual(score_res.category, "moderate")
        self.assertTrue(50 <= score_res.score < 75)
        self.assertEqual(score_res.repayment_rate, Decimal("60.00"))

    def test_new_customer_neutral_scoring(self):
        score_res = calculate_customer_score([], Decimal("0.00"))
        self.assertEqual(score_res.category, "moderate")
        self.assertEqual(score_res.score, 70)
        self.assertEqual(score_res.payment_count, 0)
        self.assertEqual(score_res.credit_count, 0)


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

    def test_unknown_obligation_type_degrades_to_ambiguous(self):
        result = parse_transcript_response(
            '{"language":"hi","insights":[],"obligations":[{"person":"A",'
            '"amount":10,"item":null,"quantity":null,"type":"guess",'
            '"due_date":null,"evidence":"x","confidence":1}]}'
        )
        obligation = result.obligations[0]
        self.assertEqual(obligation.type, "ambiguous")
        self.assertFalse(is_explicit_valid_obligation(obligation))

    def test_malformed_fields_do_not_discard_the_batch(self):
        result = parse_transcript_response(
            """{"language":"hinglish","insights":["Ravi ne udhaar liya","","  "],
            "obligations":[
              {"person":null,"amount":0,"type":null,"confidence":null,
               "due_date":"next Monday","evidence":"  "},
              {"person":"Ravi","amount":"1,500","item":"rice","quantity":"2 kg",
               "type":"CREDIT ","due_date":"2026-09-01T00:00:00",
               "evidence":"Ravi ke 1500 baki","confidence":95},
              "not an object"
            ]}"""
        )
        self.assertEqual(result.insights, ["Ravi ne udhaar liya"])
        self.assertEqual(len(result.obligations), 2)

        dropped, kept = result.obligations
        self.assertIsNone(dropped.person)
        self.assertIsNone(dropped.amount)
        self.assertIsNone(dropped.due_date)
        self.assertIsNone(dropped.evidence)
        self.assertEqual(dropped.type, "ambiguous")
        self.assertEqual(dropped.confidence, Decimal("0"))
        self.assertFalse(is_explicit_valid_obligation(dropped))

        self.assertEqual(kept.amount, Decimal("1500"))
        self.assertEqual(kept.quantity, Decimal("2"))
        self.assertEqual(kept.type, "credit")
        self.assertEqual(kept.due_date, date(2026, 9, 1))
        self.assertEqual(kept.confidence, Decimal("0.95"))
        self.assertTrue(is_explicit_valid_obligation(kept))

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
            {"person": None},
            {"evidence": None},
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
        if not self.execute_values:
            return _Result([])
        return _Result(self.execute_values.pop(0))

    def add_all(self, values):
        for value in values:
            self.add(value)

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
                [entry],
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
            {
                "summary",
                "customer_balances",
                "recent_entries",
                "insights",
                "restock_alerts",
                "vendor_recommendations",
            },
        )
        self.assertTrue(dashboard.restock_alerts)
        self.assertTrue(
            any(alert.severity == "critical" for alert in dashboard.restock_alerts)
        )
        self.assertTrue(
            any(
                "running out" in alert.message.lower()
                or "expir" in alert.message.lower()
                for alert in dashboard.restock_alerts
            )
        )
        self.assertGreater(len(dashboard.restock_alerts[0].trend), 1)
        telegram_text = format_restock_telegram(dashboard.restock_alerts)
        self.assertIsNotNone(telegram_text)
        self.assertIn("Aashirvaad Atta", telegram_text)
        self.assertIn("restock", telegram_text.lower())


class ItemIntelligenceTests(unittest.TestCase):
    def test_classifies_perishable_dairy_and_staples(self):
        milk = classify_item("Amul Taaza Milk")
        self.assertEqual(milk.category, "dairy")
        self.assertTrue(milk.perishable)
        self.assertEqual(milk.shelf_life_days, 3)

        atta = classify_item("Aashirvaad Atta 10kg")
        self.assertEqual(atta.category, "staples")
        self.assertFalse(atta.perishable)


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
