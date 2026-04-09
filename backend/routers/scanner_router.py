"""
Evidence Scanner Router — OCR + Redaction endpoints for SnapLaw.
"""

from fastapi import APIRouter, UploadFile, File, HTTPException
from services.ocr_engine import process_document
from services.redaction_engine import process_redaction
import logging

logger = logging.getLogger(__name__)

router = APIRouter()

MAX_FILE_SIZE = 10 * 1024 * 1024  # 10MB
ALLOWED_TYPES = [
    'image/jpeg', 'image/png', 'image/jpg',
    'application/pdf', 'image/tiff', 'image/webp',
    'application/octet-stream',  # fallback for some clients
]


@router.post("/api/scan-document")
async def scan_document(file: UploadFile = File(...)):
    """Upload a document, extract text via OCR, and redact sensitive info."""

    logger.info(f"Scanning document: {file.filename} ({file.content_type})")

    # Validate file type
    if file.content_type and file.content_type not in ALLOWED_TYPES:
        # Also check by extension as fallback
        ext = file.filename.lower().split('.')[-1] if file.filename else ''
        if ext not in ('pdf', 'jpg', 'jpeg', 'png', 'bmp', 'tiff', 'webp'):
            raise HTTPException(
                status_code=400,
                detail="Invalid file type. Upload PDF, JPG, or PNG only."
            )

    # Read file bytes
    file_bytes = await file.read()

    # Validate file size
    if len(file_bytes) > MAX_FILE_SIZE:
        raise HTTPException(
            status_code=400,
            detail="File too large. Maximum size is 10MB."
        )

    # Step 1: Extract text via OCR
    ocr_result = process_document(file_bytes, file.filename or "document")

    if not ocr_result["success"]:
        raise HTTPException(
            status_code=500,
            detail=f"Could not read document: {ocr_result.get('error', 'Unknown error')}"
        )

    if not ocr_result["text"].strip():
        raise HTTPException(
            status_code=422,
            detail="No text found in document. Make sure the image is clear and contains readable text."
        )

    # Step 2: Run redaction on extracted text
    redaction_result = process_redaction(ocr_result["text"])

    logger.info(
        f"Scan complete: {ocr_result['pages']} pages, "
        f"{redaction_result['total_redacted']} items redacted"
    )

    return {
        "filename": file.filename,
        "pages": ocr_result["pages"],
        "ocr_method": ocr_result["method"],
        "extracted_text": ocr_result["text"],
        "redacted_text": redaction_result["redacted_text"],
        "total_redacted": redaction_result["total_redacted"],
        "redacted_items": redaction_result["redacted_items"],
        "is_clean": redaction_result["is_clean"],
        "status": "success"
    }


@router.post("/api/redact-text")
async def redact_text_only(text: dict):
    """Redact sensitive info from provided text (no OCR needed)."""
    input_text = text.get("text", "")
    if not input_text.strip():
        raise HTTPException(status_code=400, detail="No text provided.")

    result = process_redaction(input_text)
    return {
        "redacted_text": result["redacted_text"],
        "total_redacted": result["total_redacted"],
        "redacted_items": result["redacted_items"],
        "is_clean": result["is_clean"],
        "status": "success"
    }
