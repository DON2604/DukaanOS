import logging

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.dependencies import get_current_user
from app.models.user import User
from app.services.gemini import (
    GeminiConfigurationError,
    GeminiRateLimitError,
    GeminiResponseError,
    GeminiUpstreamError,
)
from app.services.image_recognition import ImageRecognitionService
from app.services.inventory import list_inventory
from app.schemas.image_recognition import (
    ImageAnalysisResponse,
    InventoryItemBase,
    ProductMatchResponse,
)


logger = logging.getLogger(__name__)

router = APIRouter(prefix="/image-recognition", tags=["image-recognition"])

MAX_IMAGE_BYTES = 10 * 1024 * 1024


def detect_image_mime(data: bytes) -> str | None:
    """Return the image MIME type implied by `data`'s magic bytes, else None.

    The multipart Content-Type header is not trusted: clients that omit it send
    application/octet-stream, and the detected type is what gets forwarded to
    Gemini, so it has to reflect the actual bytes. Only formats Gemini accepts
    are recognised.
    """
    if data[:3] == b"\xff\xd8\xff":
        return "image/jpeg"
    if data[:8] == b"\x89PNG\r\n\x1a\n":
        return "image/png"
    if data[:4] == b"RIFF" and data[8:12] == b"WEBP":
        return "image/webp"
    if data[4:8] == b"ftyp":
        brand = data[8:12]
        if brand in (b"heic", b"heix", b"hevc", b"hevx", b"mif1", b"msf1"):
            return "image/heic"
    return None


async def read_image_upload(file: UploadFile) -> tuple[bytes, str]:
    """Read an uploaded image, returning its bytes and detected MIME type."""
    image_data = await file.read()

    if len(image_data) > MAX_IMAGE_BYTES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Image file too large (max 10MB)",
        )

    mime_type = detect_image_mime(image_data)
    if mime_type is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="File must be a JPEG, PNG, WebP or HEIC image",
        )
    return image_data, mime_type


def gemini_http_error(exc: Exception) -> HTTPException:
    """Translate a Gemini failure into the status code the client should see."""
    if isinstance(exc, GeminiRateLimitError):
        headers = {"Retry-After": str(exc.retry_after)} if exc.retry_after else None
        detail = "Image recognition quota exceeded; try again later"
        if exc.retry_after:
            detail = (
                "Image recognition quota exceeded; "
                f"try again in about {exc.retry_after}s"
            )
        return HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail=detail,
            headers=headers,
        )
    if isinstance(exc, GeminiConfigurationError):
        return HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Image recognition is not configured",
        )
    if isinstance(exc, GeminiResponseError):
        return HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail="Image recognition returned an unreadable result",
        )
    return HTTPException(
        status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
        detail="Image recognition is temporarily unavailable",
    )


@router.post("/analyze", response_model=ImageAnalysisResponse)
async def analyze_image(
    file: UploadFile = File(..., description="Image file to analyze"),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Analyze an uploaded image to identify products and their weights.
    """
    image_data, mime_type = await read_image_upload(file)

    try:
        # Analyze the image
        recognition_service = ImageRecognitionService()
        analysis_result = await recognition_service.analyze_product_image(
            image_data, mime_type
        )

        return ImageAnalysisResponse(**analysis_result)

    except (GeminiConfigurationError, GeminiUpstreamError, GeminiResponseError) as exc:
        raise gemini_http_error(exc) from exc
    except Exception as e:
        logger.exception("Image analysis failed")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Image analysis failed: {str(e)}"
        )


@router.post("/match-inventory", response_model=list[ProductMatchResponse])
async def match_with_inventory(
    file: UploadFile = File(..., description="Image file to analyze and match"),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Analyze an image and match identified products with existing inventory.
    """
    image_data, mime_type = await read_image_upload(file)

    try:
        # Get user's inventory
        inventory_items = await list_inventory(db, current_user.id)

        # Analyze the image
        recognition_service = ImageRecognitionService()
        analysis_result = await recognition_service.analyze_product_image(
            image_data, mime_type
        )

        # Match with inventory
        matches = await recognition_service.match_with_inventory(
            analysis_result.get('products', []),
            inventory_items
        )
        
        # Convert to response models
        response_matches = []
        for match in matches:
            inventory_match = match.get('inventory_match')
            if inventory_match is not None:
                inventory_match = InventoryItemBase.model_validate(
                    inventory_match,
                    from_attributes=True,
                )
            response_match = ProductMatchResponse(
                recognized_product=match['recognized_product'],
                inventory_match=inventory_match,
                match_confidence=match['match_confidence'],
                can_deduct=match['can_deduct'],
                suggested_quantity=match.get('suggested_quantity', 1.0),
                insufficient_stock_message=match.get('insufficient_stock_message'),
            )
            response_matches.append(response_match)
        
        return response_matches

    except (GeminiConfigurationError, GeminiUpstreamError, GeminiResponseError) as exc:
        raise gemini_http_error(exc) from exc
    except Exception as e:
        logger.exception("Image matching failed")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Image matching failed: {str(e)}"
        )