import uuid
from datetime import date, datetime, timezone
from decimal import Decimal

from sqlalchemy import (
    Boolean,
    Date,
    DateTime,
    ForeignKey,
    Index,
    Integer,
    JSON,
    Numeric,
    String,
    UniqueConstraint,
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


def utcnow() -> datetime:
    return datetime.now(timezone.utc)


class ItemIntelligence(Base):
    __tablename__ = "item_intelligence"
    __table_args__ = (
        UniqueConstraint("inventory_item_id", name="uq_item_intelligence_item"),
        Index("ix_item_intelligence_user", "user_id", "updated_at"),
    )

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    inventory_item_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("inventory_items.id", ondelete="CASCADE"),
        index=True,
    )
    category: Mapped[str] = mapped_column(String(40), default="general")
    perishable: Mapped[bool] = mapped_column(Boolean, default=False)
    daily_sales_rate: Mapped[Decimal] = mapped_column(
        Numeric(20, 6), default=Decimal("0")
    )
    days_until_stockout: Mapped[int | None] = mapped_column(Integer, nullable=True)
    suggested_restock_qty: Mapped[Decimal] = mapped_column(
        Numeric(20, 6), default=Decimal("0")
    )
    days_until_expiry: Mapped[int | None] = mapped_column(Integer, nullable=True)
    expiry_status: Mapped[str] = mapped_column(String(20), default="fresh")
    restock_severity: Mapped[str] = mapped_column(String(20), default="watch")
    trend: Mapped[list] = mapped_column(JSON, default=list)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow, onupdate=utcnow
    )


class ItemAlert(Base):
    __tablename__ = "item_alerts"
    __table_args__ = (
        UniqueConstraint(
            "user_id",
            "inventory_item_id",
            "alert_type",
            name="uq_item_alert_user_item_type",
        ),
        Index("ix_item_alert_user_severity", "user_id", "severity"),
    )

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    inventory_item_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("inventory_items.id", ondelete="CASCADE"),
        index=True,
    )
    item_name: Mapped[str] = mapped_column(String(300))
    unit: Mapped[str] = mapped_column(String(60), default="units")
    category: Mapped[str] = mapped_column(String(40), default="general")
    alert_type: Mapped[str] = mapped_column(String(20))  # restock, expiry
    severity: Mapped[str] = mapped_column(String(20))
    current_stock: Mapped[Decimal] = mapped_column(Numeric(20, 6))
    days_until_stockout: Mapped[int | None] = mapped_column(Integer, nullable=True)
    days_until_expiry: Mapped[int | None] = mapped_column(Integer, nullable=True)
    expiry_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    suggested_restock_qty: Mapped[Decimal] = mapped_column(
        Numeric(20, 6), default=Decimal("0")
    )
    message: Mapped[str] = mapped_column(String(500))
    trend: Mapped[list] = mapped_column(JSON, default=list)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow, onupdate=utcnow
    )
