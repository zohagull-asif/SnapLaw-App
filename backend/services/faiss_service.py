"""
FAISS Index Management Service
Manages per-user FAISS indices for fast similarity search.
"""

import faiss
import numpy as np
import logging
from typing import List, Dict, Tuple, Optional
from collections import defaultdict

logger = logging.getLogger(__name__)


class FAISSService:
    """Manages FAISS indices for vector similarity search."""

    def __init__(self, embedding_dim: int = 768):
        self.embedding_dim = embedding_dim
        # Per-user FAISS indices for policy search
        self._user_indices: Dict[str, faiss.IndexFlatIP] = {}
        # Store chunk metadata alongside indices
        self._user_chunks: Dict[str, List[Dict]] = defaultdict(list)
        # Global precedent index
        self._precedent_index: Optional[faiss.IndexFlatIP] = None
        self._precedent_data: List[Dict] = []

    def build_user_index(self, user_id: str, chunks: List[Dict], embeddings: np.ndarray):
        """
        Build/rebuild a FAISS index for a user's policy chunks.

        Args:
            user_id: The user's ID
            chunks: List of dicts with 'chunk_text', 'chunk_index', 'policy_id'
            embeddings: numpy array of shape (N, 768)
        """
        if len(chunks) == 0:
            logger.warning(f"No chunks to index for user {user_id}")
            return

        # Use Inner Product (cosine similarity since embeddings are normalized)
        index = faiss.IndexFlatIP(self.embedding_dim)
        index.add(embeddings)

        self._user_indices[user_id] = index
        self._user_chunks[user_id] = chunks
        logger.info(f"Built FAISS index for user {user_id} with {len(chunks)} chunks")

    def add_to_user_index(self, user_id: str, chunks: List[Dict], embeddings: np.ndarray):
        """Add new chunks to an existing user's index."""
        if user_id not in self._user_indices:
            self.build_user_index(user_id, chunks, embeddings)
            return

        self._user_indices[user_id].add(embeddings)
        self._user_chunks[user_id].extend(chunks)
        logger.info(f"Added {len(chunks)} chunks to user {user_id}'s index")

    def search_user_policies(
        self, user_id: str, query_embedding: np.ndarray, top_k: int = 5
    ) -> List[Tuple[Dict, float]]:
        """
        Search a user's policy index for similar chunks.

        Returns list of (chunk_metadata, similarity_score) tuples.
        """
        if user_id not in self._user_indices:
            logger.warning(f"No index found for user {user_id}")
            return []

        index = self._user_indices[user_id]
        chunks = self._user_chunks[user_id]

        # Reshape query for FAISS
        query = query_embedding.reshape(1, -1).astype(np.float32)
        top_k = min(top_k, index.ntotal)

        distances, indices = index.search(query, top_k)

        results = []
        for i, (dist, idx) in enumerate(zip(distances[0], indices[0])):
            if idx < len(chunks) and idx >= 0:
                results.append((chunks[idx], float(dist)))

        return results

    def build_precedent_index(self, cases: List[Dict], embeddings: np.ndarray):
        """Build the global legal precedent FAISS index."""
        self._precedent_index = faiss.IndexFlatIP(self.embedding_dim)
        self._precedent_index.add(embeddings)
        self._precedent_data = cases
        logger.info(f"Built precedent FAISS index with {len(cases)} cases")

    def search_precedents(
        self, query_embedding: np.ndarray, top_k: int = 5
    ) -> List[Tuple[Dict, float]]:
        """Search legal precedents by similarity."""
        if self._precedent_index is None:
            logger.warning("Precedent index not built yet")
            return []

        query = query_embedding.reshape(1, -1).astype(np.float32)
        top_k = min(top_k, self._precedent_index.ntotal)

        distances, indices = self._precedent_index.search(query, top_k)

        results = []
        for dist, idx in zip(distances[0], indices[0]):
            if 0 <= idx < len(self._precedent_data):
                results.append((self._precedent_data[idx], float(dist)))

        return results

    def remove_user_index(self, user_id: str):
        """Remove a user's FAISS index."""
        self._user_indices.pop(user_id, None)
        self._user_chunks.pop(user_id, None)
        logger.info(f"Removed FAISS index for user {user_id}")

    def has_user_index(self, user_id: str) -> bool:
        return user_id in self._user_indices


# Global instance
faiss_service = FAISSService()
