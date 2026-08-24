import uuid
from decimal import Decimal

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.inventory import InventoryItem
from app.models.khata import Customer, KhataEntry
from app.models.sales import InventoryMovement, Sale, SaleLine
from app.schemas.khata import CustomerCreate
from app.schemas.sales import CheckoutRequest, CheckoutResponse, SaleLineResponse
from app.services.khata import get_or_create_customer


MONEY = Decimal("0.01")


async def checkout(
    db: AsyncSession, user_id: uuid.UUID, body: CheckoutRequest
) -> CheckoutResponse:
    existing = (
        await db.execute(
            select(Sale).where(
                Sale.user_id == user_id, Sale.checkout_id == body.checkout_id
            )
        )
    ).scalar_one_or_none()
    if existing is not None:
        lines = (
            await db.execute(select(SaleLine).where(SaleLine.sale_id == existing.id))
        ).scalars().all()
        return checkout_response(existing, list(lines), duplicate=True)

    customer: Customer | None = None
    if body.customer_id:
        customer = (
            await db.execute(
                select(Customer).where(
                    Customer.id == body.customer_id, Customer.user_id == user_id
                )
            )
        ).scalar_one_or_none()
        if customer is None:
            raise HTTPException(status_code=404, detail="Customer not found")
    elif body.customer:
        customer = await get_or_create_customer(db, user_id, body.customer)
    if body.payment_type == "credit" and customer is None:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Credit checkout requires a customer",
        )

    inventory_ids = [line.inventory_item_id for line in body.items]
    inventory_rows = (
        await db.execute(
            select(InventoryItem)
            .where(
                InventoryItem.user_id == user_id,
                InventoryItem.id.in_(inventory_ids),
            )
            .with_for_update()
        )
    ).scalars().all()
    by_id = {item.id: item for item in inventory_rows}
    if len(by_id) != len(inventory_ids):
        raise HTTPException(status_code=404, detail="One or more inventory items not found")

    prepared: list[tuple[InventoryItem, object, Decimal, Decimal]] = []
    subtotal = Decimal("0")
    total_cost = Decimal("0")
    for requested in body.items:
        item = by_id[requested.inventory_item_id]
        if item.quantity < requested.quantity:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"Insufficient stock for {item.name}",
            )
        unit_cost = item.purchase_unit_price or Decimal("0")
        line_total = (requested.quantity * requested.unit_price).quantize(MONEY)
        line_cost = (requested.quantity * unit_cost).quantize(MONEY)
        prepared.append((item, requested, line_total, line_cost))
        subtotal += line_total
        total_cost += line_cost

    sale = Sale(
        user_id=user_id,
        checkout_id=body.checkout_id,
        customer_id=customer.id if customer else None,
        payment_type=body.payment_type,
        subtotal=subtotal,
        discount=body.discount,
        total=max(subtotal - body.discount, Decimal("0")),
        total_cost=total_cost,
    )
    db.add(sale)
    await db.flush()

    lines: list[SaleLine] = []
    for item, requested, line_total, line_cost in prepared:
        item.quantity -= requested.quantity
        line = SaleLine(
            sale_id=sale.id,
            inventory_item_id=item.id,
            item_name=item.name,
            unit=item.unit,
            quantity=requested.quantity,
            unit_price=requested.unit_price,
            unit_cost=item.purchase_unit_price or Decimal("0"),
            line_total=line_total,
            line_cost=line_cost,
        )
        db.add(line)
        lines.append(line)
        db.add(
            InventoryMovement(
                user_id=user_id,
                inventory_item_id=item.id,
                movement_type="sale",
                quantity_delta=-requested.quantity,
                unit_cost=item.purchase_unit_price,
                idempotency_key=body.checkout_id,
                reference_id=sale.id,
            )
        )
    if body.payment_type == "credit":
        db.add(
            KhataEntry(
                user_id=user_id,
                customer_id=customer.id,
                entry_type="credit",
                amount=sale.total,
                description=f"Credit sale {sale.id}",
                source="sale",
                sale_id=sale.id,
            )
        )
    await db.flush()
    return checkout_response(sale, lines)


def checkout_response(
    sale: Sale, lines: list[SaleLine], duplicate: bool = False
) -> CheckoutResponse:
    return CheckoutResponse(
        id=sale.id,
        checkout_id=sale.checkout_id,
        customer_id=sale.customer_id,
        payment_type=sale.payment_type,
        subtotal=sale.subtotal,
        discount=sale.discount,
        total=sale.total,
        total_cost=sale.total_cost,
        created_at=sale.created_at,
        lines=[SaleLineResponse.model_validate(line) for line in lines],
        duplicate=duplicate,
    )
