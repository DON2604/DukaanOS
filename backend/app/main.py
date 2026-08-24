import asyncio
import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI
from app.db.session import async_session, engine
from app.db.base import Base
from app.routers import auth
from app.services.auth import delete_expired_unverified_users

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(name)s: %(message)s",
)

# Import models so Base.metadata picks them up
import app.models.user  # noqa: F401


@asynccontextmanager
async def lifespan(app: FastAPI):
    logging.getLogger(__name__).info("DukaanOS server starting")
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    async def cleanup_loop():
        while True:
            async with async_session() as db:
                await delete_expired_unverified_users(db)
            await asyncio.sleep(30)

    cleanup_task = asyncio.create_task(cleanup_loop())
    try:
        yield
    finally:
        cleanup_task.cancel()
        await asyncio.gather(cleanup_task, return_exceptions=True)
        await engine.dispose()
        logging.getLogger(__name__).info("DukaanOS server stopped")


app = FastAPI(title="DukaanOS", version="0.1.0", lifespan=lifespan)

app.include_router(auth.router, prefix="/api")


@app.get("/health")
async def health():
    return {"status": "ok"}
