from typing import Any, Optional
from uuid import UUID
from decimal import Decimal
from datetime import datetime

from pydantic import BaseModel, ConfigDict


class RecognizedProduct(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    name: str
    category: str
    estimated_weight: Optional[float] = None
    confidence: float
    description: str


class ImageAnalysisResponse(BaseModel):
    products: list[RecognizedProduct]
    total_estimated_weight: Optional[float] = None
    image_quality: str
    error: Optional[str] = None


class InventoryItemBase(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    name: str
    quantity: Decimal
    unit: Optional[str] = None
    selling_price: Optional[Decimal] = None
    category: Optional[str] = None


class ProductMatchResponse(BaseModel):
    recognized_product: RecognizedProduct
    inventory_match: Optional[InventoryItemBase] = None
    match_confidence: float
    can_deduct: bool
    suggested_quantity: float = 1.0
    insufficient_stock_message: Optional[str] = None


class InventoryDeductionRequest(BaseModel):
    inventory_item_id: UUID
    quantity: float
    reference_id: Optional[str] = None  # For tracking the image scan transaction