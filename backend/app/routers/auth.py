from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.schemas.auth import (
    CreateAccountRequest,
    RequestOTPRequest,
    VerifyOTPRequest,
    UserResponse,
    TokenResponse,
    MessageResponse,
)
from app.services import auth as auth_service

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/create-account", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def create_account(body: CreateAccountRequest, db: AsyncSession = Depends(get_db)):
    existing = await auth_service.get_user_by_phone(db, body.phone)
    if existing:
        raise HTTPException(status_code=400, detail="Phone number already registered")

    user = await auth_service.create_account(db, body.name, body.phone, body.telegram_chat_id)
    return user


@router.post("/request-otp", response_model=MessageResponse)
async def request_otp(body: RequestOTPRequest, db: AsyncSession = Depends(get_db)):
    sent = await auth_service.request_otp(db, body.phone)
    if not sent:
        raise HTTPException(status_code=404, detail="Account not found or Telegram delivery failed")
    return {"message": "OTP sent to your Telegram"}


@router.post("/verify-otp", response_model=TokenResponse)
async def verify_otp(body: VerifyOTPRequest, db: AsyncSession = Depends(get_db)):
    token = await auth_service.verify_otp(db, body.phone, body.otp)
    if not token:
        raise HTTPException(status_code=401, detail="Invalid or expired OTP")
    return {"access_token": token}
