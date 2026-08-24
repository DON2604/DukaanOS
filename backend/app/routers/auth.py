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


def _otp_http_error(result: str) -> HTTPException:
    if result == "not_found":
        return HTTPException(status_code=404, detail="Account not found")
    return HTTPException(status_code=502, detail="Telegram delivery failed")


# --- Sign up (create account) ---


@router.post("/create-account", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def create_account(body: CreateAccountRequest, db: AsyncSession = Depends(get_db)):
    if await auth_service.get_user_by_phone(db, body.phone):
        raise HTTPException(status_code=400, detail="Phone number already registered")
    if await auth_service.get_user_by_telegram_chat_id(db, body.telegram_chat_id):
        raise HTTPException(status_code=400, detail="Telegram account already registered")

    user = await auth_service.create_account(db, body.name, body.phone, body.telegram_chat_id)
    return user


@router.post("/create-account/request-otp", response_model=MessageResponse)
async def create_account_request_otp(body: RequestOTPRequest, db: AsyncSession = Depends(get_db)):
    result = await auth_service.request_otp(db, body.phone)
    if result != "sent":
        raise _otp_http_error(result)
    return {"message": "OTP sent to your Telegram"}


@router.post("/create-account/verify-otp", response_model=TokenResponse)
async def create_account_verify_otp(body: VerifyOTPRequest, db: AsyncSession = Depends(get_db)):
    token = await auth_service.verify_otp(db, body.phone, body.otp)
    if not token:
        raise HTTPException(status_code=401, detail="Invalid or expired OTP")
    return {"access_token": token}


# --- Sign in (phone only; telegram_chat_id is already on the user) ---


@router.post("/sign-in/request-otp", response_model=MessageResponse)
async def sign_in_request_otp(body: RequestOTPRequest, db: AsyncSession = Depends(get_db)):
    result = await auth_service.request_otp(db, body.phone)
    if result != "sent":
        raise _otp_http_error(result)
    return {"message": "OTP sent to your Telegram"}


@router.post("/sign-in/verify-otp", response_model=TokenResponse)
async def sign_in_verify_otp(body: VerifyOTPRequest, db: AsyncSession = Depends(get_db)):
    token = await auth_service.verify_otp(db, body.phone, body.otp)
    if not token:
        raise HTTPException(status_code=401, detail="Invalid or expired OTP")
    return {"access_token": token}
