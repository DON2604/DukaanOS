import asyncio
import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI
from sqlalchemy import text
from app.db.session import async_session, engine
from app.db.base import Base
from app.routers import auth, inventory, invoices, khata, sales
from app.services.auth import delete_expired_unverified_users

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(name)s: %(message)s",
)

# Import models so Base.metadata picks them up
import app.models.intelligence  # noqa: F401
import app.models.inventory  # noqa: F401
import app.models.khata  # noqa: F401
import app.models.sales  # noqa: F401
import app.models.user  # noqa: F401


@asynccontextmanager
async def lifespan(app: FastAPI):
    logging.getLogger(__name__).info("DukaanOS server starting")
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
        # create_all does not update existing tables. Keep this migration
        # idempotent so previously-created development databases are upgraded.
        await conn.execute(
            text("ALTER TABLE users ADD COLUMN IF NOT EXISTS shop_name VARCHAR(200)")
        )
        await conn.execute(
            text("ALTER TABLE users ADD COLUMN IF NOT EXISTS shop_type VARCHAR(120)")
        )
        await conn.execute(
            text(
                "ALTER TABLE sales ADD COLUMN IF NOT EXISTS "
                "discount NUMERIC(20, 2) NOT NULL DEFAULT 0"
            )
        )
        await conn.execute(
            text(
                "ALTER TABLE inventory_items ADD COLUMN IF NOT EXISTS "
                "category VARCHAR(40)"
            )
        )
        await conn.execute(
            text(
                "ALTER TABLE inventory_items ADD COLUMN IF NOT EXISTS "
                "shelf_life_days INTEGER"
            )
        )
        await conn.execute(
            text(
                "ALTER TABLE inventory_items ADD COLUMN IF NOT EXISTS "
                "last_received_at TIMESTAMPTZ"
            )
        )
        await conn.execute(
            text("ALTER TABLE inventory_items ADD COLUMN IF NOT EXISTS expires_at DATE")
        )

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
app.include_router(invoices.router, prefix="/api")
app.include_router(inventory.router, prefix="/api")
app.include_router(khata.router, prefix="/api")
app.include_router(sales.router, prefix="/api")


@app.get("/health")
async def health():
    return {"status": "ok"}
