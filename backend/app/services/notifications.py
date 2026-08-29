import logging
from datetime import datetime, timedelta, timezone
from uuid import UUID

from app.schemas.khata import RestockAlert
from app.services.telegram import send_telegram_message


logger = logging.getLogger(__name__)

_COOLDOWN = timedelta(hours=6)
_last_sent_at: dict[UUID, datetime] = {}


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
