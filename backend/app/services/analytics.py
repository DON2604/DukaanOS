import uuid
from decimal import Decimal

from sqlalchemy import case, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.inventory import InventoryItem
from app.models.khata import Customer, KhataEntry, TranscriptInsightBatch
from app.models.sales import InventoryMovement, Sale, SaleLine
from app.schemas.khata import (
    CustomerBalance,
    CustomerResponse,
    DashboardInsight,
    DashboardSummary,
    KhataDashboard,
)
from app.services.khata import entry_response


ZERO = Decimal("0")


async def build_dashboard(db: AsyncSession, user_id: uuid.UUID) -> KhataDashboard:
    revenue, cogs = (
        await db.execute(
            select(
                func.coalesce(func.sum(Sale.total), 0),
                func.coalesce(func.sum(Sale.total_cost), 0),
            ).where(Sale.user_id == user_id)
        )
    ).one()
    items_sold = (
        await db.execute(
            select(func.coalesce(func.sum(SaleLine.quantity), 0))
            .join(Sale, Sale.id == SaleLine.sale_id)
            .where(Sale.user_id == user_id)
        )
    ).scalar_one()
    purchases = (
        await db.execute(
            select(
                func.coalesce(
                    func.sum(
                        InventoryMovement.quantity_delta * InventoryMovement.unit_cost
                    ),
                    0,
                )
            ).where(
                InventoryMovement.user_id == user_id,
                InventoryMovement.movement_type == "purchase",
            )
        )
    ).scalar_one()
    stock_value = (
        await db.execute(
            select(
                func.coalesce(
                    func.sum(
                        InventoryItem.quantity
                        * func.coalesce(InventoryItem.purchase_unit_price, 0)
                    ),
                    0,
                )
            ).where(InventoryItem.user_id == user_id)
        )
    ).scalar_one()

    signed_amount = case(
        (KhataEntry.entry_type == "credit", KhataEntry.amount),
        else_=-KhataEntry.amount,
    )
    balances_result = await db.execute(
        select(Customer, func.sum(signed_amount).label("balance"))
        .join(KhataEntry, KhataEntry.customer_id == Customer.id)
        .where(Customer.user_id == user_id, KhataEntry.is_deleted.is_(False))
        .group_by(Customer.id)
        .order_by(func.sum(signed_amount).desc(), Customer.name.asc())
    )
    customer_balances = [
        CustomerBalance(
            customer=CustomerResponse.model_validate(customer),
            balance=balance,
        )
        for customer, balance in balances_result.all()
        if balance != 0
    ]
    receivables = sum(
        (row.balance for row in customer_balances if row.balance > 0), ZERO
    )

    entries_result = await db.execute(
        select(KhataEntry, Customer.name)
        .join(Customer, Customer.id == KhataEntry.customer_id)
        .where(KhataEntry.user_id == user_id, KhataEntry.is_deleted.is_(False))
        .order_by(KhataEntry.occurred_at.desc(), KhataEntry.id.desc())
        .limit(50)
    )
    batches = (
        await db.execute(
            select(TranscriptInsightBatch)
            .where(TranscriptInsightBatch.user_id == user_id)
            .order_by(TranscriptInsightBatch.created_at.desc())
            .limit(20)
        )
    ).scalars()

    return KhataDashboard(
        summary=DashboardSummary(
            revenue=revenue,
            purchases=purchases,
            gain=revenue - cogs,
            items_sold=items_sold,
            stock_value=stock_value,
            receivables=receivables,
        ),
        customer_balances=customer_balances,
        recent_entries=[
            entry_response(entry, customer_name)
            for entry, customer_name in entries_result.all()
        ],
        insights=[
            DashboardInsight(
                batch_id=batch.batch_id,
                language=batch.language,
                insights=batch.insights or [],
                unresolved=batch.unresolved or [],
                created_at=batch.created_at,
            )
            for batch in batches
        ],
    )
