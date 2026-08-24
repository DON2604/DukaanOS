import uuid
from datetime import datetime, timezone
from decimal import Decimal

from sqlalchemy import DateTime, ForeignKey, Index, Numeric, String, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class InventoryItem(Base):
    __tablename__ = "inventory_items"
    __table_args__ = (
        UniqueConstraint(
            "user_id",
            "normalized_name",
            "normalized_unit",
            name="uq_inventory_user_product_unit",
        ),
        Index("ix_inventory_user_updated", "user_id", "updated_at"),
    )

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    name: Mapped[str] = mapped_column(String(300), nullable=False)
    normalized_name: Mapped[str] = mapped_column(String(300), nullable=False)
    quantity: Mapped[Decimal] = mapped_column(
        Numeric(20, 6), nullable=False, default=Decimal("0")
    )
    unit: Mapped[str | None] = mapped_column(String(60), nullable=True)
    normalized_unit: Mapped[str] = mapped_column(String(60), nullable=False, default="")
    purchase_unit_price: Mapped[Decimal | None] = mapped_column(
        Numeric(20, 6), nullable=True
    )
    selling_price: Mapped[Decimal | None] = mapped_column(Numeric(20, 6), nullable=True)
    line_total: Mapped[Decimal | None] = mapped_column(Numeric(20, 6), nullable=True)
    supplier_name: Mapped[str | None] = mapped_column(String(300), nullable=True)
    invoice_number: Mapped[str | None] = mapped_column(String(120), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc)
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
    )
