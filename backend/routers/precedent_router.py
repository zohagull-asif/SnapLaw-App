"""
Legal Precedent Search API Router
Endpoints for searching Pakistani case law.
"""

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional, List
import logging

from services.precedent_service import precedent_service

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/precedents", tags=["Precedents"])


class SearchRequest(BaseModel):
    query: str
    top_k: int = 5
    court_filter: Optional[str] = None
    year_filter: Optional[str] = None


class SearchResult(BaseModel):
    id: str
    title: str
    case_number: str
    court: str
    year: str
    summary: str
    judgment: str
    keywords: List[str]
    category: str
    relevance_score: float


@router.post("/search")
async def search_precedents(request: SearchRequest):
    """
    Search legal precedents using semantic similarity.

    The query is embedded with LegalBERT and matched against
    the case law database using FAISS cosine similarity.
    """
    if not request.query.strip():
        raise HTTPException(status_code=400, detail="Search query cannot be empty.")

    if request.top_k < 1 or request.top_k > 20:
        raise HTTPException(status_code=400, detail="top_k must be between 1 and 20.")

    try:
        results = precedent_service.search(
            query=request.query,
            top_k=request.top_k,
            court_filter=request.court_filter,
            year_filter=request.year_filter,
        )

        return {
            "success": True,
            "query": request.query,
            "result_count": len(results),
            "results": results,
        }
    except Exception as e:
        logger.error(f"Precedent search failed: {e}")
        raise HTTPException(status_code=500, detail=f"Search failed: {str(e)}")


@router.get("/cases")
async def list_all_cases():
    """Get all available cases in the database (for browsing)."""
    try:
        if not precedent_service.cases:
            precedent_service.load_seed_data()

        cases = [
            {
                "id": c["id"],
                "title": c["title"],
                "case_number": c["case_number"],
                "court": c["court"],
                "year": c["year"],
                "category": c["category"],
                "summary": c["summary"][:200] + "...",
                "keywords": c["keywords"],
            }
            for c in precedent_service.cases
        ]
        return {"success": True, "cases": cases, "total": len(cases)}
    except Exception as e:
        logger.error(f"Failed to list cases: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/cases/{case_id}")
async def get_case_detail(case_id: str):
    """Get full details of a specific case."""
    if not precedent_service.cases:
        precedent_service.load_seed_data()

    case = next((c for c in precedent_service.cases if c["id"] == case_id), None)
    if not case:
        raise HTTPException(status_code=404, detail="Case not found.")

    return {"success": True, "case": case}
