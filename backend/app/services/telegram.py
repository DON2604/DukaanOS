import logging

import httpx
from app.config import get_settings

logger = logging.getLogger(__name__)


async def send_telegram_message(
    chat_id: int,
    text: str,
    parse_mode: str | None = None,
) -> bool:
    settings = get_settings()
    token = settings.TELEGRAM_BOT_TOKEN
    if not token:
        logger.error("TELEGRAM_BOT_TOKEN is not set — cannot send message to chat_id=%s", chat_id)
        return False
    url = f"https://api.telegram.org/bot{token}/sendMessage"
    payload: dict[str, object] = {"chat_id": chat_id, "text": text}
    if parse_mode:
        payload["parse_mode"] = parse_mode
    try:
        async with httpx.AsyncClient(timeout=10) as client:
            resp = await client.post(url, json=payload)
    except httpx.TimeoutException:
        logger.error("Telegram sendMessage timed out for chat_id=%s", chat_id)
        return False
    except httpx.RequestError as exc:
        logger.error("Telegram sendMessage network error for chat_id=%s: %s", chat_id, exc)
        return False
    if resp.status_code == 200:
        logger.info("Telegram message sent to chat_id=%s", chat_id)
        return True
    logger.error(
        "Telegram sendMessage failed for chat_id=%s — HTTP %s: %s",
        chat_id,
        resp.status_code,
        resp.text,
    )
    return False


async def send_otp_via_telegram(chat_id: int, otp_code: str) -> bool:
    return await send_telegram_message(
        chat_id,
        f"Your DukaanOS login OTP is: *{otp_code}*\n\nValid for 5 minutes. Do not share.",
        parse_mode="Markdown",
    )
