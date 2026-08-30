import re
import uuid
from datetime import date, datetime
from decimal import Decimal, InvalidOperation
from typing import Annotated, Any, Literal

from pydantic import (
    BaseModel,
    Field,
    StringConstraints,
    ValidationError,
    field_validator,
    model_validator,
)


InsightText = Annotated[
    str, StringConstraints(strip_whitespace=True, min_length=1, max_length=300)
]

_OBLIGATION_TYPES = {"credit", "payment", "promise", "ambiguous"}
_NUMBER_PATTERN = re.compile(r"-?\d+(?:\.\d+)?")


def _clean_text(value: Any, limit: int) -> str | None:
    """Coerce a model-supplied value to a trimmed, length-capped string or None."""
    if value is None or isinstance(value, bool):
        return None
    if not isinstance(value, str):
        value = str(value)
    stripped = value.strip()
    return stripped[:limit] if stripped else None


def _clean_number(value: Any) -> Decimal | None:
    """Coerce a model-supplied value to a finite Decimal, or None if unusable."""
    if value is None or isinstance(value, bool):
        return None
    if isinstance(value, str):
        match = _NUMBER_PATTERN.search(value.replace(",", ""))
        if match is None:
            return None
        value = match.group(0)
    try:
        number = Decimal(str(value))
    except (InvalidOperation, ValueError, TypeError):
        return None
    return number if number.is_finite() else None


def _clean_positive(value: Any) -> Decimal | None:
    number = _clean_number(value)
    return number if number is not None and number > 0 else None


class CustomerCreate(BaseModel):
    name: str = Field(min_length=1, max_length=200)
    phone: str | None = Field(default=None, max_length=20)

    @field_validator("name")
    @classmethod
    def strip_name(cls, value: str) -> str:
        return value.strip()

    @field_validator("phone")
    @classmethod
    def strip_phone(cls, value: str | None) -> str | None:
        if value is None:
            return None
        value = value.strip()
        return value or None


class CustomerResponse(BaseModel):
    id: uuid.UUID
    name: str
    phone: str | None
    created_at: datetime
    updated_at: datetime
    model_config = {"from_attributes": True}


class KhataEntryUpdate(BaseModel):
    amount: Decimal | None = Field(default=None, gt=0, max_digits=20, decimal_places=2)
    entry_type: Literal["credit", "payment"] | None = None
    description: str | None = Field(default=None, max_length=500)
    due_date: date | None = None
    is_deleted: bool | None = None


class KhataEntryCreate(BaseModel):
    customer_id: uuid.UUID
    entry_type: Literal["credit", "payment"]
    amount: Decimal = Field(gt=0, max_digits=20, decimal_places=2)
    description: str | None = Field(default=None, max_length=500)
    due_date: date | None = None


class KhataEntryResponse(BaseModel):
    id: uuid.UUID
    customer_id: uuid.UUID
    customer_name: str
    entry_type: Literal["credit", "payment"]
    amount: Decimal
    description: str | None
    item_name: str | None
    quantity: Decimal | None
    due_date: date | None
    source: str
    evidence_text: str | None
    confidence: Decimal | None
    occurred_at: datetime
    is_deleted: bool


class TranscriptAnalyzeRequest(BaseModel):
    batch_id: uuid.UUID
    transcript: str = Field(min_length=1, max_length=20_000)
    language_hint: str | None = Field(default=None, max_length=40)

    @field_validator("transcript")
    @classmethod
    def strip_transcript(cls, value: str) -> str:
        value = value.strip()
        if not value:
            raise ValueError("transcript cannot be blank")
        return value


class TranscriptObligation(BaseModel):
    """A single obligation as reported by the LLM.

    Parsing is deliberately lenient: anything the model gets wrong is degraded to a
    safe value (None, or type "ambiguous") rather than raising, because a single bad
    field would otherwise discard the whole transcript batch. Nothing here decides
    what gets written to the khata -- `is_explicit_valid_obligation` is the gate, and
    it re-checks every field it depends on.
    """

    person: str | None = Field(default=None, max_length=200)
    amount: Decimal | None = Field(default=None, gt=0)
    item: str | None = Field(default=None, max_length=300)
    quantity: Decimal | None = Field(default=None, gt=0)
    type: Literal["credit", "payment", "promise", "ambiguous"] = "ambiguous"
    due_date: date | None = None
    evidence: str | None = Field(default=None, max_length=500)
    confidence: Decimal = Field(default=Decimal(0), ge=0, le=1)

    @field_validator("person", mode="before")
    @classmethod
    def clean_person(cls, value: Any) -> str | None:
        return _clean_text(value, 200)

    @field_validator("item", mode="before")
    @classmethod
    def clean_item(cls, value: Any) -> str | None:
        return _clean_text(value, 300)

    @field_validator("evidence", mode="before")
    @classmethod
    def clean_evidence(cls, value: Any) -> str | None:
        return _clean_text(value, 500)

    @field_validator("amount", "quantity", mode="before")
    @classmethod
    def clean_positive_amounts(cls, value: Any) -> Decimal | None:
        return _clean_positive(value)

    @field_validator("type", mode="before")
    @classmethod
    def clean_type(cls, value: Any) -> str:
        if isinstance(value, str) and value.strip().lower() in _OBLIGATION_TYPES:
            return value.strip().lower()
        # Never guess a direction from an unrecognised label.
        return "ambiguous"

    @field_validator("due_date", mode="before")
    @classmethod
    def clean_due_date(cls, value: Any) -> date | None:
        if value is None or isinstance(value, date):
            return value
        if not isinstance(value, str):
            return None
        try:
            return date.fromisoformat(value.strip()[:10])
        except ValueError:
            return None

    @field_validator("confidence", mode="before")
    @classmethod
    def clean_confidence(cls, value: Any) -> Decimal:
        number = _clean_number(value)
        if number is None or number <= 0:
            return Decimal(0)
        if number > 1:
            # Models sometimes answer on a 0-100 scale.
            number = number / 100 if number <= 100 else Decimal(1)
        return min(number, Decimal(1))


class TranscriptExtraction(BaseModel):
    language: str | None = Field(default=None, max_length=40)
    insights: list[InsightText] = Field(default_factory=list, max_length=10)
    obligations: list[TranscriptObligation] = Field(default_factory=list, max_length=100)

    @model_validator(mode="before")
    @classmethod
    def salvage_payload(cls, data: Any) -> Any:
        """Drop unusable list entries instead of failing the whole extraction."""
        if not isinstance(data, dict):
            return data
        data = dict(data)
        data["language"] = _clean_text(data.get("language"), 40)

        raw_insights = data.get("insights")
        insights: list[str] = []
        if isinstance(raw_insights, list):
            for item in raw_insights:
                text = _clean_text(item, 300)
                if text:
                    insights.append(text)
        data["insights"] = insights[:10]

        raw_obligations = data.get("obligations")
        obligations: list[TranscriptObligation] = []
        if isinstance(raw_obligations, list):
            for item in raw_obligations[:100]:
                if isinstance(item, TranscriptObligation):
                    obligations.append(item)
                    continue
                if not isinstance(item, dict):
                    continue
                try:
                    obligations.append(TranscriptObligation.model_validate(item))
                except ValidationError:
                    continue
        data["obligations"] = obligations
        return data


class InsightBatchResponse(BaseModel):
    batch_id: uuid.UUID
    language: str | None
    insights: list[str]
    unresolved: list[dict]
    obligation_count: int
    created_at: datetime
    duplicate: bool = False


class DashboardSummary(BaseModel):
    revenue: Decimal
    purchases: Decimal
    gain: Decimal
    items_sold: Decimal
    stock_value: Decimal
    receivables: Decimal


class CustomerBalance(BaseModel):
    customer: CustomerResponse
    balance: Decimal
    score: int = 70
    category: Literal["good", "moderate", "bad"] = "moderate"
    trust_label: str = "Moderate"
    payment_count: int = 0
    credit_count: int = 0
    total_credit: Decimal = Decimal("0")
    total_paid: Decimal = Decimal("0")
    repayment_rate: Decimal = Decimal("100")
    payment_probability_pct: int = 70
    payment_probability_label: str = "Moderate (70%)"
    credit_recommendation: str = ""
    reasons: list[str] = Field(default_factory=list)


class DashboardInsight(BaseModel):
    batch_id: uuid.UUID
    language: str | None
    insights: list[str]
    unresolved: list[dict]
    created_at: datetime


class StockTrendPoint(BaseModel):
    day: str
    quantity: Decimal


class RestockAlert(BaseModel):
    item_name: str
    unit: str
    current_stock: Decimal
    days_until_stockout: int
    suggested_restock_qty: Decimal
    severity: Literal["critical", "warning", "watch"]
    message: str
    trend: list[StockTrendPoint]
    item_id: uuid.UUID | None = None
    category: str = "general"
    alert_type: Literal["restock", "expiry"] = "restock"
    days_until_expiry: int | None = None
    expiry_date: date | None = None
    perishable: bool = False
    daily_sales_rate: Decimal = Decimal("0")


class VendorRecommendation(BaseModel):
    item_name: str = "inventory item"
    vendor_name: str
    quoted_price_per_unit: Decimal
    discount_pct: Decimal = Decimal("0")
    final_total: Decimal
    lead_time_days: int = 1
    rating: Decimal = Decimal("0")
    rank: int = 1
    required_quantity: Decimal
    unit: str = "kg"
    notes: str = ""
    contact_number: str = ""
    is_notification_target: bool = False


class KhataDashboard(BaseModel):
    summary: DashboardSummary
    customer_balances: list[CustomerBalance]
    recent_entries: list[KhataEntryResponse]
    insights: list[DashboardInsight]
    restock_alerts: list[RestockAlert] = Field(default_factory=list)
    vendor_recommendations: list[VendorRecommendation] = Field(default_factory=list)


class TranscriptAnalyzeResponse(BaseModel):
    batch: InsightBatchResponse
    created_entries: list[KhataEntryResponse]
    dashboard: KhataDashboard
