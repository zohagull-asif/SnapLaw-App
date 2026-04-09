"""
LawBot API Router
Provides endpoints for all LawBot features:
  - Legal Q&A (category-filtered knowledge base)
  - Contract Simplifier
  - Abuse Detection (LLM-powered)
  - SafeSpace (Abuse Guidance)
"""

import logging
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional
from services.lawbot_service import lawbot_service, legal_qa
from services.abuse_detector import detect_abuse
from services.lawbot_chat_service import chat_with_lawbot, clear_chat_session

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api", tags=["LawBot"])


class LawBotRequest(BaseModel):
    type: str  # "qa", "simplify", "abuse", "guidance"
    text: str
    language: str = "en"  # "en" or "urdu" (for simplifier Urdu translation)


class LegalQARequest(BaseModel):
    question: str
    category: str = "auto"


class AbuseDetectRequest(BaseModel):
    text: str


class ChatRequest(BaseModel):
    message: str
    session_id: str = "default"


@router.post("/lawbot")
async def process_lawbot(request: LawBotRequest):
    """
    Process a LawBot request (unified endpoint).

    Body:
        type: "qa" | "simplify" | "bias" | "guidance"
        text: user input text
    """
    valid_types = ["qa", "simplify", "bias", "guidance"]
    if request.type not in valid_types:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid type '{request.type}'. Must be one of: {valid_types}",
        )

    if not request.text or not request.text.strip():
        raise HTTPException(status_code=400, detail="Text cannot be empty")

    try:
        logger.info(f"LawBot request: type={request.type}, text_length={len(request.text)}")
        result = lawbot_service.process_request(request.type, request.text, language=request.language)

        if "error" in result:
            raise HTTPException(status_code=400, detail=result["error"])

        return result
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"LawBot error: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"LawBot processing failed: {str(e)}")


@router.post("/legal-qa")
async def legal_qa_endpoint(request: LegalQARequest):
    """
    Legal Q&A endpoint with category-filtered knowledge base.

    Body:
        question: user's legal question
        category: "auto" (detect automatically) or one of:
                  traffic_accident, theft_robbery, family_law,
                  labor_law, property_law, general_criminal
    """
    if not request.question or not request.question.strip():
        raise HTTPException(status_code=400, detail="Question cannot be empty")

    try:
        logger.info(f"Legal Q&A request: question_length={len(request.question)}, category={request.category}")

        # If category is specified (not auto), pass it through
        if request.category != "auto":
            from services.legal_kb import build_legal_answer, get_category_label
            result = build_legal_answer(request.question, request.category)
            return {
                "answer": result["answer"],
                "category": result["category"],
                "category_label": result["category_label"],
                "confidence": result["confidence"],
                "sources": result["sources"],
                "sections": result["sections"],
            }

        # Auto-detect category
        result = legal_qa(request.question)
        return {
            "answer": result["answer"],
            "category": result.get("category", ""),
            "category_label": result.get("category_label", ""),
            "confidence": result.get("confidence", 0),
            "sources": result.get("sources", []),
            "sections": result.get("sections", []),
        }
    except Exception as e:
        logger.error(f"Legal Q&A error: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Legal Q&A failed: {str(e)}")


@router.post("/detect-abuse")
async def detect_abuse_endpoint(request: AbuseDetectRequest):
    """
    Abuse Detection endpoint — LLM-powered analysis for toxic,
    hateful, threatening, or abusive language with Pakistani law references.
    Supports English, Urdu, and Roman Urdu.
    """
    if not request.text or not request.text.strip():
        raise HTTPException(status_code=400, detail="Text cannot be empty")

    try:
        logger.info(f"Abuse detection request: text_length={len(request.text)}")
        result = detect_abuse(request.text)
        return result
    except Exception as e:
        logger.error(f"Abuse detection error: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Abuse detection failed: {str(e)}")


@router.post("/lawbot-chat")
async def lawbot_chat_endpoint(request: ChatRequest):
    """
    LawBot Chat — Gemini-powered Pakistani law chatbot.
    Maintains conversation history per session.
    Supports English, Urdu, and Roman Urdu.
    """
    if not request.message or not request.message.strip():
        raise HTTPException(status_code=400, detail="Message cannot be empty")

    try:
        logger.info(f"LawBot chat: session={request.session_id}, msg_length={len(request.message)}")
        result = chat_with_lawbot(request.message, request.session_id)
        return result
    except Exception as e:
        logger.error(f"LawBot chat error: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"LawBot chat failed: {str(e)}")


@router.post("/lawbot-chat/clear")
async def clear_chat_endpoint(request: ChatRequest):
    """Clear a LawBot chat session."""
    result = clear_chat_session(request.session_id)
    return result
