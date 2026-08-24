import logging
import random
import string
from datetime import datetime, timedelta, timezone
from jose import jwt
from sqlalchemy import delete, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import get_settings
from app.models.user import User, OTP
from app.services.telegram import send_otp_via_telegram


settings = get_settings()
logger = logging.getLogger(__name__)


def _generate_otp(length: int = 6) -> str:
    return "".join(random.choices(string.digits, k=length))


def create_access_token(user_id: str) -> str:
    expire = datetime.now(timezone.utc) + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    payload = {"sub": user_id, "exp": expire}
    return jwt.encode(payload, settings.JWT_SECRET, algorithm=settings.JWT_ALGORITHM)


async def create_account(db: AsyncSession, name: str, phone: str, telegram_chat_id: int) -> User:
    user = User(name=name, phone=phone, telegram_chat_id=telegram_chat_id, is_active=False)
    db.add(user)
    await db.commit()
    await db.refresh(user)
    logger.info(
        "User created: id=%s phone=%s telegram_chat_id=%s verified=%s",
        user.id,
        phone,
        telegram_chat_id,
        user.is_active,
    )
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

    expires_at = otp.created_at + timedelta(seconds=settings.OTP_EXPIRE_SECONDS)
    logger.info("OTP sent request: phone=%s expires_at=%s (in %s seconds)", phone, expires_at, settings.OTP_EXPIRE_SECONDS)
    sent = await send_otp_via_telegram(user.telegram_chat_id, code)
    logger.info("OTP delivery: phone=%s sent=%s", phone, sent)
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
        logger.info("OTP verification failed or expired: phone=%s", phone)
        return None

    user = await get_user_by_phone(db, phone)
    if not user:
        return None

    otp.is_used = True
    user.is_active = True
    await db.commit()
    logger.info("User verified: id=%s phone=%s", user.id, phone)

    return create_access_token(str(user.id))


async def delete_expired_unverified_users(db: AsyncSession) -> int:
    """Delete inactive users whose latest OTP has expired."""
    cutoff = datetime.now(timezone.utc) - timedelta(seconds=settings.OTP_EXPIRE_SECONDS)
    result = await db.execute(select(User).where(User.is_active == False))
    users = result.scalars().all()
    deleted_count = 0

    for user in users:
        latest_otp = await db.scalar(
            select(OTP)
            .where(OTP.phone == user.phone)
            .order_by(OTP.created_at.desc())
            .limit(1)
        )
        if latest_otp and latest_otp.created_at < cutoff:
            expires_at = latest_otp.created_at + timedelta(seconds=settings.OTP_EXPIRE_SECONDS)
            logger.info("OTP expired: phone=%s expired_at=%s", user.phone, expires_at)
            delete_result = await db.execute(
                delete(User).where(User.id == user.id, User.is_active == False)
            )
            if delete_result.rowcount:
                await db.execute(delete(OTP).where(OTP.phone == user.phone))
                deleted_count += 1
                logger.info("User deleted after expired OTP: id=%s phone=%s", user.id, user.phone)

    if deleted_count:
        await db.commit()
    return deleted_count
