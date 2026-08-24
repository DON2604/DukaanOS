import re
import unicodedata
from datetime import datetime, timezone
from decimal import Decimal

from sqlalchemy import func, select
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.inventory import InventoryItem
from app.schemas.inventory import InventoryBulkAddRequest


def normalize_product_text(value: str | None) -> str:
    if not value:
        return ""
    normalized = unicodedata.normalize("NFKC", value)
    return re.sub(r"\s+", " ", normalized).strip().casefold()


async def bulk_add_inventory(
    db: AsyncSession,
    user_id,
    body: InventoryBulkAddRequest,
) -> list[InventoryItem]:
    saved: list[InventoryItem] = []

    for item in body.items:
        normalized_name = normalize_product_text(item.name)
        normalized_unit = normalize_product_text(item.unit)
        supplier_name = item.supplier_name or body.supplier_name
        invoice_number = item.invoice_number or body.invoice_number
        now = datetime.now(timezone.utc)

        statement = insert(InventoryItem).values(
            user_id=user_id,
            name=item.name,
            normalized_name=normalized_name,
            quantity=item.quantity if item.quantity is not None else Decimal("0"),
            unit=item.unit,
            normalized_unit=normalized_unit,
            purchase_unit_price=item.purchase_unit_price,
            selling_price=item.selling_price,
            line_total=item.line_total,
            supplier_name=supplier_name,
            invoice_number=invoice_number,
            created_at=now,
            updated_at=now,
        )
        excluded = statement.excluded
        statement = statement.on_conflict_do_update(
            constraint="uq_inventory_user_product_unit",
            set_={
                "name": excluded.name,
                "unit": excluded.unit,
                "quantity": InventoryItem.quantity + excluded.quantity,
                "purchase_unit_price": func.coalesce(
                    excluded.purchase_unit_price,
                    InventoryItem.purchase_unit_price,
                ),
                "selling_price": func.coalesce(
                    excluded.selling_price,
                    InventoryItem.selling_price,
                ),
                "line_total": func.coalesce(
                    excluded.line_total,
                    InventoryItem.line_total,
                ),
                "supplier_name": func.coalesce(
                    excluded.supplier_name,
                    InventoryItem.supplier_name,
                ),
                "invoice_number": func.coalesce(
                    excluded.invoice_number,
                    InventoryItem.invoice_number,
                ),
                "updated_at": now,
            },
        ).returning(InventoryItem)
        result = await db.execute(statement)
        saved.append(result.scalar_one())

    return saved


async def list_inventory(db: AsyncSession, user_id) -> list[InventoryItem]:
    result = await db.execute(
        select(InventoryItem)
        .where(InventoryItem.user_id == user_id)
        .order_by(InventoryItem.updated_at.desc(), InventoryItem.name.asc())
    )
    return list(result.scalars().all())
