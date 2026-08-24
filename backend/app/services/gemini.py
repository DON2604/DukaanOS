import base64
import json
import logging
import re
from decimal import Decimal
from typing import Any
from urllib.parse import quote

import httpx
from pydantic import ValidationError

from app.config import get_settings
from app.schemas.invoice import InvoiceAnalysis


logger = logging.getLogger(__name__)
settings = get_settings()

_PROMPT = """Extract this supplier invoice into JSON. Return JSON only, with exactly this shape:
{
  "invoice_number": string|null,
  "date": "YYYY-MM-DD"|null,
  "supplier": {"name": string|null, "phone": string|null},
  "items": [
    {
      "name": string,
      "quantity": number|null,
      "unit": string|null,
      "unit_price": number|null,
      "total": number|null
    }
  ],
  "subtotal": number|null,
  "tax": number|null,
  "grand_total": number|null
}
Do not guess illegible values. Use null instead. Keep all numeric values as JSON numbers without
currency symbols or thousands separators. Every item must have a non-blank name."""


class GeminiConfigurationError(RuntimeError):
    pass


class GeminiUpstreamError(RuntimeError):
    pass


class GeminiResponseError(RuntimeError):
    pass


def parse_invoice_response(text: str) -> InvoiceAnalysis:
    cleaned = text.strip()
    fenced = re.fullmatch(r"```(?:json)?\s*(.*?)\s*```", cleaned, re.DOTALL | re.IGNORECASE)
    if fenced:
        cleaned = fenced.group(1).strip()

    payload: Any = None
    try:
        payload = json.loads(cleaned, parse_float=Decimal, parse_int=Decimal)
    except json.JSONDecodeError:
        decoder = json.JSONDecoder(parse_float=Decimal, parse_int=Decimal)
        for index, character in enumerate(cleaned):
            if character != "{":
                continue
            try:
                candidate, _ = decoder.raw_decode(cleaned[index:])
            except json.JSONDecodeError:
                continue
            if isinstance(candidate, dict):
                payload = candidate
                break

    if not isinstance(payload, dict):
        raise GeminiResponseError("Gemini did not return a JSON invoice object")

    try:
        return InvoiceAnalysis.model_validate(payload)
    except ValidationError as exc:
        logger.warning("Gemini invoice schema validation failed: %s", exc)
        raise GeminiResponseError("Gemini returned invoice data in an invalid format") from exc


async def analyze_invoice_image(image: bytes, mime_type: str) -> InvoiceAnalysis:
    if not settings.GEMINI_API_KEY:
        raise GeminiConfigurationError("Gemini invoice analysis is not configured")

    model = quote(settings.GEMINI_MODEL.strip(), safe="-_.")
    if not model:
        raise GeminiConfigurationError("GEMINI_MODEL is not configured")
    url = (
        "https://generativelanguage.googleapis.com/v1beta/models/"
        f"{model}:generateContent"
    )
    body = {
        "contents": [
            {
                "role": "user",
                "parts": [
                    {"text": _PROMPT},
                    {
                        "inline_data": {
                            "mime_type": mime_type,
                            "data": base64.b64encode(image).decode("ascii"),
                        }
                    },
                ],
            }
        ],
        "generationConfig": {
            "temperature": 0,
            "responseMimeType": "application/json",
        },
    }

    try:
        async with httpx.AsyncClient(timeout=httpx.Timeout(45.0, connect=10.0)) as client:
            response = await client.post(
                url,
                headers={"x-goog-api-key": settings.GEMINI_API_KEY},
                json=body,
            )
    except httpx.TimeoutException as exc:
        raise GeminiUpstreamError("Gemini timed out while analyzing the invoice") from exc
    except httpx.HTTPError as exc:
        raise GeminiUpstreamError("Could not contact Gemini") from exc

    if response.is_error:
        logger.warning(
            "Gemini request failed with status %s: %s",
            response.status_code,
            response.text[:500],
        )
        if response.status_code in (401, 403):
            raise GeminiConfigurationError("Gemini rejected the configured API key")
        if response.status_code == 429:
            raise GeminiUpstreamError("Gemini rate limit exceeded; try again later")
        raise GeminiUpstreamError("Gemini could not analyze the invoice")

    try:
        data = response.json()
        candidates = data["candidates"]
        parts = candidates[0]["content"]["parts"]
        text = "".join(part.get("text", "") for part in parts)
    except (ValueError, KeyError, IndexError, TypeError) as exc:
        logger.warning("Unexpected Gemini response: %s", response.text[:500])
        raise GeminiResponseError("Gemini returned an unexpected response") from exc

    if not text.strip():
        raise GeminiResponseError("Gemini returned no invoice data")
    return parse_invoice_response(text)
