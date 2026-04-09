"""
Pakistani Law Knowledge Base Loader
Loads Pakistani law files at startup, chunks them, embeds with LegalBERT,
and builds a FAISS index for RAG retrieval.
Supports category-based filtering for domain-specific search.
"""

import os
import re
import logging
import numpy as np
from typing import List, Dict, Tuple, Optional

logger = logging.getLogger(__name__)

# Directory containing Pakistani law text files
LAWS_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), "data", "pakistani_laws")

# Map source filenames to legal categories
FILE_CATEGORY_MAP = {
    "contract_act_1872.txt": "contract",
    "labour_laws.txt": "labour",
    "arbitration_act.txt": "arbitration",
    "consumer_protection_laws.txt": "consumer",
    "corporate_compliance.txt": "corporate",
    "family_laws.txt": "family",
    "criminal_laws.txt": "criminal",
    "property_laws.txt": "property",
}


class LawChunk:
    """Represents a chunk of legal text with metadata."""
    def __init__(self, text: str, source_file: str, section: str = "", category: str = "general"):
        self.text = text
        self.source_file = source_file
        self.section = section
        self.category = category

    def __repr__(self):
        return f"LawChunk(source={self.source_file}, category={self.category}, section={self.section[:50]})"


class PakistaniLawLoader:
    """Loads and manages the Pakistani law knowledge base with category support."""

    _instance = None
    _chunks: List[LawChunk] = []
    _embeddings: np.ndarray = None
    _faiss_index = None
    _loaded = False
    _category_indices: Dict[str, List[int]] = {}  # category → list of chunk indices

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance._chunks = []
            cls._instance._embeddings = None
            cls._instance._faiss_index = None
            cls._instance._loaded = False
            cls._instance._category_indices = {}
        return cls._instance

    @property
    def is_loaded(self) -> bool:
        return self._loaded

    @property
    def chunk_count(self) -> int:
        return len(self._chunks)

    def load_and_index(self):
        """Load all law files, chunk them, embed, and build FAISS index."""
        if self._loaded:
            logger.info("Pakistani law knowledge base already loaded.")
            return

        logger.info("Loading Pakistani law knowledge base...")

        # Step 1: Load all law files
        raw_texts = self._load_law_files()
        if not raw_texts:
            logger.warning("No law files found. Knowledge base is empty.")
            return

        # Step 2: Chunk the texts with category metadata
        self._chunks = []
        self._category_indices = {}
        for source_file, text in raw_texts.items():
            category = FILE_CATEGORY_MAP.get(source_file, "general")
            chunks = self._chunk_legal_text(text, source_file, category)
            # Track indices per category
            for chunk in chunks:
                idx = len(self._chunks)
                self._chunks.append(chunk)
                self._category_indices.setdefault(category, []).append(idx)

        logger.info(f"Created {len(self._chunks)} law chunks from {len(raw_texts)} files")
        cat_summary = {cat: len(idxs) for cat, idxs in self._category_indices.items()}
        logger.info(f"Category distribution: {cat_summary}")

        # Step 3: Embed all chunks
        from models.embeddings import legal_bert
        chunk_texts = [c.text for c in self._chunks]
        self._embeddings = legal_bert.embed_texts(chunk_texts)
        logger.info(f"Generated embeddings: shape {self._embeddings.shape}")

        # Step 4: Build FAISS index
        import faiss
        dim = self._embeddings.shape[1]
        self._faiss_index = faiss.IndexFlatIP(dim)  # Inner product for cosine similarity
        self._faiss_index.add(self._embeddings)
        logger.info(f"FAISS law index built with {self._faiss_index.ntotal} vectors")

        self._loaded = True
        logger.info("Pakistani law knowledge base ready!")

    def _load_law_files(self) -> Dict[str, str]:
        """Load all .txt files from the pakistani_laws directory."""
        texts = {}
        if not os.path.exists(LAWS_DIR):
            logger.error(f"Laws directory not found: {LAWS_DIR}")
            return texts

        for filename in sorted(os.listdir(LAWS_DIR)):
            if filename.endswith(".txt"):
                filepath = os.path.join(LAWS_DIR, filename)
                with open(filepath, "r", encoding="utf-8") as f:
                    content = f.read().strip()
                    if content:
                        texts[filename] = content
                        logger.info(f"Loaded: {filename} ({len(content)} chars)")

        return texts

    def _chunk_legal_text(self, text: str, source_file: str, category: str) -> List[LawChunk]:
        """Split legal text into semantic chunks of 200-500 words."""
        chunks = []

        # Split by section headers (SECTION XX: or numbered sections)
        section_pattern = r'(?=(?:SECTION\s+\d+|Section\s+\d+|[A-Z][A-Z\s]+ACT|[A-Z][A-Z\s]+ORDINANCE|KEY\s+\w+))'
        sections = re.split(section_pattern, text)

        for section in sections:
            section = section.strip()
            if not section or len(section) < 30:
                continue

            # Extract section header
            header_match = re.match(r'^(SECTION\s+\d+[^:]*:|[A-Z][A-Z\s]+(?:ACT|ORDINANCE|LAWS|PRINCIPLES)[^\n]*)', section)
            header = header_match.group(0).strip() if header_match else ""

            words = section.split()
            if len(words) <= 500:
                # Section fits in one chunk
                chunks.append(LawChunk(
                    text=section, source_file=source_file,
                    section=header, category=category,
                ))
            else:
                # Split large sections into ~300-word chunks with overlap
                chunk_size = 300
                overlap = 50
                for i in range(0, len(words), chunk_size - overlap):
                    chunk_words = words[i:i + chunk_size]
                    if len(chunk_words) < 30:
                        continue
                    chunk_text = " ".join(chunk_words)
                    chunks.append(LawChunk(
                        text=chunk_text, source_file=source_file,
                        section=header, category=category,
                    ))

        return chunks

    def search(self, query_embedding: np.ndarray, top_k: int = 5,
               category: Optional[str] = None) -> List[Tuple[LawChunk, float]]:
        """
        Search the law knowledge base for relevant chunks.

        Args:
            query_embedding: Query vector from LegalBERT
            top_k: Number of results to return
            category: If provided, filter results to this category only
        """
        if not self._loaded or self._faiss_index is None:
            logger.warning("Law knowledge base not loaded. Returning empty results.")
            return []

        # Ensure query is 2D
        if query_embedding.ndim == 1:
            query_embedding = query_embedding.reshape(1, -1)

        if category and category in self._category_indices:
            # STRICT category-filtered search: only return chunks from the target category
            # Search the full index then filter — never fall back to unfiltered
            search_k = min(top_k * 10, self._faiss_index.ntotal)
            scores, indices = self._faiss_index.search(query_embedding, search_k)

            allowed_indices = set(self._category_indices[category])
            results = []
            for score, idx in zip(scores[0], indices[0]):
                if idx >= 0 and idx < len(self._chunks) and idx in allowed_indices:
                    results.append((self._chunks[idx], float(score)))
                    if len(results) >= top_k:
                        break

            logger.debug(f"Category '{category}' returned {len(results)} results (strict filter)")
            return results
        else:
            return self._unfiltered_search(query_embedding, top_k)

    def _unfiltered_search(self, query_embedding: np.ndarray, top_k: int) -> List[Tuple[LawChunk, float]]:
        """Standard FAISS search without category filtering."""
        scores, indices = self._faiss_index.search(query_embedding, top_k)
        results = []
        for score, idx in zip(scores[0], indices[0]):
            if idx >= 0 and idx < len(self._chunks):
                results.append((self._chunks[idx], float(score)))
        return results

    def search_text(self, query_text: str, top_k: int = 5,
                    category: Optional[str] = None) -> List[Tuple[LawChunk, float]]:
        """Search using text query (embeds the query first)."""
        from models.embeddings import legal_bert
        query_emb = legal_bert.embed_text(query_text)
        return self.search(query_emb, top_k, category=category)

    def get_all_sources(self) -> List[str]:
        """Get list of all loaded law source files."""
        return list(set(c.source_file for c in self._chunks))

    def get_categories(self) -> List[str]:
        """Get list of all available categories."""
        return list(self._category_indices.keys())


# Global singleton
law_knowledge_base = PakistaniLawLoader()
