"""
Legal Clause Classifier
Rule-based classification of contract clauses against Pakistani law.
No external API dependencies - works fully offline.
"""

import re
import logging
from typing import List, Dict, Any

logger = logging.getLogger(__name__)


# ============================================================
# Rule definitions: pattern -> risk metadata
# Each rule has: keywords (list of patterns to match),
# risk_level, category, legal_concern, suggested_fix, relevant_law
# ============================================================

RISK_RULES = [
    # --- LIABILITY ---
    {
        "keywords": [r"unlimited liability", r"bear all liability", r"unlimited.*liab"],
        "risk_level": "High",
        "category": "Liability",
        "status": "Violation",
        "legal_concern": "Unlimited liability creates excessive and disproportionate financial exposure for one party, which may be deemed unconscionable.",
        "suggested_fix": "Limit liability to the total contract value or a reasonable multiple thereof. Example: 'Liability shall not exceed the total fees paid under this agreement.'",
        "relevant_law": "Section 73-74, Contract Act 1872 - Compensation for breach must be reasonable and proportionate.",
    },
    {
        "keywords": [r"no liability whatsoever", r"bear no liability", r"zero liability", r"shall not be liable under any circumstances"],
        "risk_level": "High",
        "category": "Liability",
        "status": "Violation",
        "legal_concern": "Complete exclusion of liability for one party is one-sided and may be unenforceable, especially for negligence causing injury.",
        "suggested_fix": "Both parties should share reasonable liability. Example: 'Each party shall be liable for damages caused by its negligence or breach.'",
        "relevant_law": "Section 23, Contract Act 1872 - Agreements with unlawful consideration or object are void.",
    },
    {
        "keywords": [r"consequential.*damages", r"punitive damages", r"incidental.*damages"],
        "risk_level": "Medium",
        "category": "Liability",
        "status": "Risky",
        "legal_concern": "Broad liability for consequential and punitive damages without cap can lead to disproportionate claims.",
        "suggested_fix": "Exclude consequential and punitive damages or cap total liability. Example: 'Neither party shall be liable for indirect, consequential, or punitive damages.'",
        "relevant_law": "Section 73, Contract Act 1872 - Only direct and foreseeable losses are compensable.",
    },

    # --- PAYMENT ---
    {
        "keywords": [r"120\s*days", r"150\s*days", r"180\s*days"],
        "risk_level": "High",
        "category": "Payment",
        "status": "Violation",
        "legal_concern": "Payment terms exceeding 90 days are unreasonable and create cash flow risk for the service provider.",
        "suggested_fix": "Reduce payment terms to 30-60 days. Example: 'Payment shall be made within 30 days of invoice submission.'",
        "relevant_law": "Company policy and standard commercial practice - Payment should not exceed 90 days from invoice date.",
    },
    {
        "keywords": [r"withhold payment indefinitely", r"withhold.*payment.*without.*reason", r"right to withhold payment"],
        "risk_level": "High",
        "category": "Payment",
        "status": "Violation",
        "legal_concern": "Indefinite withholding of payment without objective criteria is unfair and may constitute unjust enrichment.",
        "suggested_fix": "Define clear, objective criteria for payment disputes with a resolution timeline. Example: 'Disputed amounts must be notified within 14 days with specific reasons.'",
        "relevant_law": "Section 73, Contract Act 1872 - Work performed entitles compensation; withholding without cause is unjust enrichment.",
    },
    {
        "keywords": [r"no interest.*late", r"no interest shall accrue"],
        "risk_level": "Medium",
        "category": "Payment",
        "status": "Risky",
        "legal_concern": "Absence of late payment interest removes incentive for timely payment and disadvantages the service provider.",
        "suggested_fix": "Include a reasonable late payment interest clause. Example: 'Late payments shall accrue interest at SBP base rate + 2% per annum.'",
        "relevant_law": "State Bank of Pakistan regulations and commercial best practices.",
    },

    # --- TERMINATION ---
    {
        "keywords": [r"terminat.*immediately.*without.*notice", r"without any notice period", r"no notice period"],
        "risk_level": "High",
        "category": "Termination",
        "status": "Violation",
        "legal_concern": "Termination without notice period denies the other party reasonable time to prepare and find alternatives.",
        "suggested_fix": "Include a minimum 30-day notice period for termination. Example: 'Either party may terminate with 30 days written notice.'",
        "relevant_law": "Section 10.1, Termination Policy - Minimum 30 days notice required. Also Industrial and Commercial Employment (Standing Orders) Ordinance 1968.",
    },
    {
        "keywords": [r"forfeit all pending payments", r"forfeit.*payment", r"not.*entitled.*compensation.*termination"],
        "risk_level": "High",
        "category": "Termination",
        "status": "Violation",
        "legal_concern": "Forfeiture of earned payments upon termination is unfair and may be void as an unreasonable penalty.",
        "suggested_fix": "All work completed before termination should be compensated. Example: 'Upon termination, the Service Provider shall be paid for all work completed up to the termination date.'",
        "relevant_law": "Section 74, Contract Act 1872 - Penalties must be reasonable. Section 10.2 - Reasonable compensation to non-terminating party required.",
    },

    # --- NON-COMPETE ---
    {
        "keywords": [r"10 years", r"15 years", r"20 years"],
        "risk_level": "High",
        "category": "Non-Compete",
        "status": "Violation",
        "legal_concern": "Non-compete period exceeding 2 years is considered unreasonable restraint of trade and is void under Pakistani law.",
        "suggested_fix": "Reduce non-compete to 1-2 years with limited geographic scope. Example: 'The Service Provider shall not compete in the same market segment within the city of Lahore for 1 year.'",
        "relevant_law": "Section 27, Contract Act 1872 - All agreements in restraint of trade are void.",
    },
    {
        "keywords": [r"not.*engage.*any.*business", r"not.*provide.*services.*any.*client", r"anywhere in pakistan.*non.compete"],
        "risk_level": "High",
        "category": "Non-Compete",
        "status": "Violation",
        "legal_concern": "Blanket restriction preventing all business activity across the entire country is an unreasonable restraint of trade.",
        "suggested_fix": "Limit non-compete to specific competitors, geographic area, and reasonable duration. Example: 'Shall not provide similar services to direct competitors within Lahore for 12 months.'",
        "relevant_law": "Section 27, Contract Act 1872 - Agreements in restraint of trade are void unless within recognized exceptions (e.g., sale of goodwill).",
    },

    # --- PENALTY ---
    {
        "keywords": [r"penalty.*million", r"penalty.*crore", r"50,000,000", r"PKR\s*50"],
        "risk_level": "High",
        "category": "Penalty",
        "status": "Violation",
        "legal_concern": "Disproportionate penalty amount bears no reasonable relation to actual damages and is unenforceable.",
        "suggested_fix": "Set penalty proportional to actual losses or contract value. Example: 'Penalty shall not exceed 10% of the total contract value.'",
        "relevant_law": "Section 74, Contract Act 1872 - When penalty is named, only reasonable compensation (not exceeding penalty amount) can be awarded.",
    },
    {
        "keywords": [r"regardless of.*nature.*breach", r"regardless of.*extent.*breach", r"any breach.*penalty"],
        "risk_level": "High",
        "category": "Penalty",
        "status": "Violation",
        "legal_concern": "Imposing the same penalty regardless of breach severity is disproportionate and unconscionable.",
        "suggested_fix": "Penalties should be proportionate to the severity and type of breach. Example: 'Penalties shall be determined based on the nature and extent of the breach.'",
        "relevant_law": "Section 74, Contract Act 1872 - Compensation must be reasonable, not exceeding the stated penalty.",
    },

    # --- INTELLECTUAL PROPERTY ---
    {
        "keywords": [r"pre-existing ip.*become.*property", r"pre-existing.*tools.*property of.*company", r"all.*ip.*including.*pre-existing"],
        "risk_level": "High",
        "category": "Intellectual Property",
        "status": "Violation",
        "legal_concern": "Claiming ownership of pre-existing IP and tools is unfair and may constitute unjust enrichment.",
        "suggested_fix": "Distinguish between pre-existing IP (remains with creator) and new IP (assigned to client). Example: 'IP created specifically for this project shall belong to the Company. Pre-existing IP remains with the Service Provider under a perpetual license.'",
        "relevant_law": "Copyright Ordinance 1962 and Section 4.1 IP Policy - IP rights must be clearly defined. Pre-existing IP should be licensed, not transferred.",
    },
    {
        "keywords": [r"without any additional compensation.*ip", r"ip.*without.*compensation"],
        "risk_level": "Medium",
        "category": "Intellectual Property",
        "status": "Risky",
        "legal_concern": "Transfer of IP without fair compensation may be challenged as lacking adequate consideration.",
        "suggested_fix": "Include IP transfer compensation or ensure the service fee covers IP assignment. Example: 'The service fees include compensation for assignment of project-specific IP.'",
        "relevant_law": "Section 23-25, Contract Act 1872 - Agreements require lawful consideration.",
    },

    # --- CONFIDENTIALITY ---
    {
        "keywords": [r"unlimited duration.*confidential", r"confidentiality.*unlimited", r"indefinite.*confidential"],
        "risk_level": "Medium",
        "category": "Confidentiality",
        "status": "Risky",
        "legal_concern": "Perpetual confidentiality obligations are burdensome and difficult to enforce long-term.",
        "suggested_fix": "Limit confidentiality to 3-5 years after termination, except for trade secrets. Example: 'Confidentiality obligations shall survive for 5 years after termination.'",
        "relevant_law": "Section 4.4, Confidentiality Policy - NDAs should specify duration, scope, and type of confidential information.",
    },
    {
        "keywords": [r"no obligation.*confidentiality.*company", r"one-sided.*confidential", r"no.*confidentiality.*from.*company"],
        "risk_level": "High",
        "category": "Confidentiality",
        "status": "Violation",
        "legal_concern": "One-sided confidentiality obligations are unfair and leave one party's proprietary information unprotected.",
        "suggested_fix": "Make confidentiality obligations mutual. Example: 'Both parties shall maintain confidentiality of each other's proprietary information.'",
        "relevant_law": "Section 4.4, Confidentiality Policy - Confidentiality provisions must be reasonable and balanced.",
    },

    # --- INDEMNIFICATION ---
    {
        "keywords": [r"indemnif.*without.*limitation", r"indemnif.*without any cap", r"unlimited.*indemnif"],
        "risk_level": "High",
        "category": "Indemnity",
        "status": "Violation",
        "legal_concern": "Unlimited indemnification creates uncapped financial exposure for one party.",
        "suggested_fix": "Cap indemnification at a reasonable amount tied to contract value. Example: 'Indemnification obligations shall not exceed the total fees paid under this agreement.'",
        "relevant_law": "Section 6.2, Liability Policy - Indemnity clauses must be mutual and balanced. One-sided indemnity may be unconscionable.",
    },
    {
        "keywords": [r"company has no indemnification", r"no indemnif.*obligation.*toward", r"one-sided.*indemnif"],
        "risk_level": "High",
        "category": "Indemnity",
        "status": "Violation",
        "legal_concern": "One-sided indemnification where only one party bears all risk is unfair and may be unenforceable.",
        "suggested_fix": "Make indemnification mutual. Example: 'Each party shall indemnify the other against claims arising from its own negligence or breach.'",
        "relevant_law": "Section 6.2, Liability Policy - Indemnity clauses must be mutual and balanced.",
    },

    # --- JURISDICTION / GOVERNING LAW ---
    {
        "keywords": [r"courts of london", r"courts of.*united kingdom", r"english law", r"laws of.*united kingdom"],
        "risk_level": "High",
        "category": "Jurisdiction",
        "status": "Violation",
        "legal_concern": "Foreign jurisdiction and governing law for a domestic Pakistani contract is impractical and disadvantages the local party.",
        "suggested_fix": "Use Pakistani jurisdiction and law. Example: 'This agreement shall be governed by the laws of Pakistan. Disputes shall be resolved in the courts of [city], Pakistan.'",
        "relevant_law": "Section 5.2, Dispute Resolution Policy - Domestic contracts should use Pakistani law and jurisdiction.",
    },
    {
        "keywords": [r"waives.*right.*arbitration", r"waives.*right.*mediation", r"no.*arbitration"],
        "risk_level": "High",
        "category": "Jurisdiction",
        "status": "Violation",
        "legal_concern": "Waiving arbitration rights removes a cost-effective and faster dispute resolution mechanism.",
        "suggested_fix": "Include arbitration clause. Example: 'Disputes shall first be referred to arbitration under the Arbitration Act 1940 before proceeding to courts.'",
        "relevant_law": "Arbitration Act 1940 and Section 5.1 - Arbitration is the preferred method of dispute resolution.",
    },
    {
        "keywords": [r"pakistani laws shall have no applicability", r"exclude.*pakistani law"],
        "risk_level": "High",
        "category": "Jurisdiction",
        "status": "Violation",
        "legal_concern": "Excluding Pakistani law from a contract between Pakistani entities is improper and may render the contract unenforceable.",
        "suggested_fix": "Apply Pakistani law as governing law. Example: 'This agreement shall be governed by and construed in accordance with the laws of Pakistan.'",
        "relevant_law": "Section 5.2, Dispute Resolution Policy - Governing law for domestic contracts shall be the laws of Pakistan.",
    },

    # --- WORKING HOURS / EMPLOYMENT ---
    {
        "keywords": [r"24/7", r"24.*hours.*7.*days", r"seven days a week.*without.*overtime"],
        "risk_level": "High",
        "category": "Employment",
        "status": "Violation",
        "legal_concern": "Requiring 24/7 availability without overtime pay violates Pakistani labor laws on maximum working hours.",
        "suggested_fix": "Limit to standard 48 hours/week with overtime at double rate. Example: 'Working hours shall not exceed 48 hours per week. Overtime shall be compensated at double the normal rate.'",
        "relevant_law": "Factories Act 1934, Section 2.2 - Maximum 48 hours/week and 9 hours/day. Overtime must be paid at double rate.",
    },
    {
        "keywords": [r"no.*additional.*overtime.*compensation", r"without.*overtime", r"no overtime"],
        "risk_level": "High",
        "category": "Employment",
        "status": "Violation",
        "legal_concern": "Denial of overtime compensation violates mandatory labor law provisions.",
        "suggested_fix": "Include overtime compensation at the legally mandated rate. Example: 'Overtime work shall be compensated at double the normal hourly rate.'",
        "relevant_law": "Factories Act 1934 and Shops and Establishments Ordinance 1969 - Overtime must be compensated at double the normal rate.",
    },
]


def analyze_clause(clause_text: str, retrieved_laws: List[str]) -> Dict[str, Any]:
    """
    Rule-based analysis of a contract clause against Pakistani law.

    Args:
        clause_text: The contract clause text to analyze.
        retrieved_laws: List of relevant law texts retrieved via RAG/FAISS.

    Returns:
        Dict with category, risk_level, status, legal_concern, suggested_fix, relevant_law, etc.
    """
    clause_lower = clause_text.lower()
    matched_rules = []

    # Check each rule against the clause
    for rule in RISK_RULES:
        for pattern in rule["keywords"]:
            if re.search(pattern, clause_lower):
                matched_rules.append(rule)
                break  # One match per rule is enough

    if not matched_rules:
        # No risk patterns found - clause appears compliant
        relevant_law_text = retrieved_laws[0][:200] if retrieved_laws else "None"
        return {
            "status": "Compliant",
            "risk_level": "Low",
            "clause_type": _detect_category(clause_lower),
            "explanation": "This clause does not contain any known risk patterns and appears to comply with Pakistani law.",
            "relevant_law": relevant_law_text,
            "relevant_policy_excerpt": retrieved_laws[0][:300] if retrieved_laws else "None",
            "legal_concern": "No significant legal concerns identified.",
            "recommendation": "No changes required. Standard clause.",
            "suggested_fix": "No change needed",
        }

    # Use the highest-risk matched rule
    highest_risk = _get_highest_risk(matched_rules)

    # Combine concerns from all matched rules
    all_concerns = [r["legal_concern"] for r in matched_rules]
    combined_concern = " | ".join(all_concerns) if len(all_concerns) > 1 else all_concerns[0]

    # Use retrieved law from RAG if available, otherwise use rule's law reference
    rag_law = retrieved_laws[0][:200] if retrieved_laws else highest_risk["relevant_law"]

    # Build explanation from all matches
    violation_count = sum(1 for r in matched_rules if r["status"] == "Violation")
    risky_count = sum(1 for r in matched_rules if r["status"] == "Risky")
    explanation_parts = []
    if violation_count > 0:
        explanation_parts.append(f"{violation_count} violation(s) detected")
    if risky_count > 0:
        explanation_parts.append(f"{risky_count} risk indicator(s) found")
    categories = list(set(r["category"] for r in matched_rules))
    explanation_parts.append(f"Categories affected: {', '.join(categories)}")

    return {
        "status": highest_risk["status"],
        "risk_level": highest_risk["risk_level"],
        "clause_type": highest_risk["category"],
        "explanation": ". ".join(explanation_parts) + ".",
        "relevant_law": highest_risk["relevant_law"],
        "relevant_policy_excerpt": rag_law,
        "legal_concern": combined_concern,
        "recommendation": highest_risk["suggested_fix"],
        "suggested_fix": highest_risk["suggested_fix"],
    }


def _detect_category(text: str) -> str:
    """Detect clause category from text keywords."""
    category_keywords = {
        "Termination": ["terminat", "cancel", "end of agreement"],
        "Payment": ["payment", "fee", "price", "compensation", "invoice"],
        "Liability": ["liability", "liable", "damage", "loss"],
        "Confidentiality": ["confidential", "non-disclosure", "nda", "secret"],
        "Jurisdiction": ["jurisdiction", "governing law", "court", "arbitrat", "dispute"],
        "Penalty": ["penalty", "fine", "liquidated damage", "breach"],
        "Intellectual Property": ["intellectual property", "copyright", "patent", "trademark"],
        "Non-Compete": ["non-compete", "non compete", "competition", "restrictive covenant"],
        "Employment": ["working hours", "overtime", "employee", "employment"],
        "Indemnity": ["indemnif", "hold harmless"],
    }
    for cat, keywords in category_keywords.items():
        if any(kw in text for kw in keywords):
            return cat
    return "General"


def _get_highest_risk(rules: List[Dict]) -> Dict:
    """Return the rule with the highest risk level."""
    risk_priority = {"High": 3, "Medium": 2, "Low": 1}
    status_priority = {"Violation": 3, "Risky": 2, "Compliant": 1, "Not Covered": 0}
    return max(rules, key=lambda r: (
        risk_priority.get(r["risk_level"], 0),
        status_priority.get(r["status"], 0),
    ))


def generate_overall_summary(clause_results: List[Dict[str, Any]]) -> Dict[str, Any]:
    """Generate an overall risk summary from individual clause analyses."""
    violations = sum(1 for c in clause_results if c.get("status") == "Violation")
    risky = sum(1 for c in clause_results if c.get("status") == "Risky")
    compliant = sum(1 for c in clause_results if c.get("status") == "Compliant")
    not_covered = sum(1 for c in clause_results if c.get("status") == "Not Covered")

    total = len(clause_results)
    if total == 0:
        return {"overall_risk": "Unknown", "risk_score": 0, "summary": "No clauses analyzed"}

    # Calculate risk score (0-100, higher = more risky)
    risk_score = int(((violations * 3 + risky * 1.5) / (total * 3)) * 100)
    risk_score = min(risk_score, 100)

    if risk_score >= 60:
        overall_risk = "High"
    elif risk_score >= 30:
        overall_risk = "Medium"
    else:
        overall_risk = "Low"

    # Collect all relevant laws cited
    laws_cited = set()
    for c in clause_results:
        law = c.get("relevant_law", "None")
        if law and law != "None":
            laws_cited.add(law)

    # Collect high-risk concerns
    high_risk_concerns = []
    for c in clause_results:
        if c.get("risk_level") == "High":
            concern = c.get("legal_concern", c.get("explanation", ""))
            if concern:
                high_risk_concerns.append(concern)

    return {
        "overall_risk": overall_risk,
        "risk_score": risk_score,
        "compliance_summary": f"{violations} violations, {risky} risky, {compliant} compliant, {not_covered} not covered",
        "total_clauses": total,
        "violations": violations,
        "risky_count": risky,
        "compliant_count": compliant,
        "not_covered": not_covered,
        "laws_cited": list(laws_cited),
        "high_risk_concerns": high_risk_concerns[:5],
    }
