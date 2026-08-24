from fastapi import APIRouter, Depends, File, HTTPException, UploadFile, status

from app.config import get_settings
from app.dependencies import get_current_user
from app.models.user import User
from app.schemas.invoice import InvoiceAnalysis
from app.services.gemini import (
    GeminiConfigurationError,
    GeminiResponseError,
    GeminiUpstreamError,
    analyze_invoice_image,
)


router = APIRouter(prefix="/invoices", tags=["invoices"])
settings = get_settings()
ALLOWED_IMAGE_TYPES = {
    "image/jpeg",
    "image/png",
    "image/webp",
    "image/heic",
    "image/heif",
}


def _detected_image_type(data: bytes) -> str | None:
    if data.startswith(b"\xff\xd8\xff"):
        return "image/jpeg"
    if data.startswith(b"\x89PNG\r\n\x1a\n"):
        return "image/png"
    if len(data) >= 12 and data[:4] == b"RIFF" and data[8:12] == b"WEBP":
        return "image/webp"
    if len(data) >= 12 and data[4:8] == b"ftyp":
        brand = data[8:12]
        if brand in {b"heic", b"heix", b"hevc", b"hevx"}:
            return "image/heic"
        if brand in {b"mif1", b"msf1"}:
            return "image/heif"
    return None


@router.post("/analyze", response_model=InvoiceAnalysis)
async def analyze_invoice(
    image: UploadFile = File(...),
    _current_user: User = Depends(get_current_user),
) -> InvoiceAnalysis:
    mime_type = (image.content_type or "").lower().split(";", 1)[0].strip()
    if mime_type not in ALLOWED_IMAGE_TYPES:
        raise HTTPException(
            status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
            detail="Upload a JPEG, PNG, WebP, HEIC, or HEIF invoice image",
        )

    image_bytes = await image.read(settings.MAX_INVOICE_IMAGE_BYTES + 1)
    await image.close()
    if not image_bytes:
        raise HTTPException(status_code=400, detail="Uploaded invoice image is empty")
    if len(image_bytes) > settings.MAX_INVOICE_IMAGE_BYTES:
        max_mb = settings.MAX_INVOICE_IMAGE_BYTES / (1024 * 1024)
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail=f"Invoice image exceeds the {max_mb:g} MB limit",
        )
    detected_type = _detected_image_type(image_bytes)
    heif_types = {"image/heic", "image/heif"}
    if detected_type != mime_type and not (
        detected_type in heif_types and mime_type in heif_types
    ):
        raise HTTPException(
            status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
            detail="File contents do not match the declared image type",
        )

    try:
        return await analyze_invoice_image(image_bytes, mime_type)
    except GeminiConfigurationError as exc:
        raise HTTPException(status_code=503, detail=str(exc)) from exc
    except GeminiUpstreamError as exc:
        raise HTTPException(status_code=502, detail=str(exc)) from exc
    except GeminiResponseError as exc:
        raise HTTPException(status_code=502, detail=str(exc)) from exc
