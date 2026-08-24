from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.dependencies import get_current_user
from app.models.user import User
from app.schemas.inventory import (
    InventoryBulkAddRequest,
    InventoryItemResponse,
)
from app.services.inventory import bulk_add_inventory, list_inventory


router = APIRouter(prefix="/inventory", tags=["inventory"])


@router.post(
    "/bulk",
    response_model=list[InventoryItemResponse],
    status_code=status.HTTP_201_CREATED,
)
async def add_inventory_bulk(
    body: InventoryBulkAddRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> list:
    try:
        items = await bulk_add_inventory(db, current_user.id, body)
        await db.commit()
    except SQLAlchemyError as exc:
        await db.rollback()
        raise HTTPException(
            status_code=500,
            detail="Could not save inventory; no items were added",
        ) from exc

    # The same normalized product may occur more than once in an invoice.
    # Return each resulting inventory row once.
    return list({item.id: item for item in items}.values())


@router.get("", response_model=list[InventoryItemResponse])
async def get_inventory(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> list:
    return await list_inventory(db, current_user.id)
