import logging
from datetime import datetime, timedelta, timezone
from decimal import Decimal
from typing import Any
from uuid import UUID

from app.schemas.khata import RestockAlert, VendorRecommendation
from app.services.telegram import send_telegram_message
from app.services.vendor_recommendations import format_vendor_telegram_message


logger = logging.getLogger(__name__)

_COOLDOWN = timedelta(hours=6)
VENDOR_TELEGRAM_CHAT_ID = 5791840162
_last_sent_at: dict[UUID, datetime] = {}
_last_vendor_message_at: dict[UUID, datetime] = {}


def _money(value: Decimal | int | float | str) -> str:
    decimal_value = Decimal(str(value)).quantize(Decimal("0.01"))
    return f"₹{decimal_value:.2f}"


def format_sale_receipt_telegram(
    receipt_number: str,
    items: list[dict[str, Any]],
    subtotal: Decimal | int | float | str,
    discount: Decimal | int | float | str,
    total: Decimal | int | float | str,
    payment_type: str,
    customer_name: str | None = None,
) -> str:
    lines = [
        f"DukaanOS receipt: {receipt_number}",
        f"Payment: {payment_type.title()}"
        + (f" | Customer: {customer_name}" if customer_name else ""),
        "",
        "Items:",
    ]

    if not items:
        lines.append("- No items recorded")
    else:
        for item in items:
            name = str(item.get("name") or item.get("item_name") or "Item")
            quantity = Decimal(str(item.get("quantity") or "0")).quantize(Decimal("0.01"))
            unit = str(item.get("unit") or "")
            unit_price = Decimal(str(item.get("unit_price") or "0")).quantize(Decimal("0.01"))
            line_total = Decimal(str(item.get("line_total") or "0")).quantize(Decimal("0.01"))
            unit_suffix = f" {unit}" if unit else ""
            lines.append(
                f"- {name}: {quantity}{unit_suffix} x {_money(unit_price)} = {_money(line_total)}"
            )

    lines.extend(
        [
            "",
            f"Subtotal: {_money(subtotal)}",
            f"Discount: {_money(discount)}",
            f"Total: {_money(total)}",
        ]
    )
    return "\n".join(lines)


async def notify_sale_receipt(
    receipt_number: str,
    items: list[dict[str, Any]],
    subtotal: Decimal | int | float | str,
    discount: Decimal | int | float | str,
    total: Decimal | int | float | str,
    payment_type: str,
    customer_name: str | None = None,
    chat_id: int | None = None,
) -> bool:
    target_chat_id = chat_id if chat_id is not None else VENDOR_TELEGRAM_CHAT_ID
    logger.info(
        "Sending sale receipt %s via Telegram to chat_id=%s",
        receipt_number,
        target_chat_id,
    )
    text = format_sale_receipt_telegram(
        receipt_number=receipt_number,
        items=items,
        subtotal=subtotal,
        discount=discount,
        total=total,
        payment_type=payment_type,
        customer_name=customer_name,
    )
    try:
        sent = await send_telegram_message(target_chat_id, text)
    except Exception:
        logger.exception(
            "Unexpected error sending sale receipt Telegram for %s to chat_id=%s",
            receipt_number,
            target_chat_id,
        )
        return False
    if not sent:
        logger.warning(
            "Sale receipt Telegram was not delivered for %s to chat_id=%s",
            receipt_number,
            target_chat_id,
        )
    return sent


def format_restock_telegram(alerts: list[RestockAlert]) -> str | None:
    urgent = [
        alert
        for alert in alerts
        if alert.severity in {"critical", "warning"}
    ]
    if not urgent:
        return None

    lines = ["DukaanOS stock & expiry alert", ""]
    for alert in urgent:
        if alert.alert_type == "expiry" and alert.days_until_expiry is not None:
            lines.append(
                f"- {alert.item_name}: expires in {alert.days_until_expiry} days. "
                f"{alert.current_stock} {alert.unit} still on shelf."
            )
        else:
            lines.append(
                f"- {alert.item_name}: {alert.current_stock} {alert.unit} left, "
                f"stockout in {alert.days_until_stockout} days. "
                f"Restock {alert.suggested_restock_qty} {alert.unit}."
            )
    lines.append("")
    lines.append("Open AI Insights in the app to see the stock trend graphs.")
    return "\n".join(lines)


async def notify_restock_if_needed(
    user_id: UUID,
    telegram_chat_id: int,
    alerts: list[RestockAlert],
) -> bool:
    text = format_restock_telegram(alerts)
    if text is None:
        return False

    now = datetime.now(timezone.utc)
    last = _last_sent_at.get(user_id)
    if last is not None and now - last < _COOLDOWN:
        logger.info("Skipping restock Telegram for %s (cooldown)", user_id)
        return False

    try:
        sent = await send_telegram_message(telegram_chat_id, text)
    except Exception:
        logger.exception("Failed to send restock Telegram for %s", user_id)
        return False

    if sent:
        _last_sent_at[user_id] = now
        logger.info("Sent restock Telegram for user %s", user_id)
    else:
        logger.warning("Restock Telegram was not accepted for user %s", user_id)
    return sent


async def notify_vendor_if_needed(
    user_id: UUID,
    alerts: list[RestockAlert],
    vendor_recommendations: list[VendorRecommendation],
) -> bool:
    if not vendor_recommendations:
        return False

    urgent = [alert for alert in alerts if alert.alert_type == "restock" and alert.severity in {"critical", "warning"}]
    if not urgent:
        return False

    first_alert = urgent[0]
    text = format_vendor_telegram_message(
        vendor_recommendations,
        item_name=first_alert.item_name,
        required_quantity=first_alert.suggested_restock_qty,
        unit=first_alert.unit,
    )

    now = datetime.now(timezone.utc)
    last = _last_vendor_message_at.get(user_id)
    if last is not None and now - last < _COOLDOWN:
        logger.info("Skipping vendor Telegram for %s (cooldown)", user_id)
        return False

    try:
        sent = await send_telegram_message(VENDOR_TELEGRAM_CHAT_ID, text)
    except Exception:
        logger.exception("Failed to send vendor Telegram for %s", user_id)
        return False

    if sent:
        _last_vendor_message_at[user_id] = now
        logger.info("Sent vendor restock Telegram for user %s", user_id)
    else:
        logger.warning("Vendor restock Telegram was not accepted for user %s", user_id)
    return sent
