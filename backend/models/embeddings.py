"""
Legal Embedding Service
Uses LegalBERT (nlpaueb/legal-bert-base-uncased) via transformers directly.
No external API dependencies — runs fully offline.
"""

import numpy as np
from typing import List
import logging
import torch

logger = logging.getLogger(__name__)

MODEL_NAME = "nlpaueb/legal-bert-base-uncased"


class LegalBERTEmbeddings:
    """Singleton service for LegalBERT embeddings using transformers directly."""

    _instance = None
    _model = None
    _tokenizer = None
    _embedding_dim_value = 768

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
        return cls._instance

    def load_model(self):
        """Load LegalBERT model and tokenizer."""
        if self._model is not None:
            return

        logger.info(f"Loading LegalBERT model ({MODEL_NAME})...")
        from transformers import AutoModel, AutoTokenizer

        self._tokenizer = AutoTokenizer.from_pretrained(MODEL_NAME)
        self._model = AutoModel.from_pretrained(MODEL_NAME)
        self._model.eval()
        logger.info("LegalBERT model loaded successfully (offline, no API needed).")

    def _mean_pooling(self, model_output, attention_mask):
        """Mean pooling over token embeddings, masked by attention_mask."""
        token_embeddings = model_output.last_hidden_state
        input_mask_expanded = attention_mask.unsqueeze(-1).expand(token_embeddings.size()).float()
        return torch.sum(token_embeddings * input_mask_expanded, 1) / torch.clamp(
            input_mask_expanded.sum(1), min=1e-9
        )

    def embed_text(self, text: str) -> np.ndarray:
        """Embed a single text string. Returns numpy array of shape (768,)."""
        return self.embed_texts([text])[0]

    def embed_texts(self, texts: List[str]) -> np.ndarray:
        """Embed multiple texts. Returns (N, 768) numpy array, L2-normalized."""
        if self._model is None:
            self.load_model()

        all_embeddings = []
        batch_size = 16

        for i in range(0, len(texts), batch_size):
            batch = texts[i:i + batch_size]
            # Truncate to 512 tokens max
            encoded = self._tokenizer(
                batch,
                padding=True,
                truncation=True,
                max_length=512,
                return_tensors="pt",
            )

            with torch.no_grad():
                output = self._model(**encoded)

            embeddings = self._mean_pooling(output, encoded["attention_mask"])
            # L2 normalize
            embeddings = torch.nn.functional.normalize(embeddings, p=2, dim=1)
            all_embeddings.append(embeddings.cpu().numpy())

            if (i // batch_size) % 5 == 0 and i > 0:
                logger.info(f"Embedded {i + len(batch)}/{len(texts)} texts...")

        result = np.vstack(all_embeddings).astype(np.float32)
        return result

    @property
    def embedding_dim(self) -> int:
        return self._embedding_dim_value

    @property
    def is_using_openai(self) -> bool:
        return False


# Global instance
legal_bert = LegalBERTEmbeddings()
