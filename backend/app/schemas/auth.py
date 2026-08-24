from pydantic import BaseModel, Field
import uuid
from datetime import datetime


# --- Request schemas ---

class CreateAccountRequest(BaseModel):
    name: str
    phone: str
    telegram_chat_id: int
    shop_name: str = Field(min_length=1, max_length=200)
    shop_type: str = Field(min_length=1, max_length=120)


class RequestOTPRequest(BaseModel):
    phone: str


class VerifyOTPRequest(BaseModel):
    phone: str
    otp: str


# --- Response schemas ---

class UserResponse(BaseModel):
    id: uuid.UUID
    name: str
    phone: str
    telegram_chat_id: int
    shop_name: str | None
    shop_type: str | None
    is_active: bool
    created_at: datetime

    model_config = {"from_attributes": True}


class TokenResponse(BaseModel):
    access_token: str
    session_id: uuid.UUID
    token_type: str = "bearer"


class SessionResponse(BaseModel):
    valid: bool
    user: UserResponse


class MessageResponse(BaseModel):
    message: str
