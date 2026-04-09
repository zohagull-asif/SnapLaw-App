"""
Redaction Engine for SnapLaw Evidence Scanner.
Finds and blacks out personal/sensitive information using regex + Gemini AI.
"""

import re
import os
import logging
import google.generativeai as genai
from dotenv import load_dotenv

load_dotenv()
logger = logging.getLogger(__name__)

# Configure Gemini
genai.configure(api_key=os.getenv("GEMINI_API_KEY"))
model = genai.GenerativeModel("gemini-2.5-flash")

# Regex patterns for common Pakistani personal data
PATTERNS = {
    "CNIC": r'\b\d{5}-\d{7}-\d{1}\b',
    "Phone": r'\b(\+92|0092|0)?[-.\s]?[0-9]{3}[-.\s]?[0-9]{7}\b',
    "Email": r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b',
    "Date_of_Birth": r'\b(DOB|Date of Birth|D\.O\.B|تاریخ پیدائش)[:\s]+\d{1,2}[/-]\d{1,2}[/-]\d{2,4}\b',
    "Bank_Account": r'\b(?:IBAN|Account)[:\s]*[A-Z]{0,2}\d{10,24}\b',
    "Passport": r'\b[A-Z]{2}\d{7}\b',
}

REDACTION_PROMPT = """You are a privacy protection expert for Pakistani legal documents.

Read the following extracted text from a legal document and identify ALL
personally identifiable information (PII) that should be redacted.

Find and list these types of sensitive information:
1. Full names of private individuals (NOT public officials, judges, or advocates)
2. Home addresses (street, mohalla, house number, city, district)
3. CNIC numbers (format: XXXXX-XXXXXXX-X)
4. Phone numbers (mobile or landline)
5. Email addresses
6. Date of birth
7. Bank account numbers or IBAN
8. Passport numbers
9. Vehicle registration numbers
10. Names of minor children
11. Father's name / Husband's name when linked to identity

For each item found, respond in EXACTLY this format (one per line):
REDACT: [exact text to redact] | TYPE: [type of info]

If nothing sensitive found, respond with ONLY:
NOTHING_TO_REDACT

Document text:
{text}"""


def find_sensitive_info_regex(text: str) -> list:
    """Fast regex-based detection for common patterns."""
    found = []
    for data_type, pattern in PATTERNS.items():
        matches = re.finditer(pattern, text, re.IGNORECASE)
        for match in matches:
            found.append({
                "text": match.group(),
                "type": data_type,
                "start": match.start(),
                "end": match.end()
            })
    return found


def find_sensitive_info_ai(text: str) -> list:
    """AI-based detection for names, addresses, and complex patterns."""
    try:
        # Truncate very long texts
        truncated = text[:4000] if len(text) > 4000 else text

        response = model.generate_content(
            REDACTION_PROMPT.format(text=truncated)
        )

        result_text = response.text.strip()

        if "NOTHING_TO_REDACT" in result_text:
            return []

        found = []
        for line in result_text.split('\n'):
            line = line.strip()
            if line.startswith('REDACT:'):
                parts = line.split('|')
                if len(parts) >= 2:
                    sensitive_text = parts[0].replace('REDACT:', '').strip()
                    data_type = parts[1].replace('TYPE:', '').strip()
                    if sensitive_text and len(sensitive_text) > 1:
                        found.append({
                            "text": sensitive_text,
                            "type": data_type
                        })
        return found

    except Exception as e:
        logger.error(f"AI redaction failed: {e}")
        return []


def redact_text(original_text: str, sensitive_items: list) -> str:
    """Replace sensitive text with [REDACTED] placeholders."""
    redacted = original_text

    # Sort by length (longest first) to avoid partial replacements
    sorted_items = sorted(
        sensitive_items,
        key=lambda x: len(x.get("text", "")),
        reverse=True
    )

    for item in sorted_items:
        text_to_redact = item.get("text", "")
        if text_to_redact and len(text_to_redact) > 1:
            type_label = item['type'].upper().replace(' ', '_')
            placeholder = f"[{type_label} REDACTED]"
            redacted = redacted.replace(text_to_redact, placeholder)

    return redacted


def process_redaction(text: str) -> dict:
    """Main redaction function combining regex + AI detection."""

    if not text or not text.strip():
        return {
            "original_text": text,
            "redacted_text": text,
            "total_redacted": 0,
            "redacted_items": [],
            "is_clean": True
        }

    # Step 1: Regex detection (fast, catches CNIC/phone/email)
    regex_findings = find_sensitive_info_regex(text)
    logger.info(f"Regex found {len(regex_findings)} items")

    # Step 2: AI detection (catches names, addresses, complex info)
    ai_findings = find_sensitive_info_ai(text)
    logger.info(f"AI found {len(ai_findings)} items")

    # Combine all findings and remove duplicates
    all_findings = regex_findings + ai_findings
    seen = set()
    unique_findings = []
    for item in all_findings:
        item_text = item.get("text", "").strip()
        if item_text and item_text not in seen and len(item_text) > 1:
            seen.add(item_text)
            unique_findings.append(item)

    # Apply redaction
    redacted_text = redact_text(text, unique_findings)

    return {
        "original_text": text,
        "redacted_text": redacted_text,
        "total_redacted": len(unique_findings),
        "redacted_items": [
            {"type": item["type"], "length": len(item.get("text", ""))}
            for item in unique_findings
        ],
        "is_clean": len(unique_findings) == 0
    }
