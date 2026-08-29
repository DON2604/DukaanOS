from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    DATABASE_URL: str = "postgresql+asyncpg://user:pass@localhost/db"
    TELEGRAM_BOT_TOKEN: str = ""
    JWT_SECRET: str = "change-me"
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7  # 7 days
    OTP_EXPIRE_SECONDS: int = 300  # 5 minutes
    GEMINI_API_KEY: str = ""
    GEMINI_API_KEY_NEW: str = ""
    GEMINI_MODEL: str = "gemini-3.6-flash"
    MAX_INVOICE_IMAGE_BYTES: int = 10 * 1024 * 1024

    model_config = {"env_file": ".env"}


@lru_cache
def get_settings() -> Settings:
    return Settings()
