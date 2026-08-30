from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.exc import IntegrityError, SQLAlchemyError
from sqlalchemy.ext.asyncio import AsyncSession
import logging

from app.db.session import get_db
from app.dependencies import get_current_user
from app.models.user import User
from app.schemas.sales import CheckoutRequest, CheckoutResponse, SendReceiptRequest
from app.services.notifications import notify_sale_receipt
from app.services.sales import checkout

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/sales", tags=["sales"])


@router.post(
    "/checkout", response_model=CheckoutResponse, status_code=status.HTTP_201_CREATED
)
async def create_checkout(
    body: CheckoutRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> CheckoutResponse:
    try:
        result = await checkout(db, current_user.id, body)
        await db.commit()

        receipt_number = f"RCP-{result.checkout_id.hex[:8].upper()}-{result.id.hex[:6].upper()}"
        receipt_items = [
            {
                "name": line.item_name,
                "quantity": line.quantity,
                "unit": line.unit,
                "unit_price": line.unit_price,
                "line_total": line.line_total,
            }
            for line in result.lines
        ]
        customer_name = None
        if result.customer_id is not None:
            customer_name = f"customer-{result.customer_id.hex[:8]}"

        logger.info(
            "Checkout %s complete — firing Telegram receipt to chat_id=%s",
            receipt_number,
            current_user.telegram_chat_id,
        )
        await notify_sale_receipt(
            receipt_number=receipt_number,
            items=receipt_items,
            subtotal=result.subtotal,
            discount=result.discount,
            total=result.total,
            payment_type=result.payment_type,
            customer_name=customer_name,
            chat_id=current_user.telegram_chat_id,
        )
        return result
    except HTTPException:
        await db.rollback()
        raise
    except IntegrityError as exc:
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Checkout id is already being processed; retry the same request",
        ) from exc
    except SQLAlchemyError as exc:
        await db.rollback()
        raise HTTPException(
            status_code=500,
            detail="Checkout failed; inventory and sale were not changed",
        ) from exc


@router.post("/send-receipt", status_code=status.HTTP_200_OK)
async def send_receipt(
    body: SendReceiptRequest,
    current_user: User = Depends(get_current_user),
) -> dict:
    """Send a bill receipt via Telegram for the current user."""
    items = [
        {
            "name": item.name,
            "quantity": item.quantity,
            "unit": item.unit,
            "unit_price": item.unit_price,
            "line_total": item.line_total,
        }
        for item in body.items
    ]
    logger.info(
        "send-receipt %s — sending Telegram to chat_id=%s",
        body.receipt_number,
        current_user.telegram_chat_id,
    )
    sent = await notify_sale_receipt(
        receipt_number=body.receipt_number,
        items=items,
        subtotal=body.subtotal,
        discount=body.discount,
        total=body.total,
        payment_type=body.payment_type,
        customer_name=body.customer_name,
        chat_id=current_user.telegram_chat_id,
    )
    return {"sent": sent}
