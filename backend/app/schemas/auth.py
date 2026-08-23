from pydantic import BaseModel
import uuid
from datetime import datetime


# --- Request schemas ---

class CreateAccountRequest(BaseModel):
    name: str
    phone: str
    telegram_chat_id: int


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
    is_active: bool
    created_at: datetime

    model_config = {"from_attributes": True}


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"


class MessageResponse(BaseModel):
    message: str
