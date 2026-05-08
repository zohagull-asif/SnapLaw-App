from fastapi import APIRouter, UploadFile, File, HTTPException
from summarizer_extractor import extract_text
from summarizer_ai import summarize_case

router = APIRouter(prefix="/api", tags=["summarizer"])

ALLOWED_TYPES = [
    'application/pdf',
    'image/jpeg', 'image/jpg',
    'image/png', 'image/tiff', 'image/webp'
]

MAX_SIZE = 20 * 1024 * 1024  # 20MB


@router.post("/summarize")
async def summarize(file: UploadFile = File(...)):
    """Extract text from uploaded PDF/image and summarize with Groq AI."""

    if file.content_type not in ALLOWED_TYPES:
        raise HTTPException(
            status_code=400,
            detail="Invalid file. Upload PDF, JPG, or PNG only."
        )

    file_bytes = await file.read()

    if len(file_bytes) > MAX_SIZE:
        raise HTTPException(
            status_code=400,
            detail="File too large. Maximum size is 20MB."
        )

    # Step 1: Extract text from file
    extraction = extract_text(file_bytes, file.filename)

    if not extraction["success"]:
        raise HTTPException(
            status_code=422,
            detail=f"Could not read document: {extraction['error']}"
        )

    if len(extraction["text"].strip()) < 100:
        raise HTTPException(
            status_code=422,
            detail="Document appears empty or unreadable. Try a clearer scan or paste the text manually."
        )

    # Step 2: Summarize with Groq
    result = summarize_case(extraction["text"], file.filename or "document")

    if not result["success"]:
        raise HTTPException(status_code=500, detail=result["error"])

    return {
        "filename": file.filename,
        "pages": extraction.get("pages", 1),
        "extraction_method": extraction.get("method", "unknown"),
        "summary": result["summary"],
        "original_length": result["original_length"],
        "summary_length": result["summary_length"],
        "truncated": result["truncated"],
        "status": "success"
    }
