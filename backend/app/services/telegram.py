import httpx
from app.config import get_settings


async def send_telegram_message(
    chat_id: int,
    text: str,
    parse_mode: str | None = None,
) -> bool:
    settings = get_settings()
    url = f"https://api.telegram.org/bot{settings.TELEGRAM_BOT_TOKEN}/sendMessage"
    payload: dict[str, object] = {"chat_id": chat_id, "text": text}
    if parse_mode:
        payload["parse_mode"] = parse_mode
    async with httpx.AsyncClient(timeout=10) as client:
        resp = await client.post(url, json=payload)
        return resp.status_code == 200


async def send_otp_via_telegram(chat_id: int, otp_code: str) -> bool:
    return await send_telegram_message(
        chat_id,
        f"Your DukaanOS login OTP is: *{otp_code}*\n\nValid for 5 minutes. Do not share.",
        parse_mode="Markdown",
    )
