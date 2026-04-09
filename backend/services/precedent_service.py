"""
Legal Precedent Search Service — Hybrid Retrieval
Combines FAISS semantic search with keyword-aware re-ranking and domain filtering.
Achieves high relevance by:
  1. Rich embedding text (title + summary + decision + keywords)
  2. Keyword extraction from queries
  3. Domain-specific category boosting
  4. Hybrid scoring: FAISS similarity + keyword match bonus
  5. Explainable results with reason field
Fully offline — no external API calls required.
"""

import json
import logging
import os
import re
import numpy as np
from typing import List, Dict, Any, Optional, Set, Tuple
from models.embeddings import legal_bert
from services.faiss_service import faiss_service

logger = logging.getLogger(__name__)

# ─── Keyword & Domain Configuration ───

LEGAL_KEYWORD_MAP = {
    "arbitration": ["arbitration", "arbitrator", "arbitral", "arbitration clause", "arbitration award", "arbitration agreement"],
    "jurisdiction": ["jurisdiction", "forum", "court jurisdiction", "exclusive jurisdiction", "governing law"],
    "penalty": ["penalty", "penalties", "liquidated damages", "forfeiture", "punitive", "fine"],
    "liability": ["liability", "liable", "limitation of liability", "unlimited liability", "vicarious liability", "negligence"],
    "indemnification": ["indemnification", "indemnity", "indemnify", "indemnity clause", "hold harmless"],
    "labour": ["labour", "labor", "worker", "employee", "employment", "termination", "wages", "overtime", "retrenchment", "trade union"],
    "contract": ["breach of contract", "contract", "agreement", "contractual", "void contract", "frustration"],
    "dispute resolution": ["dispute resolution", "dispute", "mediation", "conciliation", "settlement"],
}

# Maps detected domains to preferred case categories
DOMAIN_CATEGORY_MAP = {
    "arbitration": ["Arbitration"],
    "jurisdiction": ["Jurisdiction"],
    "penalty": ["Penalty"],
    "liability": ["Liability"],
    "indemnification": ["Indemnification"],
    "labour": ["Labour Law"],
    "contract": ["Contract Dispute"],
    "dispute resolution": ["Arbitration", "Jurisdiction"],
}

# Keyword boost per match
KEYWORD_BOOST = 0.08
# Category match boost
CATEGORY_BOOST = 0.12
# Maximum total boost
MAX_BOOST = 0.40


def extract_query_keywords(query: str) -> Tuple[Set[str], Set[str]]:
    """
    Extract legal keywords and detected domains from a query.

    Returns:
        (matched_keywords, detected_domains)
    """
    query_lower = query.lower()
    matched_keywords = set()
    detected_domains = set()

    for domain, keywords in LEGAL_KEYWORD_MAP.items():
        for keyword in keywords:
            if keyword in query_lower:
                matched_keywords.add(keyword)
                detected_domains.add(domain)

    return matched_keywords, detected_domains


def generate_reason(query: str, case_data: Dict, matched_keywords: Set[str], keyword_overlap: List[str]) -> str:
    """
    Generate an explainable reason for why this case was matched.
    """
    case_title = case_data.get("case_title", case_data.get("title", ""))
    category = case_data.get("category", "")

    parts = []

    if keyword_overlap:
        overlap_str = ", ".join(keyword_overlap[:4])
        parts.append(f"shares legal topics: {overlap_str}")

    if category:
        parts.append(f"falls under {category}")

    case_keywords = case_data.get("keywords", [])
    # Find thematic connection
    for kw in matched_keywords:
        for ckw in case_keywords:
            if kw in ckw.lower() or ckw.lower() in kw:
                parts.append(f"directly addresses '{ckw}'")
                break
        if len(parts) >= 3:
            break

    if parts:
        reason = f"This case is relevant because it {', and '.join(parts[:3])}."
    else:
        reason = f"This case from {category} involves similar legal principles to your query."

    return reason


class PrecedentService:
    """Manages legal precedent embedding and hybrid search."""

    def __init__(self):
        self.cases: List[Dict] = []
        self._loaded = False

    def load_seed_data(self, data_path: str = None):
        """Load and index the legal cases dataset."""
        if self._loaded:
            return

        if data_path is None:
            data_path = os.path.join(
                os.path.dirname(os.path.dirname(__file__)), "data", "legal_cases.json"
            )

        if not os.path.exists(data_path):
            data_path = os.path.join(
                os.path.dirname(os.path.dirname(__file__)), "data", "seed_cases.json"
            )

        logger.info(f"Loading legal cases from {data_path}...")
        with open(data_path, "r", encoding="utf-8") as f:
            self.cases = json.load(f)

        logger.info(f"Loaded {len(self.cases)} legal cases")

        # TASK 1: Improved embedding text — title + summary + decision + keywords
        search_texts = []
        for case in self.cases:
            keywords_str = " ".join(case.get("keywords", []))
            case_text = (
                f"{case.get('case_title', case.get('title', ''))}. "
                f"{case.get('summary', '')} "
                f"{case.get('decision', case.get('judgment', ''))} "
                f"{keywords_str}"
            )
            search_texts.append(case_text)

        # Embed all cases using LegalBERT
        logger.info("Embedding legal cases with LegalBERT...")
        embeddings = legal_bert.embed_texts(search_texts)

        # Build FAISS index
        faiss_service.build_precedent_index(self.cases, embeddings)

        self._loaded = True
        logger.info(f"Legal precedent index ready with {len(self.cases)} cases")

        # Log category distribution
        categories = {}
        for c in self.cases:
            cat = c.get("category", "Unknown")
            categories[cat] = categories.get(cat, 0) + 1
        logger.info(f"Category distribution: {categories}")

    def _hybrid_rerank(
        self,
        raw_results: List[Tuple[Dict, float]],
        query_keywords: Set[str],
        query_domains: Set[str],
    ) -> List[Tuple[Dict, float, List[str], str]]:
        """
        Re-rank FAISS results using keyword matching and domain filtering.

        Returns list of (case_data, adjusted_score, keyword_overlap, reason)
        """
        reranked = []

        for case_data, faiss_score in raw_results:
            case_keywords = [kw.lower() for kw in case_data.get("keywords", [])]
            case_category = case_data.get("category", "").lower()

            boost = 0.0
            keyword_overlap = []

            # TASK 4: Keyword match boost
            for qk in query_keywords:
                for ck in case_keywords:
                    if qk in ck or ck in qk:
                        boost += KEYWORD_BOOST
                        keyword_overlap.append(ck)
                        break

            # TASK 5: Domain/category boost
            for domain in query_domains:
                preferred_categories = DOMAIN_CATEGORY_MAP.get(domain, [])
                for pcat in preferred_categories:
                    if pcat.lower() == case_category:
                        boost += CATEGORY_BOOST
                        break

            # Cap the boost
            boost = min(boost, MAX_BOOST)
            adjusted_score = faiss_score + boost

            # Generate reason
            reason = generate_reason("", case_data, query_keywords, keyword_overlap)

            reranked.append((case_data, adjusted_score, keyword_overlap, reason))

        # Sort by adjusted score descending
        reranked.sort(key=lambda x: x[1], reverse=True)

        return reranked

    def search_precedents(
        self, query_text: str, top_k: int = 3
    ) -> List[Dict[str, Any]]:
        """
        Hybrid search for similar legal precedents given a contract clause.

        Pipeline:
          Clause → Keyword Extraction → LegalBERT Embedding → FAISS (top 10)
          → Keyword Boost + Domain Filter → Re-rank → Return top_k with reasons

        Args:
            query_text: Contract clause text or legal query
            top_k: Number of results to return

        Returns:
            List of cases with similarity scores and reasons
        """
        if not self._loaded:
            self.load_seed_data()

        # TASK 2: Extract keywords from query
        query_keywords, query_domains = extract_query_keywords(query_text)
        logger.debug(f"Query keywords: {query_keywords}, domains: {query_domains}")

        # TASK 6: Increased search depth — fetch 10 from FAISS, return top_k after reranking
        faiss_top_k = max(10, top_k * 3)

        # Embed the query using LegalBERT
        query_embedding = legal_bert.embed_text(query_text)

        # FAISS similarity search
        raw_results = faiss_service.search_precedents(query_embedding, top_k=faiss_top_k)

        # TASK 3 & 4: Hybrid re-ranking with keyword boost + domain filtering
        reranked = self._hybrid_rerank(raw_results, query_keywords, query_domains)

        # Return top_k results with reason field (TASK 8 & 9)
        results = []
        for case_data, score, keyword_overlap, reason in reranked[:top_k]:
            results.append({
                "case_title": case_data.get("case_title", case_data.get("title", "")),
                "court": case_data.get("court", ""),
                "year": case_data.get("year", ""),
                "summary": case_data.get("summary", ""),
                "decision": case_data.get("decision", case_data.get("judgment", "")),
                "keywords": case_data.get("keywords", []),
                "category": case_data.get("category", ""),
                "case_number": case_data.get("case_number", ""),
                "similarity_score": min(round(float(score) * 100, 1), 99.9),
                "reason": reason,
            })

        return results

    def search(
        self, query: str, top_k: int = 5, court_filter: Optional[str] = None, year_filter: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        """
        Search for relevant legal precedents with optional filters.
        Used by the Legal Precedent Finder screen.
        Uses hybrid search with keyword boosting and domain filtering.
        """
        if not self._loaded:
            self.load_seed_data()

        # Extract keywords and domains
        query_keywords, query_domains = extract_query_keywords(query)

        # Embed the query
        query_embedding = legal_bert.embed_text(query)

        # Search FAISS with increased depth
        search_k = max(15, top_k * 3)
        raw_results = faiss_service.search_precedents(query_embedding, top_k=search_k)

        # Hybrid re-ranking
        reranked = self._hybrid_rerank(raw_results, query_keywords, query_domains)

        # Apply filters and format results
        results = []
        for case_data, score, keyword_overlap, reason in reranked:
            # Apply court filter
            if court_filter and court_filter != "All Courts":
                if court_filter.lower() not in case_data.get("court", "").lower():
                    continue

            # Apply year filter
            if year_filter and year_filter != "All Years":
                if str(case_data.get("year", "")) != str(year_filter):
                    continue

            results.append({
                "id": case_data.get("id", ""),
                "title": case_data.get("case_title", case_data.get("title", "")),
                "case_number": case_data.get("case_number", ""),
                "court": case_data.get("court", ""),
                "year": case_data.get("year", ""),
                "summary": case_data.get("summary", ""),
                "judgment": case_data.get("decision", case_data.get("judgment", "")),
                "decision": case_data.get("decision", case_data.get("judgment", "")),
                "keywords": case_data.get("keywords", []),
                "category": case_data.get("category", ""),
                "relevance_score": min(round(float(score) * 100, 1), 99.9),
                "reason": reason,
            })

            if len(results) >= top_k:
                break

        return results


# Global instance
precedent_service = PrecedentService()
