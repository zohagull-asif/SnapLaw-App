"""
Contract Analysis API Router
RAG-based contract risk analysis endpoints.
Uses preloaded Pakistani law knowledge base - no user policies needed.
"""

from fastapi import APIRouter, UploadFile, File, Form, HTTPException, Depends
import logging

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/contracts", tags=["Contracts"])


def get_rag_service():
    from main import rag_service
    return rag_service


@router.post("/analyze")
async def analyze_contract(
    file: UploadFile = File(...),
    rag=Depends(get_rag_service),
):
    """
    Analyze a contract document against Pakistani law using RAG.

    Flow:
    1. Extract text from uploaded contract
    2. Split into clauses
    3. For each clause: embed with LegalBERT -> retrieve relevant law chunks from FAISS
    4. GPT classifies each clause against Pakistani law
    5. Returns structured risk report
    """
    # Validate file
    if not file.filename.endswith((".pdf", ".txt")):
        raise HTTPException(status_code=400, detail="Only PDF and TXT files are supported.")

    content = await file.read()
    if len(content) == 0:
        raise HTTPException(status_code=400, detail="Empty file uploaded.")

    if len(content) > 10 * 1024 * 1024:
        raise HTTPException(status_code=400, detail="File too large. Maximum 10MB.")

    try:
        result = await rag.analyze_contract(
            contract_content=content,
            filename=file.filename,
        )

        if "error" in result:
            raise HTTPException(status_code=500, detail=result["error"])

        return {"success": True, "data": result}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Contract analysis failed: {e}")
        raise HTTPException(status_code=500, detail=f"Analysis failed: {str(e)}")


@router.post("/analyze-text")
async def analyze_contract_text(
    contract_text: str = Form(...),
    rag=Depends(get_rag_service),
):
    """
    Analyze contract text directly (without file upload).
    Useful for pasting contract text.
    """
    if not contract_text.strip():
        raise HTTPException(status_code=400, detail="Contract text is empty.")

    try:
        # Convert text to bytes for the pipeline
        content = contract_text.encode("utf-8")
        result = await rag.analyze_contract(
            contract_content=content,
            filename="contract.txt",
        )

        if "error" in result:
            raise HTTPException(status_code=500, detail=result["error"])

        return {"success": True, "data": result}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Contract text analysis failed: {e}")
        raise HTTPException(status_code=500, detail=f"Analysis failed: {str(e)}")
