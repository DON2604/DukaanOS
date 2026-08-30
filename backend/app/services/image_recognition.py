import base64
import math
import re
from typing import Any

from app.services.gemini import json_object_from_response, request_gemini_json


_NUMBER_PATTERN = re.compile(r"-?\d+(?:\.\d+)?")
_IMAGE_QUALITIES = {"good", "fair", "poor"}

_PRODUCT_PROMPT = """Analyze this image and identify any products, especially fruits,
vegetables, or food items. Return JSON only, with exactly this shape:
{
  "products": [
    {
      "name": string,
      "category": string,
      "estimated_weight": number|null,
      "confidence": number,
      "description": string
    }
  ],
  "total_estimated_weight": number|null,
  "image_quality": "good"|"fair"|"poor"
}
Rules:
- Only identify actual products/food items, ignore packaging or background objects.
- Be specific with product names ("Red Apple" rather than "Apple" if clearly red).
- Weights are in grams as plain JSON numbers, with no units or thousands separators.
  Estimates must be realistic (apple 150-200g, banana 100-150g).
- If several items of the same product are visible, include the count in the name.
- Confidence is 0 to 1. Set it low when the image is unclear.
- Return an empty products array if no food items are clearly identifiable."""


def _as_number(value: Any) -> float | None:
    """Coerce a model-supplied value to a finite float, or None if unusable."""
    if value is None or isinstance(value, bool):
        return None
    if isinstance(value, str):
        match = _NUMBER_PATTERN.search(value.replace(",", ""))
        if match is None:
            return None
        value = match.group(0)
    try:
        number = float(value)
    except (TypeError, ValueError):
        return None
    return number if math.isfinite(number) else None


def _as_positive(value: Any) -> float | None:
    number = _as_number(value)
    return number if number is not None and number > 0 else None


def _as_confidence(value: Any) -> float:
    number = _as_number(value)
    if number is None or number <= 0:
        return 0.0
    if number > 1:
        # Models sometimes answer on a 0-100 scale.
        number = number / 100 if number <= 100 else 1.0
    return min(number, 1.0)


def _as_text(value: Any, limit: int) -> str:
    if value is None or isinstance(value, bool):
        return ""
    if not isinstance(value, str):
        value = str(value)
    return value.strip()[:limit]


def _clean_products(raw: Any) -> list[dict]:
    """Coerce the model's product list into RecognizedProduct-shaped dicts.

    Anything without a usable name is dropped; every other field is degraded to a
    safe default rather than raising, so one malformed entry cannot fail the request.
    """
    if not isinstance(raw, list):
        return []
    products: list[dict] = []
    for entry in raw[:50]:
        if not isinstance(entry, dict):
            continue
        name = _as_text(entry.get("name"), 200)
        if not name:
            continue
        products.append({
            "name": name,
            "category": _as_text(entry.get("category"), 100) or "unknown",
            "estimated_weight": _as_positive(entry.get("estimated_weight")),
            "confidence": _as_confidence(entry.get("confidence")),
            "description": _as_text(entry.get("description"), 500),
        })
    return products


class ImageRecognitionService:
    async def analyze_product_image(
        self, image_data: bytes, mime_type: str = "image/jpeg"
    ) -> dict:
        """Identify products and their weights in an image.

        Raises the Gemini* errors on upstream failure so the caller can return a
        real status code. Swallowing them here made a spent quota look like an
        empty result, and the client reported "no products found" instead.
        """
        text = await request_gemini_json(
            [
                {"text": _PRODUCT_PROMPT},
                {
                    "inline_data": {
                        "mime_type": mime_type,
                        "data": base64.b64encode(image_data).decode("ascii"),
                    }
                },
            ],
            "the product image",
        )
        payload = json_object_from_response(text)

        quality = _as_text(payload.get("image_quality"), 20).lower()
        return {
            "products": _clean_products(payload.get("products")),
            "total_estimated_weight": _as_positive(payload.get("total_estimated_weight")),
            "image_quality": quality if quality in _IMAGE_QUALITIES else "fair",
        }


    async def match_with_inventory(self, recognized_products: list, inventory_items: list) -> list:
        """
        Match recognized products with existing inventory items.
        
        Args:
            recognized_products: List of products from image analysis
            inventory_items: List of inventory items from database
            
        Returns:
            List of matched products with inventory information
        """
        matches = []
        
        for product in recognized_products:
            product_name = product.get('name', '').lower().strip()
            estimated_weight = product.get('estimated_weight')
            
            # Find best match in inventory
            best_match = None
            best_score = 0.0
            
            for inventory_item in inventory_items:
                inventory_name = inventory_item.name.lower().strip()
                
                # Simple matching algorithm
                score = 0.0
                
                # Exact name match
                if product_name == inventory_name:
                    score = 1.0
                # Partial name match
                elif product_name in inventory_name or inventory_name in product_name:
                    score = 0.8
                # Keyword matching for common variations
                elif self._check_product_keywords(product_name, inventory_name):
                    score = 0.6
                
                if score > best_score and score > 0.5:  # Minimum threshold
                    best_score = score
                    best_match = inventory_item
            
            match_result = {
                "recognized_product": product,
                "inventory_match": best_match,
                "match_confidence": best_score,
                "can_deduct": best_match is not None and best_match.quantity > 0,
            }

            if best_match is None:
                match_result["can_deduct"] = True
                match_result["insufficient_stock_message"] = (
                    "Not found in inventory. This item can still be added manually."
                )
            else:
                # Enhanced weight-based quantity calculation
                suggested_quantity = self._calculate_suggested_quantity(
                    estimated_weight, best_match
                )
                match_result["suggested_quantity"] = suggested_quantity

                # Check if we have enough inventory for the suggested quantity
                if best_match.quantity < suggested_quantity:
                    match_result["can_deduct"] = False
                    match_result["insufficient_stock_message"] = (
                        f"Need {suggested_quantity} but only {best_match.quantity} available"
                    )

            matches.append(match_result)
        
        return matches
    
    def _calculate_suggested_quantity(self, estimated_weight: float, inventory_item) -> float:
        """Calculate suggested quantity based on weight and inventory unit."""
        if not estimated_weight:
            return 1.0
        
        unit = inventory_item.unit or ""
        unit_lower = unit.lower().strip()
        
        # Weight conversions based on inventory unit
        if 'kg' in unit_lower or 'kilogram' in unit_lower:
            # Convert grams to kilograms
            return round(estimated_weight / 1000, 3)
        elif 'g' in unit_lower and 'kg' not in unit_lower:  # grams but not kilograms
            # Keep as grams
            return round(estimated_weight, 0)
        elif 'lb' in unit_lower or 'pound' in unit_lower:
            # Convert grams to pounds (1 pound = 453.592 grams)
            return round(estimated_weight / 453.592, 3)
        elif 'oz' in unit_lower or 'ounce' in unit_lower:
            # Convert grams to ounces (1 ounce = 28.3495 grams)
            return round(estimated_weight / 28.3495, 2)
        elif any(word in unit_lower for word in ['piece', 'pcs', 'unit', 'each', 'item']):
            # For piece-based items, use weight to estimate count
            # This is a rough estimation based on common fruit/vegetable weights
            weight_to_pieces_map = {
                'apple': 150,     # Average apple weight
                'banana': 120,    # Average banana weight
                'orange': 180,    # Average orange weight
                'tomato': 100,    # Average tomato weight
                'potato': 200,    # Average potato weight
                'onion': 150,     # Average onion weight
                'lemon': 60,      # Average lemon weight
                'mango': 300,     # Average mango weight
            }
            
            # Try to find matching weight estimation
            item_name_lower = inventory_item.name.lower()
            estimated_piece_weight = None
            
            for fruit_name, avg_weight in weight_to_pieces_map.items():
                if fruit_name in item_name_lower:
                    estimated_piece_weight = avg_weight
                    break
            
            if estimated_piece_weight:
                return max(1, round(estimated_weight / estimated_piece_weight))
            else:
                # Default: assume medium-sized items (150g each)
                return max(1, round(estimated_weight / 150))
        else:
            # Default case: treat as 1 unit
            return 1.0
    
    def _check_product_keywords(self, product_name: str, inventory_name: str) -> bool:
        """Check if product names match based on common keywords."""
        # Common product variations
        keywords_map = {
            'apple': ['apple', 'seb'],
            'banana': ['banana', 'kela'],
            'orange': ['orange', 'santra'],
            'tomato': ['tomato', 'tamatar'],
            'potato': ['potato', 'aloo'],
            'onion': ['onion', 'pyaz'],
            'carrot': ['carrot', 'gajar'],
            'lemon': ['lemon', 'nimbu'],
            'mango': ['mango', 'aam']
        }
        
        for base_name, variations in keywords_map.items():
            if any(var in product_name for var in variations) and any(var in inventory_name for var in variations):
                return True
        
        return False