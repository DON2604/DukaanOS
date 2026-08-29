"""Classify items, detect expiry/stockout, and persist alerts in the database."""

from __future__ import annotations

import uuid
from dataclasses import dataclass
from datetime import date, datetime, timedelta, timezone
from decimal import Decimal, ROUND_CEILING, ROUND_HALF_UP
from math import ceil

from sqlalchemy import delete, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.intelligence import ItemAlert, ItemIntelligence
from app.models.inventory import InventoryItem
from app.models.sales import InventoryMovement
from app.schemas.khata import RestockAlert, StockTrendPoint
from app.services.inventory import normalize_product_text


ZERO = Decimal("0")

_CATEGORY_RULES: tuple[tuple[tuple[str, ...], str, int, bool], ...] = (
    (("milk", "doodh", "dahi", "curd", "paneer", "taaza", "amul"), "dairy", 3, True),
    (("bread", "pav", "bun", "bakery"), "bakery", 2, True),
    (
        ("tomato", "onion", "aloo", "potato", "sabzi", "vegetable", "fruit", "banana"),
        "produce",
        4,
        True,
    ),
    (("egg", "anda"), "protein", 10, True),
    (("atta", "flour", "maida", "besan"), "staples", 90, False),
    (("rice", "chawal", "basmati"), "staples", 180, False),
    (("oil", "ghee", "tel"), "oil", 180, False),
    (("maggi", "noodle", "pasta", "biscuit", "namkeen"), "packaged", 180, False),
    (("sugar", "salt", "chini", "namak"), "staples", 365, False),
)


@dataclass(frozen=True)
class ItemProfile:
    category: str
    shelf_life_days: int
    perishable: bool


def classify_item(name: str) -> ItemProfile:
    haystack = normalize_product_text(name)
    for keywords, category, shelf_life, perishable in _CATEGORY_RULES:
        if any(keyword in haystack for keyword in keywords):
            return ItemProfile(category, shelf_life, perishable)
    return ItemProfile("general", 120, False)


def _as_date(value: datetime | date | None, fallback: date) -> date:
    if value is None:
        return fallback
    if isinstance(value, datetime):
        return value.date()
    return value


def apply_item_metadata(item: InventoryItem, today: date | None = None) -> ItemProfile:
    today = today or date.today()
    profile = classify_item(item.name)
    if not item.category:
        item.category = profile.category
    if item.shelf_life_days is None:
        item.shelf_life_days = profile.shelf_life_days
    if item.last_received_at is None:
        item.last_received_at = item.created_at or datetime.now(timezone.utc)
    shelf_life = item.shelf_life_days or profile.shelf_life_days
    received = _as_date(item.last_received_at, today)
    if item.expires_at is None and shelf_life:
        item.expires_at = received + timedelta(days=shelf_life)
    return ItemProfile(
        item.category or profile.category,
        shelf_life,
        profile.perishable,
    )


def _qty(value: Decimal | int | float | None) -> Decimal:
    if value is None:
        return ZERO
    return Decimal(value)


def reconstruct_trend(
    current: Decimal,
    movements: list[InventoryMovement],
    today: date,
    days: int = 14,
) -> list[StockTrendPoint]:
    by_day: dict[date, Decimal] = {}
    for movement in movements:
        day = _as_date(movement.created_at, today)
        delta = _qty(movement.quantity_delta)
        if movement.movement_type == "sale" and delta > 0:
            delta = -delta
        if movement.movement_type == "purchase" and delta < 0:
            delta = abs(delta)
        by_day[day] = by_day.get(day, ZERO) + delta

    qty = _qty(current)
    points: list[tuple[date, Decimal]] = [(today, qty)]
    for offset in range(1, days):
        day = today - timedelta(days=offset)
        next_day = day + timedelta(days=1)
        qty = qty - by_day.get(next_day, ZERO)
        if qty < 0:
            qty = ZERO
        points.append((day, qty))
    points.reverse()
    return [
        StockTrendPoint(day=day.isoformat(), quantity=value.quantize(Decimal("0.01")))
        for day, value in points
    ]


def _severity_for_days(days: int, perishable: bool) -> str:
    if days <= 2 or (perishable and days <= 3):
        return "critical"
    if days <= 5 or (perishable and days <= 7):
        return "warning"
    return "watch"


def build_item_alerts(
    item: InventoryItem,
    movements: list[InventoryMovement],
    today: date | None = None,
) -> tuple[list[RestockAlert], dict]:
    today = today or date.today()
    profile = apply_item_metadata(item, today)
    stock = _qty(item.quantity)
    unit = item.unit or "units"
    sold_14 = sum(
        (
            abs(_qty(movement.quantity_delta))
            for movement in movements
            if movement.movement_type == "sale"
        ),
        ZERO,
    )
    daily_rate = (sold_14 / Decimal(14)).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)
    if daily_rate <= 0:
        heuristic = Decimal("0.18") if profile.perishable else Decimal("0.08")
        daily_rate = max(stock * heuristic, Decimal("0.5")).quantize(Decimal("0.01"))
    if 0 < stock <= 12:
        daily_rate = max(
            daily_rate, (stock / Decimal("4")).quantize(Decimal("0.01"))
        )

    days_until_stockout = int(ceil(float(stock / daily_rate))) if daily_rate > 0 else 99
    cover_days = 10 if profile.perishable else 14
    suggested = (daily_rate * Decimal(cover_days) - stock).quantize(
        Decimal("1"), rounding=ROUND_CEILING
    )
    if suggested < daily_rate:
        suggested = daily_rate.quantize(Decimal("1"), rounding=ROUND_CEILING)

    expires_on = item.expires_at
    days_until_expiry = (expires_on - today).days if expires_on else None
    if days_until_expiry is None:
        expiry_status = "unknown"
    elif days_until_expiry < 0:
        expiry_status = "expired"
    elif days_until_expiry <= 3:
        expiry_status = "expiring"
    else:
        expiry_status = "fresh"

    trend = reconstruct_trend(stock, movements, today)
    restock_severity = _severity_for_days(days_until_stockout, profile.perishable)
    alerts: list[RestockAlert] = []

    if stock <= 0 or days_until_stockout <= 8:
        restock_severity = (
            "critical" if stock <= 0 or days_until_stockout <= 3 else restock_severity
        )
        alerts.append(
            RestockAlert(
                item_id=item.id,
                item_name=item.name,
                unit=unit,
                category=profile.category,
                alert_type="restock",
                current_stock=stock,
                days_until_stockout=days_until_stockout,
                days_until_expiry=days_until_expiry,
                expiry_date=expires_on,
                suggested_restock_qty=suggested,
                severity=restock_severity,
                perishable=profile.perishable,
                daily_sales_rate=daily_rate,
                message=(
                    f"{item.name} is running out — {stock} {unit} left. "
                    f"At the current pace it will stock out in {days_until_stockout} days. "
                    f"Restock {suggested} {unit}."
                ),
                trend=trend,
            )
        )

    if days_until_expiry is not None and (
        days_until_expiry <= 5 or (profile.perishable and days_until_expiry <= 7)
    ):
        expiry_severity = "critical" if days_until_expiry <= 1 else "warning"
        if days_until_expiry < 0:
            expiry_severity = "critical"
            expiry_message = (
                f"{item.name} has expired. Remove it from sale and restock a fresh lot."
            )
        else:
            expiry_message = (
                f"{item.name} expires in {days_until_expiry} days "
                f"({expires_on.isoformat() if expires_on else 'soon'}). "
                f"Sell through or discount before it spoils."
            )
        alerts.append(
            RestockAlert(
                item_id=item.id,
                item_name=item.name,
                unit=unit,
                category=profile.category,
                alert_type="expiry",
                current_stock=stock,
                days_until_stockout=days_until_stockout,
                days_until_expiry=days_until_expiry,
                expiry_date=expires_on,
                suggested_restock_qty=suggested,
                severity=expiry_severity,
                perishable=profile.perishable,
                daily_sales_rate=daily_rate,
                message=expiry_message,
                trend=trend,
            )
        )

    snapshot = {
        "category": profile.category,
        "perishable": profile.perishable,
        "daily_sales_rate": daily_rate,
        "days_until_stockout": days_until_stockout,
        "suggested_restock_qty": suggested,
        "days_until_expiry": days_until_expiry,
        "expiry_status": expiry_status,
        "restock_severity": restock_severity,
        "trend": [point.model_dump(mode="json") for point in trend],
    }
    return alerts, snapshot


def _demo_catalog() -> list[dict]:
    return [
        {
            "name": "Aashirvaad Atta",
            "quantity": Decimal("4"),
            "unit": "bags",
            "received_days_ago": 20,
        },
        {
            "name": "Fortune Sunflower Oil",
            "quantity": Decimal("6"),
            "unit": "litres",
            "received_days_ago": 30,
        },
        {
            "name": "Maggi Noodles",
            "quantity": Decimal("18"),
            "unit": "packs",
            "received_days_ago": 12,
        },
        {
            "name": "Amul Taaza Milk",
            "quantity": Decimal("9"),
            "unit": "packets",
            "received_days_ago": 2,
        },
        {
            "name": "India Gate Basmati Rice",
            "quantity": Decimal("22"),
            "unit": "kg",
            "received_days_ago": 40,
        },
    ]


async def _ensure_demo_inventory(
    db: AsyncSession, user_id, today: date
) -> list[InventoryItem]:
    now = datetime.now(timezone.utc)
    items: list[InventoryItem] = []
    for spec in _demo_catalog():
        received = now - timedelta(days=spec["received_days_ago"])
        item = InventoryItem(
            user_id=user_id,
            name=spec["name"],
            normalized_name=normalize_product_text(spec["name"]),
            quantity=spec["quantity"],
            unit=spec["unit"],
            normalized_unit=normalize_product_text(spec["unit"]),
            last_received_at=received,
            created_at=received,
            updated_at=now,
        )
        apply_item_metadata(item, today)
        db.add(item)
        items.append(item)
    return items


def dummy_restock_alerts(today: date | None = None) -> list[RestockAlert]:
    """Offline fallback used by tests that do not open a database session."""
    today = today or date.today()
    alerts: list[RestockAlert] = []
    now = datetime.now(timezone.utc)
    for spec in _demo_catalog():
        item = InventoryItem(
            id=uuid.uuid4(),
            user_id=uuid.uuid4(),
            name=spec["name"],
            normalized_name=normalize_product_text(spec["name"]),
            quantity=spec["quantity"],
            unit=spec["unit"],
            normalized_unit=normalize_product_text(spec["unit"]),
            last_received_at=now - timedelta(days=spec["received_days_ago"]),
            created_at=now - timedelta(days=spec["received_days_ago"]),
        )
        built, _ = build_item_alerts(item, [], today)
        alerts.extend(built)
    return alerts


async def sync_inventory_intelligence(
    db: AsyncSession, user_id, today: date | None = None
) -> list[RestockAlert]:
    today = today or date.today()
    items = list(
        (
            await db.execute(
                select(InventoryItem).where(InventoryItem.user_id == user_id)
            )
        ).scalars()
    )
    if not items:
        items = await _ensure_demo_inventory(db, user_id, today)
    await db.flush()

    movements = list(
        (
            await db.execute(
                select(InventoryMovement).where(InventoryMovement.user_id == user_id)
            )
        ).scalars()
    )
    movements_by_item: dict = {}
    for movement in movements:
        movements_by_item.setdefault(movement.inventory_item_id, []).append(movement)

    alerts: list[RestockAlert] = []
    snapshots: list[tuple[InventoryItem, dict]] = []
    for item in items:
        item_alerts, snapshot = build_item_alerts(
            item, movements_by_item.get(item.id, []), today
        )
        alerts.extend(item_alerts)
        snapshots.append((item, snapshot))

    await db.execute(delete(ItemIntelligence).where(ItemIntelligence.user_id == user_id))
    await db.execute(delete(ItemAlert).where(ItemAlert.user_id == user_id))

    for item, snapshot in snapshots:
        if item.id is None:
            continue
        db.add(
            ItemIntelligence(
                user_id=user_id,
                inventory_item_id=item.id,
                category=snapshot["category"],
                perishable=snapshot["perishable"],
                daily_sales_rate=snapshot["daily_sales_rate"],
                days_until_stockout=snapshot["days_until_stockout"],
                suggested_restock_qty=snapshot["suggested_restock_qty"],
                days_until_expiry=snapshot["days_until_expiry"],
                expiry_status=snapshot["expiry_status"],
                restock_severity=snapshot["restock_severity"],
                trend=snapshot["trend"],
            )
        )
    for alert in alerts:
        if alert.item_id is None:
            continue
        db.add(
            ItemAlert(
                user_id=user_id,
                inventory_item_id=alert.item_id,
                item_name=alert.item_name,
                unit=alert.unit,
                category=alert.category,
                alert_type=alert.alert_type,
                severity=alert.severity,
                current_stock=alert.current_stock,
                days_until_stockout=alert.days_until_stockout,
                days_until_expiry=alert.days_until_expiry,
                expiry_date=alert.expiry_date,
                suggested_restock_qty=alert.suggested_restock_qty,
                message=alert.message,
                trend=[point.model_dump(mode="json") for point in alert.trend],
            )
        )

    severity_rank = {"critical": 0, "warning": 1, "watch": 2}
    alerts.sort(key=lambda row: (severity_rank.get(row.severity, 9), row.item_name))
    return alerts
