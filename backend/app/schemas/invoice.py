from datetime import date as Date
from decimal import Decimal

from pydantic import BaseModel, Field, field_validator


class InvoiceSupplier(BaseModel):
    name: str | None = None
    phone: str | None = None

    @field_validator("name", "phone")
    @classmethod
    def strip_optional_text(cls, value: str | None) -> str | None:
        if value is None:
            return None
        value = value.strip()
        return value or None


class InvoiceItem(BaseModel):
    name: str = Field(min_length=1, max_length=300)
    quantity: Decimal | None = None
    unit: str | None = Field(default=None, max_length=60)
    unit_price: Decimal | None = None
    total: Decimal | None = None

    @field_validator("name")
    @classmethod
    def strip_name(cls, value: str) -> str:
        value = value.strip()
        if not value:
            raise ValueError("item name cannot be blank")
        return value

    @field_validator("unit")
    @classmethod
    def strip_unit(cls, value: str | None) -> str | None:
        if value is None:
            return None
        value = value.strip()
        return value or None

    @field_validator("quantity", "unit_price", "total")
    @classmethod
    def finite_decimal(cls, value: Decimal | None) -> Decimal | None:
        if value is not None and not value.is_finite():
            raise ValueError("must be a finite decimal")
        return value


class InvoiceAnalysis(BaseModel):
    invoice_number: str | None = Field(default=None, max_length=120)
    date: Date | None = None
    supplier: InvoiceSupplier = Field(default_factory=InvoiceSupplier)
    items: list[InvoiceItem] = Field(min_length=1)
    subtotal: Decimal | None = None
    tax: Decimal | None = None
    grand_total: Decimal | None = None

    @field_validator("invoice_number")
    @classmethod
    def strip_invoice_number(cls, value: str | None) -> str | None:
        if value is None:
            return None
        value = value.strip()
        return value or None

    @field_validator("subtotal", "tax", "grand_total")
    @classmethod
    def finite_decimal(cls, value: Decimal | None) -> Decimal | None:
        if value is not None and not value.is_finite():
            raise ValueError("must be a finite decimal")
        return value
