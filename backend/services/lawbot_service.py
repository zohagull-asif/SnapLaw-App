"""
LawBot Service — Central AI engine for SnapLaw's legal assistant.
Provides: Legal Q&A (category-filtered KB), Contract Simplifier, Bias Checker, SafeSpace (Abuse Guidance).
"""

import re
import logging
from typing import Dict, Any, List
from deep_translator import GoogleTranslator

logger = logging.getLogger(__name__)


# ─── Contract Simplifier: Legal jargon → plain language ───

LEGAL_SIMPLIFICATIONS = [
    # Latin / archaic terms
    (r"\bhereinafter\b", "from now on"),
    (r"\bherein\b", "in this document"),
    (r"\bhereby\b", "by this document"),
    (r"\bhereto\b", "to this document"),
    (r"\bhereunder\b", "under this document"),
    (r"\bhereof\b", "of this document"),
    (r"\bthereof\b", "of that"),
    (r"\btherein\b", "in that"),
    (r"\bthereby\b", "by that"),
    (r"\bwherein\b", "where"),
    (r"\bwhereas\b", "since"),
    (r"\bnotwithstanding\b", "despite"),
    (r"\baforesaid\b", "mentioned earlier"),
    (r"\bforgoing\b", "previous"),
    (r"\bforegoing\b", "previous"),
    (r"\bshall\b", "must"),
    (r"\bshall not\b", "must not"),
    (r"\bdeem(?:ed)?\b", "consider(ed)"),
    (r"\bpursuant to\b", "according to"),
    (r"\bin lieu of\b", "instead of"),
    (r"\bwithout prejudice\b", "without affecting rights"),
    (r"\bmutatis mutandis\b", "with necessary changes"),
    (r"\binter alia\b", "among other things"),
    (r"\bprima facie\b", "at first sight"),
    (r"\bab initio\b", "from the beginning"),
    (r"\bbona fide\b", "in good faith"),
    (r"\bde facto\b", "in practice"),
    (r"\bde jure\b", "by law"),
    (r"\bin toto\b", "completely"),
    (r"\bipso facto\b", "by that very fact"),
    (r"\bviz\.?\b", "namely"),
    (r"\bi\.e\.?\b", "that is"),
    (r"\be\.g\.?\b", "for example"),
    (r"\bthe party of the first part\b", "the first party"),
    (r"\bthe party of the second part\b", "the second party"),
    (r"\bindemnif(?:y|ies|ication)\b", "compensate / protect from loss"),
    (r"\bforce majeure\b", "unforeseeable circumstances (e.g., natural disasters)"),
    (r"\bliquidated damages\b", "pre-agreed compensation for breach"),
    (r"\bnon-compete\b", "restriction from working with competitors"),
    (r"\bwaiver\b", "giving up a right"),
    (r"\bseverability\b", "if one part is invalid, the rest still applies"),
]


def translate_to_urdu(text: str) -> str:
    """Translate English text to proper Urdu using Google Translate."""
    try:
        # Split into chunks of max 4500 chars (Google Translate limit is 5000)
        chunks = []
        sentences = re.split(r'(?<=[.!?])\s+', text)
        current_chunk = ""
        for sentence in sentences:
            if len(current_chunk) + len(sentence) + 1 > 4500:
                if current_chunk:
                    chunks.append(current_chunk.strip())
                current_chunk = sentence
            else:
                current_chunk += " " + sentence if current_chunk else sentence
        if current_chunk:
            chunks.append(current_chunk.strip())

        translator = GoogleTranslator(source='en', target='ur')
        translated_chunks = []
        for chunk in chunks:
            translated = translator.translate(chunk)
            if translated:
                translated_chunks.append(translated)

        return "\n\n".join(translated_chunks)
    except Exception as e:
        logger.error(f"Urdu translation failed: {e}")
        return "ترجمہ دستیاب نہیں ہے۔ براہ کرم دوبارہ کوشش کریں۔ (Translation not available. Please try again.)"


def simplify_contract(text: str, language: str = "en") -> Dict[str, Any]:
    """Simplify legal jargon in contract text to plain language."""
    simplified = text
    changes_made = []

    for pattern, replacement in LEGAL_SIMPLIFICATIONS:
        matches = re.findall(pattern, simplified, re.IGNORECASE)
        if matches:
            for match in set(matches):
                changes_made.append({"original": match, "simplified": replacement})
            simplified = re.sub(pattern, replacement, simplified, flags=re.IGNORECASE)

    # Break very long sentences (over 50 words)
    sentences = re.split(r'(?<=[.;])\s+', simplified)
    broken_sentences = []
    for sentence in sentences:
        words = sentence.split()
        if len(words) > 50:
            # Split at commas or conjunctions
            parts = re.split(r',\s*(?:and|or|but|however|provided that|subject to)\s+', sentence)
            broken_sentences.extend([p.strip() + '.' for p in parts if p.strip()])
        else:
            broken_sentences.append(sentence)

    simplified = '\n\n'.join(broken_sentences)

    # Summary
    word_count = len(text.split())
    simplified_count = len(simplified.split())

    # Urdu translation if requested
    urdu_text = ""
    if language == "urdu":
        urdu_text = translate_to_urdu(simplified)

    return {
        "simplified_text": simplified,
        "urdu_text": urdu_text,
        "changes_made": changes_made[:20],  # Limit to top 20
        "total_changes": len(changes_made),
        "original_word_count": word_count,
        "simplified_word_count": simplified_count,
        "summary": f"Simplified {len(changes_made)} legal terms into plain language."
        if changes_made
        else "No complex legal jargon detected. The text is already fairly simple.",
    }


# ─── Abuse Detection: LLM-powered (uses abuse_detector.py) ───
# Detection is handled by services/abuse_detector.py using OpenAI GPT-4o-mini
# The /api/detect-abuse endpoint calls it directly from the router


# ─── SafeSpace: Abuse & Harassment Guidance ───

SAFESPACE_KEYWORDS = {
    "harassment": [
        "harassment", "harass", "harassed", "harassing",
        "stalking", "stalker", "stalked",
        "bullying", "bully", "bullied",
        "threatening", "threatened", "threats",
        "intimidation", "intimidate", "intimidated",
    ],
    "domestic_violence": [
        "domestic violence", "domestic abuse",
        "violence", "violent", "beaten", "beat me", "hits me", "hitting",
        "physical abuse", "physical violence",
        "spouse abuse", "partner abuse",
    ],
    "sexual_abuse": [
        "sexual abuse", "sexual harassment", "sexual assault",
        "rape", "raped", "molestation", "molested",
        "inappropriate touch", "sexual misconduct",
    ],
    "workplace_abuse": [
        "workplace harassment", "workplace abuse", "workplace bullying",
        "boss harass", "employer abuse", "unfair treatment at work",
        "wrongful termination", "hostile work environment",
    ],
    "child_abuse": [
        "child abuse", "child labor", "child labour",
        "minor abuse", "child exploitation",
    ],
    "cyber_abuse": [
        "cyberbullying", "cyber harassment", "online harassment",
        "online abuse", "blackmail", "revenge porn", "sextortion",
    ],
}

SAFESPACE_RESPONSES = {
    "harassment": {
        "title": "Harassment & Stalking Guidance",
        "steps": [
            "Document everything — save messages, screenshots, emails, and note dates/times of incidents.",
            "Report to police — File an FIR (First Information Report) at your nearest police station under the Pakistan Penal Code.",
            "Seek a restraining order — Apply to a court for a protection order against the harasser.",
            "Contact Punjab/Sindh/KP Women Protection Authority if applicable.",
            "Reach out to helplines for immediate support.",
        ],
        "laws": [
            "Pakistan Penal Code Section 509 — Word, gesture or act intended to insult modesty",
            "Protection Against Harassment of Women at Workplace Act 2010",
            "Punjab Protection of Women Against Violence Act 2016",
            "Prevention of Electronic Crimes Act (PECA) 2016 — for online harassment",
        ],
        "helplines": [
            "Women's Helpline: 1099",
            "Punjab Women Safety App: Women Safety App",
            "National Commission on Status of Women: 051-9224875",
            "Madadgaar Helpline: 0800-22444",
        ],
    },
    "domestic_violence": {
        "title": "Domestic Violence Guidance",
        "steps": [
            "Ensure your immediate safety — If in danger, leave the location and go to a safe place (family, friend, shelter).",
            "Call emergency services: Rescue 1122 or Police 15.",
            "File an FIR at the nearest police station — Domestic violence is a criminal offense.",
            "Seek medical attention and document all injuries with medical reports.",
            "Apply for a protection order under the Domestic Violence (Prevention & Protection) Act.",
            "Contact a women's shelter or Dar-ul-Aman for temporary refuge.",
            "Consult a family law attorney for legal options including divorce, custody, and maintenance.",
        ],
        "laws": [
            "Domestic Violence (Prevention & Protection) Act 2012",
            "Punjab Protection of Women Against Violence Act 2016",
            "Sindh Domestic Violence (Prevention & Protection) Act 2013",
            "Pakistan Penal Code Section 337 — Hurt offenses",
        ],
        "helplines": [
            "Women's Helpline: 1099",
            "Rescue Emergency: 1122",
            "Police Emergency: 15",
            "Edhi Foundation: 115",
            "Madadgaar Helpline: 0800-22444",
        ],
    },
    "sexual_abuse": {
        "title": "Sexual Abuse & Assault Guidance",
        "steps": [
            "Prioritize your safety — Move to a safe location immediately.",
            "Do NOT shower or change clothes — Preserve physical evidence.",
            "Seek immediate medical attention at a hospital.",
            "File an FIR at the police station — This is your legal right.",
            "Request a female police officer if you feel more comfortable.",
            "Get a medico-legal examination done within 72 hours.",
            "Contact a lawyer specializing in criminal/women's rights law.",
            "Seek psychological support from a counselor.",
        ],
        "laws": [
            "Pakistan Penal Code Section 375-376 — Rape",
            "Anti-Rape (Investigation and Trial) Act 2021",
            "Criminal Law (Amendment) (Offenses Relating to Rape) Act 2016",
            "Protection Against Harassment of Women at Workplace Act 2010",
        ],
        "helplines": [
            "Women's Helpline: 1099",
            "War Against Rape (WAR): 021-35682227",
            "Madadgaar Helpline: 0800-22444",
            "Rozan Counseling: 051-2890505",
        ],
    },
    "workplace_abuse": {
        "title": "Workplace Harassment Guidance",
        "steps": [
            "Document all incidents — Keep a written record with dates, times, witnesses, and details.",
            "Report to your organization's Inquiry Committee (mandatory under the law).",
            "If no committee exists, file a complaint with the Ombudsperson for Protection Against Harassment.",
            "File a written complaint with specific details of the harassment.",
            "The Ombudsperson must decide within 30 days.",
            "You can appeal to the relevant court if unsatisfied with the decision.",
        ],
        "laws": [
            "Protection Against Harassment of Women at Workplace Act 2010",
            "Every organization with employees is required to have an Inquiry Committee",
            "Federal/Provincial Ombudsperson handles complaints",
        ],
        "helplines": [
            "Federal Ombudsperson: 051-9205263",
            "Women's Helpline: 1099",
            "Madadgaar Helpline: 0800-22444",
        ],
    },
    "child_abuse": {
        "title": "Child Abuse Guidance",
        "steps": [
            "Ensure the child's immediate safety — Remove them from the harmful situation.",
            "Report to police — File an FIR immediately.",
            "Seek medical attention for the child.",
            "Contact Child Protection Bureau in your province.",
            "Document all evidence carefully.",
            "Consult a child rights lawyer.",
            "Seek counseling for the child from a qualified psychologist.",
        ],
        "laws": [
            "Punjab Destitute and Neglected Children Act 2004",
            "Sindh Child Protection Authority Act 2011",
            "ICT Child Protection Act 2018",
            "Pakistan Penal Code — Various sections on offenses against children",
            "Zainab Alert, Response and Recovery Act 2020",
        ],
        "helplines": [
            "Zainab Alert Helpline: 1099",
            "Child Protection Bureau: 1121",
            "Edhi Foundation: 115",
            "Pakistan Child Protection (SPARC): 042-35761999",
        ],
    },
    "cyber_abuse": {
        "title": "Cyber Harassment & Online Abuse Guidance",
        "steps": [
            "Do NOT delete any evidence — Screenshot all messages, posts, profiles.",
            "Block the abuser on all platforms.",
            "Report the content to the platform (Facebook, Instagram, etc.).",
            "File a complaint with FIA Cyber Crime Wing (online or in-person).",
            "FIA Cyber Crime reporting: Go to nr3c.gov.pk",
            "File an FIR at local police station if threats are involved.",
            "Consult a cyber crime lawyer for legal action.",
        ],
        "laws": [
            "Prevention of Electronic Crimes Act (PECA) 2016",
            "Section 21 — Offenses against modesty and minor",
            "Section 24 — Cyber stalking (up to 3 years jail + fine)",
            "Pakistan Penal Code Section 509 — Insult to modesty",
        ],
        "helplines": [
            "FIA Cyber Crime Wing: 9911",
            "FIA Online Complaint: nr3c.gov.pk",
            "Women's Helpline: 1099",
            "Digital Rights Foundation: 0800-39393",
        ],
    },
    "general": {
        "title": "General Guidance — Seeking Help",
        "steps": [
            "Identify the type of abuse or concern you are facing.",
            "Document all incidents with dates, times, and details.",
            "Report to local police by filing an FIR.",
            "Contact relevant helplines for immediate support.",
            "Consult a qualified lawyer for legal guidance.",
            "Seek medical or psychological help if needed.",
        ],
        "laws": [
            "Pakistan Penal Code — General criminal offenses",
            "Constitution of Pakistan Article 9 — Right to life and liberty",
            "Constitution of Pakistan Article 14 — Right to dignity",
        ],
        "helplines": [
            "Police Emergency: 15",
            "Rescue Emergency: 1122",
            "Women's Helpline: 1099",
            "Edhi Foundation: 115",
            "Madadgaar Helpline: 0800-22444",
        ],
    },
}


def get_safespace_guidance(text: str) -> Dict[str, Any]:
    """Detect abuse type and provide step-by-step guidance with legal references."""
    text_lower = text.lower()
    detected_categories = []

    for category, keywords in SAFESPACE_KEYWORDS.items():
        for keyword in keywords:
            if keyword in text_lower:
                detected_categories.append(category)
                break

    if not detected_categories:
        response_data = SAFESPACE_RESPONSES["general"]
        detected_categories = ["general"]
    else:
        priority = ["sexual_abuse", "child_abuse", "domestic_violence", "cyber_abuse", "workplace_abuse", "harassment"]
        selected = "general"
        for p in priority:
            if p in detected_categories:
                selected = p
                break
        response_data = SAFESPACE_RESPONSES[selected]

    steps_text = "\n".join([f"Step {i+1}: {s}" for i, s in enumerate(response_data["steps"])])
    laws_text = "\n".join([f"  - {l}" for l in response_data["laws"]])
    helplines_text = "\n".join([f"  - {h}" for h in response_data["helplines"]])

    formatted_response = (
        f"{response_data['title']}\n\n"
        f"What You Should Do:\n{steps_text}\n\n"
        f"Relevant Laws:\n{laws_text}\n\n"
        f"Helplines & Resources:\n{helplines_text}\n\n"
        f"Remember: You are not alone. Seeking help is a sign of strength, not weakness. "
        f"If you are in immediate danger, call 15 (Police) or 1122 (Rescue) right away."
    )

    return {
        "detected_categories": detected_categories,
        "title": response_data["title"],
        "response": formatted_response,
        "steps": response_data["steps"],
        "laws": response_data["laws"],
        "helplines": response_data["helplines"],
    }


# ─── Legal Q&A (Category-Filtered Knowledge Base) ───

from services.legal_kb import detect_category, build_legal_answer, get_category_label


def legal_qa(query: str) -> Dict[str, Any]:
    """
    Answer legal questions using category-filtered knowledge base.

    Pipeline:
      Question → Category Detection (keyword matching)
      → Retrieve ONLY laws from that category
      → Build structured answer with sections + procedure + penalties
      → Return with sources and confidence

    This ensures NO cross-domain contamination (e.g., traffic questions
    never return criminal rape/robbery sections).
    """
    if not query or not query.strip():
        return {
            "answer": "Please provide a legal question to get assistance.",
            "sources": [],
            "confidence": 0,
        }

    # Step 1: Detect the legal category
    category = detect_category(query)
    label = get_category_label(category)
    logger.info(f"Legal Q&A — category: {category} ({label}), query: {query[:80]}")

    # Step 2: Build answer using ONLY laws from the detected category
    result = build_legal_answer(query, category)

    logger.info(f"Legal Q&A — returning {len(result['sections'])} sections from {category}")

    return {
        "answer": result["answer"],
        "sources": result["sources"],
        "confidence": result["confidence"],
        "category": result["category"],
        "category_label": result["category_label"],
        "sections": result["sections"],
    }


# ─── Main LawBot Engine ───

class LawBotService:
    """Central LawBot engine that dispatches requests to the appropriate handler."""

    @staticmethod
    def process_request(request_type: str, input_text: str, language: str = "en") -> Dict[str, Any]:
        """
        Process a LawBot request.

        Args:
            request_type: "qa", "simplify", "bias", or "guidance"
            input_text: User input text
            language: "en" or "urdu" (for simplifier Urdu translation)

        Returns:
            Dict with response data
        """
        if not input_text or not input_text.strip():
            return {"error": "Please provide some text to analyze."}

        input_text = input_text.strip()

        if request_type == "qa":
            result = legal_qa(input_text)
            return {
                "type": "qa",
                "response": result["answer"],
                "sources": result.get("sources", []),
                "confidence": result.get("confidence", 0),
                "category": result.get("category", ""),
                "category_label": result.get("category_label", ""),
                "sections": result.get("sections", []),
            }

        elif request_type == "simplify":
            result = simplify_contract(input_text, language=language)
            return {
                "type": "simplify",
                "response": result["simplified_text"],
                "urdu_text": result.get("urdu_text", ""),
                "changes_made": result["changes_made"],
                "total_changes": result["total_changes"],
                "summary": result["summary"],
            }

        elif request_type == "abuse":
            from services.abuse_detector import detect_abuse as llm_detect_abuse
            result = llm_detect_abuse(input_text)
            return {
                "type": "abuse",
                "is_abusive": result["is_abusive"],
                "response": result["result"],
            }

        elif request_type == "guidance":
            result = get_safespace_guidance(input_text)
            return {
                "type": "guidance",
                "response": result["response"],
                "title": result["title"],
                "detected_categories": result["detected_categories"],
                "steps": result["steps"],
                "laws": result["laws"],
                "helplines": result["helplines"],
            }

        else:
            return {"error": f"Unknown request type: {request_type}"}


# Global instance
lawbot_service = LawBotService()
