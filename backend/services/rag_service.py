"""
RAG Service
Orchestrates the full RAG pipeline for contract analysis.
Contract text -> clause extraction -> embedding -> law retrieval -> rule-based classification
Fully offline - no external API calls required.
"""

import re
import logging
from typing import List, Dict, Any
from models.embeddings import legal_bert
from models.classifier import analyze_clause, generate_overall_summary
from services.law_loader import law_knowledge_base
from services.policy_service import extract_text_from_file
from services.precedent_service import precedent_service

logger = logging.getLogger(__name__)


class RAGService:
    """Orchestrates the RAG pipeline for contract risk analysis."""

    def __init__(self):
        pass

    def extract_clauses(self, contract_text: str) -> List[Dict[str, str]]:
        """
        Extract individual clauses from a contract document.

        Returns list of dicts with 'text' and 'type' keys.
        """
        clauses = []

        # Pattern 1: Numbered sections (1. ..., 2. ..., etc.)
        numbered = re.split(r"(?=(?:^|\n)\s*\d+[\.\)]\s+)", contract_text)

        # Pattern 2: Section headers
        if len(numbered) <= 2:
            numbered = re.split(
                r"(?=(?:^|\n)\s*(?:Section|Article|Clause|SECTION|ARTICLE|CLAUSE)\s+\d)",
                contract_text,
                flags=re.IGNORECASE,
            )

        # Pattern 3: Paragraph-based fallback
        if len(numbered) <= 2:
            numbered = contract_text.split("\n\n")

        for section in numbered:
            section = section.strip()
            if len(section) < 20:
                continue

            clause_type = self._detect_clause_type(section)
            clauses.append({"text": section, "type": clause_type})

        # If still no clauses found, treat whole text as one clause
        if not clauses:
            clauses.append({
                "text": contract_text[:3000],
                "type": "General",
            })

        return clauses

    def _detect_clause_type(self, text: str) -> str:
        """Detect the type of a legal clause based on keywords."""
        text_lower = text.lower()

        type_keywords = {
            "Termination": ["terminat", "cancel", "end of agreement", "expiry"],
            "Payment": ["payment", "fee", "price", "compensation", "invoice", "salary"],
            "Liability": ["liability", "liable", "indemnif", "damage", "loss"],
            "Confidentiality": ["confidential", "non-disclosure", "nda", "secret", "proprietary"],
            "Jurisdiction": ["jurisdiction", "governing law", "court", "arbitrat", "dispute resolution"],
            "Penalty": ["penalty", "penalt", "fine", "liquidated damage", "breach"],
            "Obligations": ["shall", "must", "obligat", "responsib", "duty", "duties"],
            "Intellectual Property": ["intellectual property", "copyright", "patent", "trademark", "ip rights"],
            "Force Majeure": ["force majeure", "act of god", "unforeseen", "pandemic"],
            "Non-Compete": ["non-compete", "non compete", "competition", "restrictive covenant"],
        }

        for clause_type, keywords in type_keywords.items():
            if any(kw in text_lower for kw in keywords):
                return clause_type

        return "General"

    async def analyze_contract(
        self,
        contract_content: bytes,
        filename: str,
    ) -> Dict[str, Any]:
        """
        Full RAG pipeline for contract analysis using preloaded Pakistani law knowledge base.

        1. Extract text from contract
        2. Split into clauses
        3. For each clause: embed -> retrieve relevant law chunks -> rule-based classify
        4. Generate overall summary
        """
        # Step 1: Extract text
        contract_text = extract_text_from_file(contract_content, filename)
        if not contract_text.strip():
            return {"error": "Could not extract text from document"}

        # Step 2: Extract clauses
        clauses = self.extract_clauses(contract_text)
        logger.info(f"Extracted {len(clauses)} clauses from contract")

        # Step 3: Check that the law knowledge base is loaded
        if not law_knowledge_base.is_loaded:
            return {
                "error": "Pakistani law knowledge base is not loaded. Please restart the backend server.",
            }

        # Step 4: Analyze each clause
        clause_results = []
        for i, clause in enumerate(clauses):
            logger.info(f"Analyzing clause {i + 1}/{len(clauses)}: {clause['type']}")

            # Embed the clause
            clause_embedding = legal_bert.embed_text(clause["text"])

            # Retrieve relevant law chunks from preloaded knowledge base (top 5)
            law_matches = law_knowledge_base.search(clause_embedding, top_k=5)

            # Extract law texts
            retrieved_laws = [match[0].text for match in law_matches]
            similarity_scores = [match[1] for match in law_matches]

            # Rule-based classification (no external API needed)
            classification = analyze_clause(
                clause_text=clause["text"][:1500],
                retrieved_laws=retrieved_laws,
            )

            # Search for similar legal precedents for this clause
            clause_precedents = precedent_service.search_precedents(
                query_text=clause["text"][:1000],
                top_k=3,
            )

            clause_results.append({
                "clause_text": clause["text"][:500],
                "clause_type": classification.get("clause_type", clause["type"]),
                "status": classification.get("status", "Unknown"),
                "risk_level": classification.get("risk_level", "Unknown"),
                "explanation": classification.get("explanation", ""),
                "relevant_policy": classification.get("relevant_policy_excerpt", ""),
                "recommendation": classification.get("recommendation", ""),
                "relevant_law": classification.get("relevant_law", ""),
                "legal_concern": classification.get("legal_concern", ""),
                "suggested_fix": classification.get("suggested_fix", ""),
                "similarity_score": similarity_scores[0] if similarity_scores else 0,
                "precedents": clause_precedents,
            })

        # Step 5: Generate overall summary
        summary = generate_overall_summary(clause_results)

        return {
            "overall_risk": summary["overall_risk"],
            "risk_score": summary["risk_score"],
            "compliance_summary": summary["compliance_summary"],
            "total_clauses": summary["total_clauses"],
            "clauses": clause_results,
            "contract_text_preview": contract_text[:500],
        }
