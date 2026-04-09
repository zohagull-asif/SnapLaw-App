"""
SnapLaw RAG Backend
FastAPI server with LegalBERT embeddings, FAISS search, and rule-based legal analysis.
No external API dependencies - works fully offline.
"""

import os
import logging
from contextlib import asynccontextmanager
from dotenv import load_dotenv
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from supabase import create_client, Client

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger(__name__)

# Global clients
supabase_client: Client = None
rag_service = None


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Startup and shutdown events."""
    global supabase_client, rag_service

    logger.info("Starting SnapLaw RAG Backend...")

    # Initialize Supabase
    supabase_url = os.getenv("SUPABASE_URL")
    supabase_key = os.getenv("SUPABASE_ANON_KEY")
    if supabase_url and supabase_key:
        supabase_client = create_client(supabase_url, supabase_key)
        logger.info("Supabase client initialized")
    else:
        logger.warning("Supabase credentials not found. Database features disabled.")

    # Load embedding model (LegalBERT or OpenAI fallback)
    from models.embeddings import legal_bert
    try:
        legal_bert.load_model()
        if legal_bert.is_using_openai:
            logger.info("Using OpenAI embeddings (LegalBERT unavailable)")
        else:
            logger.info("Using LegalBERT embeddings")
    except Exception as e:
        logger.error(f"Failed to load any embedding model: {e}")
        raise

    # Initialize RAG service (no external API keys needed)
    from services.rag_service import RAGService
    rag_service = RAGService()
    logger.info("RAG service initialized (rule-based, no external API needed)")

    # Load Pakistani law knowledge base (preloaded for all users)
    from services.law_loader import law_knowledge_base
    try:
        law_knowledge_base.load_and_index()
        logger.info(f"Pakistani law knowledge base: {law_knowledge_base.chunk_count} chunks indexed")
    except Exception as e:
        logger.error(f"Failed to load law knowledge base: {e}")

    # Load legal precedent seed data
    from services.precedent_service import precedent_service
    try:
        precedent_service.load_seed_data()
    except Exception as e:
        logger.error(f"Failed to load precedent data: {e}")

    logger.info("SnapLaw RAG Backend ready!")
    yield

    # Shutdown
    logger.info("Shutting down SnapLaw RAG Backend...")


# Create FastAPI app
app = FastAPI(
    title="SnapLaw RAG Backend",
    description="LegalBERT + FAISS + Rule-based RAG pipeline for contract risk analysis and legal precedent search",
    version="1.0.0",
    lifespan=lifespan,
)

# CORS middleware (allow Flutter app to connect)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, restrict to your Flutter app's origin
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
from routers.policy_router import router as policy_router
from routers.contract_router import router as contract_router
from routers.precedent_router import router as precedent_router
from routers.lawbot_router import router as lawbot_router
from routers.scanner_router import router as scanner_router
from routers.vault_router import router as vault_router

app.include_router(policy_router)
app.include_router(contract_router)
app.include_router(precedent_router)
app.include_router(lawbot_router)
app.include_router(scanner_router)
app.include_router(vault_router)


@app.get("/")
async def root():
    return {
        "service": "SnapLaw RAG Backend",
        "status": "running",
        "features": [
            "Contract Risk Analysis (RAG)",
            "Policy Management",
            "Legal Precedent Search",
            "LawBot AI Assistant",
        ],
    }


@app.get("/api/health")
async def health_check():
    from models.embeddings import legal_bert
    from services.law_loader import law_knowledge_base
    from services.precedent_service import precedent_service

    return {
        "status": "healthy",
        "embedding_model": "LegalBERT",
        "model_loaded": legal_bert._model is not None,
        "law_knowledge_base_loaded": law_knowledge_base.is_loaded,
        "law_chunks_indexed": law_knowledge_base.chunk_count,
        "law_sources": law_knowledge_base.get_all_sources(),
        "precedent_cases": len(precedent_service.cases),
        "supabase_connected": supabase_client is not None,
        "rag_service_ready": rag_service is not None,
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
