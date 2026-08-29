import uuid
from datetime import date, datetime
from decimal import Decimal
from typing import Annotated, Literal

from pydantic import BaseModel, Field, StringConstraints, field_validator


InsightText = Annotated[
    str, StringConstraints(strip_whitespace=True, min_length=1, max_length=300)
]


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
    person: str | None = Field(default=None, max_length=200)
    amount: Decimal | None = Field(default=None, gt=0)
    item: str | None = Field(default=None, max_length=300)
    quantity: Decimal | None = Field(default=None, gt=0)
    type: Literal["credit", "payment", "promise", "ambiguous"]
    due_date: date | None = None
    evidence: str | None = Field(default=None, max_length=500)
    confidence: Decimal = Field(ge=0, le=1)

    @field_validator("person", "item", "evidence")
    @classmethod
    def strip_strings(cls, value: str | None) -> str | None:
        if value is None:
            return None
        stripped = value.strip()
        return stripped if stripped else None


class TranscriptExtraction(BaseModel):
    language: str | None = Field(default=None, max_length=40)
    insights: list[InsightText] = Field(default_factory=list, max_length=10)
    obligations: list[TranscriptObligation] = Field(default_factory=list, max_length=100)


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


class KhataDashboard(BaseModel):
    summary: DashboardSummary
    customer_balances: list[CustomerBalance]
    recent_entries: list[KhataEntryResponse]
    insights: list[DashboardInsight]
    restock_alerts: list[RestockAlert] = Field(default_factory=list)


class TranscriptAnalyzeResponse(BaseModel):
    batch: InsightBatchResponse
    created_entries: list[KhataEntryResponse]
    dashboard: KhataDashboard
