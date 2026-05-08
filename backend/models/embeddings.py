"""
Legal Embedding Service
Uses LegalBERT (nlpaueb/legal-bert-base-uncased) via transformers when available.
Falls back to OpenAI text-embedding-3-small when torch/transformers are not installed.
"""

import os
import numpy as np
from typing import List
import logging

logger = logging.getLogger(__name__)

MODEL_NAME = "nlpaueb/legal-bert-base-uncased"

# Check if torch is available
try:
    import torch
    TORCH_AVAILABLE = True
except ImportError:
    TORCH_AVAILABLE = False
    logger.warning("torch not installed — will use OpenAI embeddings fallback")


class LegalBERTEmbeddings:
    """Embedding service: LegalBERT when torch is available, OpenAI otherwise."""

    _instance = None
    _model = None
    _tokenizer = None
    _openai_client = None
    _using_openai = False
    _embedding_dim_value = 768

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
        return cls._instance

    def load_model(self):
        """Load LegalBERT model, or initialise Gemini embeddings as fallback."""
        if self._model is not None or self._openai_client is not None:
            return

        if TORCH_AVAILABLE:
            try:
                logger.info(f"Loading LegalBERT model ({MODEL_NAME})...")
                from transformers import AutoModel, AutoTokenizer
                self._tokenizer = AutoTokenizer.from_pretrained(MODEL_NAME)
                self._model = AutoModel.from_pretrained(MODEL_NAME)
                self._model.eval()
                logger.info("LegalBERT model loaded successfully.")
                return
            except Exception as e:
                logger.warning(f"LegalBERT load failed ({e}), falling back to Gemini embeddings.")

        # Gemini embeddings fallback
        try:
            import google.generativeai as genai
            api_key = os.getenv("GEMINI_API_KEY")
            if not api_key:
                raise ValueError("GEMINI_API_KEY not set")
            genai.configure(api_key=api_key)
            self._openai_client = genai  # reuse slot, holds the genai module
            self._using_openai = True
            self._embedding_dim_value = 3072  # Gemini gemini-embedding-001 dim
            logger.info("Using Gemini gemini-embedding-001 embeddings.")
        except Exception as e:
            raise RuntimeError(f"Failed to load any embedding model: {e}")

    def _mean_pooling(self, model_output, attention_mask):
        token_embeddings = model_output.last_hidden_state
        input_mask_expanded = attention_mask.unsqueeze(-1).expand(token_embeddings.size()).float()
        return torch.sum(token_embeddings * input_mask_expanded, 1) / torch.clamp(
            input_mask_expanded.sum(1), min=1e-9
        )

    def embed_text(self, text: str) -> np.ndarray:
        return self.embed_texts([text])[0]

    def embed_texts(self, texts: List[str]) -> np.ndarray:
        if self._model is None and self._openai_client is None:
            self.load_model()

        if self._using_openai:
            return self._embed_with_openai(texts)

        return self._embed_with_legalbert(texts)

    def _embed_with_openai(self, texts: List[str]) -> np.ndarray:
        """Embed texts using Gemini embedding-001."""
        import google.generativeai as genai
        all_embeddings = []
        for text in texts:
            result = genai.embed_content(
                model="models/gemini-embedding-001",
                content=text,
                task_type="retrieval_document",
            )
            all_embeddings.append(result["embedding"])
        arr = np.array(all_embeddings, dtype=np.float32)
        # L2 normalize
        norms = np.linalg.norm(arr, axis=1, keepdims=True)
        norms = np.where(norms == 0, 1, norms)
        return arr / norms

    def _embed_with_legalbert(self, texts: List[str]) -> np.ndarray:
        all_embeddings = []
        batch_size = 16
        for i in range(0, len(texts), batch_size):
            batch = texts[i:i + batch_size]
            encoded = self._tokenizer(
                batch, padding=True, truncation=True,
                max_length=512, return_tensors="pt",
            )
            with torch.no_grad():
                output = self._model(**encoded)
            embeddings = self._mean_pooling(output, encoded["attention_mask"])
            embeddings = torch.nn.functional.normalize(embeddings, p=2, dim=1)
            all_embeddings.append(embeddings.cpu().numpy())
        return np.vstack(all_embeddings).astype(np.float32)

    @property
    def embedding_dim(self) -> int:
        return self._embedding_dim_value

    @property
    def is_using_openai(self) -> bool:
        return self._using_openai


# Global instance
legal_bert = LegalBERTEmbeddings()
