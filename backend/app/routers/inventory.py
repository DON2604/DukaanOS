from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.ext.asyncio import AsyncSession
from uuid import uuid4
from datetime import datetime, timezone

from app.db.session import get_db
from app.dependencies import get_current_user
from app.models.user import User
from app.models.sales import InventoryMovement
from app.schemas.inventory import (
    InventoryBulkAddRequest,
    InventoryItemResponse,
)
from app.schemas.image_recognition import InventoryDeductionRequest
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


@router.post("/deduct", status_code=status.HTTP_200_OK)
async def deduct_inventory(
    deduction: InventoryDeductionRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Deduct inventory quantity for image-recognized products.
    """
    try:
        from sqlalchemy import select, update
        from app.models.inventory import InventoryItem
        from decimal import Decimal
        
        # Get the inventory item
        result = await db.execute(
            select(InventoryItem).where(
                InventoryItem.id == deduction.inventory_item_id,
                InventoryItem.user_id == current_user.id
            )
        )
        inventory_item = result.scalar_one_or_none()
        
        if not inventory_item:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Inventory item not found"
            )
        
        deduction_quantity = Decimal(str(deduction.quantity))
        
        # Check if sufficient quantity available (with small tolerance for float precision)
        tolerance = Decimal('0.001')
        if inventory_item.quantity + tolerance < deduction_quantity:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Insufficient quantity. Available: {inventory_item.quantity}, Requested: {deduction_quantity}"
            )
        
        # Calculate new quantity
        new_quantity = inventory_item.quantity - deduction_quantity
        # Ensure we don't go below zero due to floating point precision
        if new_quantity < Decimal('0'):
            new_quantity = Decimal('0')
        
        # Update inventory quantity
        await db.execute(
            update(InventoryItem)
            .where(InventoryItem.id == deduction.inventory_item_id)
            .values(
                quantity=new_quantity,
                updated_at=datetime.now(timezone.utc)
            )
        )
        
        # Record the movement
        movement = InventoryMovement(
            user_id=current_user.id,
            inventory_item_id=inventory_item.id,
            movement_type="sale",
            quantity_delta=-deduction_quantity,
            unit_cost=inventory_item.selling_price,
            reference_id=deduction.reference_id or uuid4(),
            idempotency_key=uuid4()
        )
        db.add(movement)
        
        await db.commit()
        
        return {
            "message": "Inventory deducted successfully",
            "item_name": inventory_item.name,
            "deducted_quantity": float(deduction_quantity),
            "remaining_quantity": float(new_quantity),
            "unit": inventory_item.unit
        }
        
    except SQLAlchemyError as exc:
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to deduct inventory"
        ) from exc
