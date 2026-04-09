from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import HTMLResponse
from pathlib import Path
from summarizer_extractor import extract_text
from summarizer_ai import summarize_case

app = FastAPI(title="SnapLaw Case Summarizer")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"]
)

ALLOWED_TYPES = [
    'application/pdf',
    'image/jpeg', 'image/jpg',
    'image/png', 'image/tiff', 'image/webp'
]

MAX_SIZE = 20 * 1024 * 1024  # 20MB


@app.get("/", response_class=HTMLResponse)
async def serve_ui():
    """Serve the summarizer UI"""
    ui_path = Path(__file__).parent / "summarizer_ui.html"
    if ui_path.exists():
        return HTMLResponse(content=ui_path.read_text(encoding="utf-8"))
    return HTMLResponse(content="<h1>UI not found. Place summarizer_ui.html next to this file.</h1>")


@app.post("/api/summarize")
async def summarize(file: UploadFile = File(...)):

    # Validate file type
    if file.content_type not in ALLOWED_TYPES:
        raise HTTPException(
            status_code=400,
            detail="Invalid file. Upload PDF, JPG, or PNG only."
        )

    # Read file bytes
    file_bytes = await file.read()

    # Validate size
    if len(file_bytes) > MAX_SIZE:
        raise HTTPException(
            status_code=400,
            detail="File too large. Maximum size is 20MB."
        )

    # Step 1: Extract text
    extraction = extract_text(file_bytes, file.filename)

    if not extraction["success"]:
        raise HTTPException(
            status_code=422,
            detail=f"Could not read document: {extraction['error']}"
        )

    if len(extraction["text"].strip()) < 100:
        raise HTTPException(
            status_code=422,
            detail="Document appears empty or unreadable. Try a clearer scan."
        )

    # Step 2: AI summarization
    result = summarize_case(extraction["text"], file.filename)

    if not result["success"]:
        raise HTTPException(
            status_code=500,
            detail=result["error"]
        )

    return {
        "filename": file.filename,
        "pages": extraction["pages"],
        "extraction_method": extraction["method"],
        "original_text": extraction["text"],
        "summary": result["summary"],
        "original_length": result["original_length"],
        "summary_length": result["summary_length"],
        "truncated": result["truncated"],
        "status": "success"
    }


@app.get("/health")
def health():
    return {"status": "running", "module": "case-summarizer"}


if __name__ == "__main__":
    import uvicorn
    print("CASE SUMMARIZER READY")
    uvicorn.run("summarizer_app:app", host="0.0.0.0", port=8002, reload=True, timeout_keep_alive=120)
