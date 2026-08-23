import random
import string
from datetime import datetime, timedelta, timezone
from jose import jwt
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import get_settings
from app.models.user import User, OTP
from app.services.telegram import send_otp_via_telegram


settings = get_settings()


def _generate_otp(length: int = 6) -> str:
    return "".join(random.choices(string.digits, k=length))


def create_access_token(user_id: str) -> str:
    expire = datetime.now(timezone.utc) + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    payload = {"sub": user_id, "exp": expire}
    return jwt.encode(payload, settings.JWT_SECRET, algorithm=settings.JWT_ALGORITHM)


async def create_account(db: AsyncSession, name: str, phone: str, telegram_chat_id: int) -> User:
    user = User(name=name, phone=phone, telegram_chat_id=telegram_chat_id)
    db.add(user)
    await db.commit()
    await db.refresh(user)
    return user


async def get_user_by_phone(db: AsyncSession, phone: str) -> User | None:
    result = await db.execute(select(User).where(User.phone == phone))
    return result.scalar_one_or_none()


async def request_otp(db: AsyncSession, phone: str) -> bool:
    """Generate OTP, save it, and send via Telegram. Returns True on success."""
    user = await get_user_by_phone(db, phone)
    if not user:
        return False

    code = _generate_otp()
    otp = OTP(phone=phone, code=code)
    db.add(otp)
    await db.commit()

    sent = await send_otp_via_telegram(user.telegram_chat_id, code)
    return sent


async def verify_otp(db: AsyncSession, phone: str, code: str) -> str | None:
    """Verify OTP and return access token, or None if invalid."""
    cutoff = datetime.now(timezone.utc) - timedelta(seconds=settings.OTP_EXPIRE_SECONDS)

    result = await db.execute(
        select(OTP)
        .where(OTP.phone == phone, OTP.code == code, OTP.is_used == False, OTP.created_at >= cutoff)
        .order_by(OTP.created_at.desc())
        .limit(1)
    )
    otp = result.scalar_one_or_none()
    if not otp:
        return None

    otp.is_used = True
    await db.commit()

    user = await get_user_by_phone(db, phone)
    if not user:
        return None

    return create_access_token(str(user.id))
