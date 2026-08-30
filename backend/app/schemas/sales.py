import uuid
from datetime import datetime
from decimal import Decimal
from typing import Literal

from pydantic import BaseModel, Field, model_validator

from app.schemas.khata import CustomerCreate


class ReceiptLineItem(BaseModel):
    name: str
    quantity: Decimal = Field(max_digits=20, decimal_places=6)
    unit: str | None = None
    unit_price: Decimal = Field(ge=0, max_digits=20, decimal_places=2)
    line_total: Decimal = Field(ge=0, max_digits=20, decimal_places=2)


class SendReceiptRequest(BaseModel):
    receipt_number: str
    items: list[ReceiptLineItem] = Field(min_length=1)
    subtotal: Decimal = Field(ge=0, max_digits=20, decimal_places=2)
    discount: Decimal = Field(default=Decimal("0"), ge=0, max_digits=20, decimal_places=2)
    total: Decimal = Field(ge=0, max_digits=20, decimal_places=2)
    payment_type: Literal["cash", "credit"]
    customer_name: str | None = None


class CheckoutLine(BaseModel):
    inventory_item_id: uuid.UUID
    quantity: Decimal = Field(gt=0, max_digits=20, decimal_places=6)
    unit_price: Decimal = Field(ge=0, max_digits=20, decimal_places=2)


class CheckoutRequest(BaseModel):
    checkout_id: uuid.UUID
    payment_type: Literal["cash", "credit"]
    items: list[CheckoutLine] = Field(min_length=1, max_length=500)
    discount: Decimal = Field(default=Decimal("0"), ge=0, max_digits=20, decimal_places=2)
    customer_id: uuid.UUID | None = None
    customer: CustomerCreate | None = None

    @model_validator(mode="after")
    def validate_checkout(self):
        item_ids = [item.inventory_item_id for item in self.items]
        if len(item_ids) != len(set(item_ids)):
            raise ValueError("inventory items must not be repeated")
        if self.customer_id is not None and self.customer is not None:
            raise ValueError("provide customer_id or customer, not both")
        return self


class SaleLineResponse(BaseModel):
    id: uuid.UUID
    inventory_item_id: uuid.UUID
    item_name: str
    unit: str | None
    quantity: Decimal
    unit_price: Decimal
    unit_cost: Decimal
    line_total: Decimal
    line_cost: Decimal
    model_config = {"from_attributes": True}


class CheckoutResponse(BaseModel):
    id: uuid.UUID
    checkout_id: uuid.UUID
    customer_id: uuid.UUID | None
    payment_type: Literal["cash", "credit"]
    subtotal: Decimal
    discount: Decimal
    total: Decimal
    total_cost: Decimal
    created_at: datetime
    lines: list[SaleLineResponse]
    duplicate: bool = False
