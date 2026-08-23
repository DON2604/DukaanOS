import httpx
from app.config import get_settings


async def send_otp_via_telegram(chat_id: int, otp_code: str) -> bool:
    settings = get_settings()
    url = f"https://api.telegram.org/bot{settings.TELEGRAM_BOT_TOKEN}/sendMessage"
    payload = {
        "chat_id": chat_id,
        "text": f"Your DukaanOS login OTP is: *{otp_code}*\n\nValid for 5 minutes. Do not share.",
        "parse_mode": "Markdown",
    }
    async with httpx.AsyncClient() as client:
        resp = await client.post(url, json=payload)
        return resp.status_code == 200