import uuid
from datetime import date, datetime
from decimal import Decimal

from pydantic import BaseModel, Field, field_validator


class InventoryBulkItem(BaseModel):
    name: str = Field(min_length=1, max_length=300)
    quantity: Decimal | None = Field(
        default=None, ge=0, max_digits=20, decimal_places=6
    )
    unit: str | None = Field(default=None, max_length=60)
    purchase_unit_price: Decimal | None = Field(
        default=None, ge=0, max_digits=20, decimal_places=6
    )
    selling_price: Decimal | None = Field(
        default=None, ge=0, max_digits=20, decimal_places=6
    )
    line_total: Decimal | None = Field(
        default=None, ge=0, max_digits=20, decimal_places=6
    )
    supplier_name: str | None = Field(default=None, max_length=300)
    invoice_number: str | None = Field(default=None, max_length=120)

    @field_validator("name")
    @classmethod
    def strip_name(cls, value: str) -> str:
        value = value.strip()
        if not value:
            raise ValueError("item name cannot be blank")
        return value

    @field_validator("unit", "supplier_name", "invoice_number")
    @classmethod
    def strip_optional_text(cls, value: str | None) -> str | None:
        if value is None:
            return None
        value = value.strip()
        return value or None


class InventoryBulkAddRequest(BaseModel):
    items: list[InventoryBulkItem] = Field(min_length=1, max_length=500)
    supplier_name: str | None = Field(default=None, max_length=300)
    invoice_number: str | None = Field(default=None, max_length=120)
    idempotency_key: uuid.UUID | None = None

    @field_validator("supplier_name", "invoice_number")
    @classmethod
    def strip_optional_text(cls, value: str | None) -> str | None:
        if value is None:
            return None
        value = value.strip()
        return value or None


class InventoryItemResponse(BaseModel):
    id: uuid.UUID
    name: str
    normalized_name: str
    quantity: Decimal
    unit: str | None
    purchase_unit_price: Decimal | None
    selling_price: Decimal | None
    line_total: Decimal | None
    supplier_name: str | None
    invoice_number: str | None
    category: str | None = None
    shelf_life_days: int | None = None
    last_received_at: datetime | None = None
    expires_at: datetime | date | None = None
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}


class InventoryBulkAddResponse(BaseModel):
    items: list[InventoryItemResponse]
    created: int
    merged: int
