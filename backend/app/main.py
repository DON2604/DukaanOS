from contextlib import asynccontextmanager
from fastapi import FastAPI
from app.db.session import engine
from app.db.base import Base
from app.routers import auth

# Import models so Base.metadata picks them up
import app.models.user  # noqa: F401


@asynccontextmanager
async def lifespan(app: FastAPI):
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield


app = FastAPI(title="DukaanOS", version="0.1.0", lifespan=lifespan)

app.include_router(auth.router, prefix="/api")


@app.get("/health")
async def health():
    return {"status": "ok"}
