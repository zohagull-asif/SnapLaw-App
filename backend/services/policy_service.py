"""
Policy Service
Handles policy document upload, text extraction, chunking, and embedding storage.
"""

import re
import uuid
import logging
import pdfplumber
from io import BytesIO
from typing import List, Dict, Optional
from models.embeddings import legal_bert
from services.faiss_service import faiss_service

logger = logging.getLogger(__name__)


def extract_text_from_file(file_content: bytes, filename: str) -> str:
    """Extract text from uploaded file (PDF or TXT)."""
    ext = filename.lower().rsplit(".", 1)[-1] if "." in filename else ""

    if ext == "txt":
        return file_content.decode("utf-8", errors="ignore")
    elif ext == "pdf":
        return _extract_from_pdf(file_content)
    elif ext in ("doc", "docx"):
        # For simplicity, treat as plain text. In production, use python-docx
        return file_content.decode("utf-8", errors="ignore")
    else:
        raise ValueError(f"Unsupported file type: {ext}. Use PDF or TXT.")


def _extract_from_pdf(content: bytes) -> str:
    """Extract text from PDF using pdfplumber."""
    text_parts = []
    with pdfplumber.open(BytesIO(content)) as pdf:
        for page in pdf.pages:
            page_text = page.extract_text()
            if page_text:
                text_parts.append(page_text)
    return "\n\n".join(text_parts)


def chunk_text(text: str, chunk_size: int = 500, overlap: int = 50) -> List[str]:
    """
    Split text into overlapping chunks for embedding.

    Strategy:
    1. First try splitting by section headers / numbered clauses
    2. Fall back to paragraph splitting
    3. Final fallback: fixed-size character chunks with overlap
    """
    # Try to split by legal section patterns (e.g., "1.", "Section 1", "Article I")
    section_pattern = r"(?=(?:^|\n)\s*(?:\d+[\.\)]\s|Section\s+\d|Article\s+[IVXLCDM\d]|CLAUSE\s+\d))"
    sections = re.split(section_pattern, text, flags=re.IGNORECASE)
    sections = [s.strip() for s in sections if s.strip()]

    # If we got meaningful sections, use them
    if len(sections) > 1 and all(len(s) < chunk_size * 3 for s in sections):
        chunks = []
        for section in sections:
            if len(section) <= chunk_size:
                chunks.append(section)
            else:
                # Split long sections into sub-chunks
                chunks.extend(_fixed_size_chunks(section, chunk_size, overlap))
        return chunks

    # Try paragraph splitting
    paragraphs = text.split("\n\n")
    paragraphs = [p.strip() for p in paragraphs if p.strip()]

    if len(paragraphs) > 1:
        chunks = []
        current_chunk = ""
        for para in paragraphs:
            if len(current_chunk) + len(para) <= chunk_size:
                current_chunk += "\n\n" + para if current_chunk else para
            else:
                if current_chunk:
                    chunks.append(current_chunk)
                current_chunk = para
        if current_chunk:
            chunks.append(current_chunk)
        return chunks

    # Fallback: fixed-size chunks
    return _fixed_size_chunks(text, chunk_size, overlap)


def _fixed_size_chunks(text: str, chunk_size: int, overlap: int) -> List[str]:
    """Split text into fixed-size chunks with overlap."""
    chunks = []
    start = 0
    while start < len(text):
        end = start + chunk_size
        chunk = text[start:end]
        if chunk.strip():
            chunks.append(chunk.strip())
        start = end - overlap
    return chunks


async def process_policy_upload(
    user_id: str,
    file_content: bytes,
    filename: str,
    policy_name: str,
    supabase_client,
) -> Dict:
    """
    Full pipeline: extract text -> chunk -> embed -> store in Supabase + FAISS.

    Returns dict with policy_id and chunk count.
    """
    # 1. Extract text
    logger.info(f"Extracting text from {filename}...")
    text = extract_text_from_file(file_content, filename)
    if not text.strip():
        raise ValueError("Could not extract any text from the document.")

    # 2. Chunk the text
    logger.info("Chunking text...")
    chunks = chunk_text(text)
    logger.info(f"Created {len(chunks)} chunks")

    # 3. Generate embeddings
    logger.info("Generating LegalBERT embeddings...")
    embeddings = legal_bert.embed_texts(chunks)

    # 4. Store policy in Supabase
    policy_id = str(uuid.uuid4())

    # Insert policy record
    supabase_client.table("company_policies").insert({
        "id": policy_id,
        "user_id": user_id,
        "policy_name": policy_name,
        "original_text": text[:10000],  # Limit stored text
    }).execute()

    # Insert chunks with embeddings
    chunk_records = []
    chunk_metadata = []
    for i, (chunk_text_val, embedding) in enumerate(zip(chunks, embeddings)):
        chunk_id = str(uuid.uuid4())
        chunk_records.append({
            "id": chunk_id,
            "policy_id": policy_id,
            "user_id": user_id,
            "chunk_text": chunk_text_val,
            "chunk_index": i,
            "embedding": embedding.tolist(),
        })
        chunk_metadata.append({
            "chunk_id": chunk_id,
            "chunk_text": chunk_text_val,
            "chunk_index": i,
            "policy_id": policy_id,
            "policy_name": policy_name,
        })

    # Batch insert chunks
    for record in chunk_records:
        supabase_client.table("policy_chunks").insert(record).execute()

    # 5. Update FAISS index
    faiss_service.add_to_user_index(user_id, chunk_metadata, embeddings)

    logger.info(f"Policy '{policy_name}' processed: {len(chunks)} chunks stored")

    return {
        "policy_id": policy_id,
        "policy_name": policy_name,
        "chunk_count": len(chunks),
        "text_length": len(text),
    }


async def load_user_policies_into_faiss(user_id: str, supabase_client):
    """Load a user's existing policy chunks from Supabase into FAISS."""
    import numpy as np

    response = (
        supabase_client.table("policy_chunks")
        .select("id, chunk_text, chunk_index, policy_id, embedding")
        .eq("user_id", user_id)
        .execute()
    )

    if not response.data:
        logger.info(f"No existing policies for user {user_id}")
        return

    chunks = []
    embeddings_list = []
    for row in response.data:
        chunks.append({
            "chunk_id": row["id"],
            "chunk_text": row["chunk_text"],
            "chunk_index": row["chunk_index"],
            "policy_id": row["policy_id"],
        })
        embeddings_list.append(row["embedding"])

    embeddings = np.array(embeddings_list, dtype=np.float32)
    faiss_service.build_user_index(user_id, chunks, embeddings)
    logger.info(f"Loaded {len(chunks)} chunks into FAISS for user {user_id}")
