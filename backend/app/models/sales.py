import uuid
from datetime import datetime, timezone
from decimal import Decimal

from sqlalchemy import DateTime, ForeignKey, Index, Numeric, String, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


def utcnow() -> datetime:
    return datetime.now(timezone.utc)


class Sale(Base):
    __tablename__ = "sales"
    __table_args__ = (
        UniqueConstraint("user_id", "checkout_id", name="uq_sale_user_checkout"),
        Index("ix_sale_user_created", "user_id", "created_at"),
    )

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    checkout_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True))
    customer_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("customers.id", ondelete="RESTRICT"), nullable=True
    )
    payment_type: Mapped[str] = mapped_column(String(20))
    subtotal: Mapped[Decimal] = mapped_column(Numeric(20, 2))
    discount: Mapped[Decimal] = mapped_column(Numeric(20, 2), default=Decimal("0"))
    total: Mapped[Decimal] = mapped_column(Numeric(20, 2))
    total_cost: Mapped[Decimal] = mapped_column(Numeric(20, 2))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)


class SaleLine(Base):
    __tablename__ = "sale_lines"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    sale_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("sales.id", ondelete="CASCADE"), index=True
    )
    inventory_item_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("inventory_items.id", ondelete="RESTRICT")
    )
    item_name: Mapped[str] = mapped_column(String(300))
    unit: Mapped[str | None] = mapped_column(String(60), nullable=True)
    quantity: Mapped[Decimal] = mapped_column(Numeric(20, 6))
    unit_price: Mapped[Decimal] = mapped_column(Numeric(20, 2))
    unit_cost: Mapped[Decimal] = mapped_column(Numeric(20, 6))
    line_total: Mapped[Decimal] = mapped_column(Numeric(20, 2))
    line_cost: Mapped[Decimal] = mapped_column(Numeric(20, 2))


class InventoryMovement(Base):
    __tablename__ = "inventory_movements"
    __table_args__ = (
        UniqueConstraint(
            "user_id",
            "idempotency_key",
            "inventory_item_id",
            "movement_type",
            name="uq_inventory_movement_idempotency",
        ),
        Index("ix_movement_user_created", "user_id", "created_at"),
    )

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    inventory_item_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("inventory_items.id", ondelete="RESTRICT")
    )
    movement_type: Mapped[str] = mapped_column(String(20))  # purchase, sale
    quantity_delta: Mapped[Decimal] = mapped_column(Numeric(20, 6))
    unit_cost: Mapped[Decimal | None] = mapped_column(Numeric(20, 6), nullable=True)
    idempotency_key: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True))
    reference_id: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
