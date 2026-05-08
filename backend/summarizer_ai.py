import os
import requests
from dotenv import load_dotenv

load_dotenv()

GROQ_API_KEY = os.getenv("GROQ_API_KEY", "")
GROQ_URL = "https://api.groq.com/openai/v1/chat/completions"
GROQ_MODEL = "llama-3.3-70b-versatile"

SUMMARIZER_PROMPT = """You are an expert Pakistani legal analyst and case summarizer
for SnapLaw, a legal platform used by lawyers in Pakistan.

A lawyer has uploaded a court judgment or legal document. Your job is to read the
full text and produce a highly structured, accurate, and easy-to-understand summary.

The summary must follow EXACTLY this format with all these sections.
Do not skip any section. If information is not found write "Not mentioned in document".

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 CASE SUMMARY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**CASE TITLE:**
[Full case name e.g. Muhammad Ali vs State of Pakistan]

**CASE NUMBER:**
[Case/Appeal/Writ number]

**COURT:**
[Which court — Supreme Court / High Court / Sessions Court / etc.]

**JUDGMENT DATE:**
[Date the judgment was issued]

**JUDGE(S):**
[Name(s) of judge(s) who decided the case]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚖️ PARTIES INVOLVED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**COMPLAINANT / APPELLANT:**
[Who filed the case / who is suing]

**DEFENDANT / RESPONDENT:**
[Who is being sued / defending]

**LAWYERS:**
[Advocate names if mentioned]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📖 WHAT THIS CASE IS ABOUT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**CASE TYPE:**
[Criminal / Civil / Family / Property / Labor / Constitutional / etc.]

**BACKGROUND IN SIMPLE WORDS:**
[3-5 sentences explaining what happened that led to this case.
Write as if explaining to a non-lawyer. No legal jargon.]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🗣️ ARGUMENTS MADE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**COMPLAINANT / APPELLANT ARGUED:**
- [Key argument 1]
- [Key argument 2]
- [Key argument 3]

**DEFENDANT / RESPONDENT ARGUED:**
- [Key argument 1]
- [Key argument 2]
- [Key argument 3]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📜 LAWS AND SECTIONS CITED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

- [Law name + Section number]: [What it covers — one sentence]
- [Law name + Section number]: [What it covers — one sentence]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚖️ COURT'S DECISION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**VERDICT:**
[Guilty / Not Guilty / Appeal Allowed / Appeal Dismissed / Acquitted / Convicted]

**PUNISHMENT / ORDER:**
[Exact sentence given]

**WHO WON:**
[Complainant / Defendant]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🧠 REASONING — WHY COURT DECIDED THIS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[3-5 sentences explaining the main reasons the court gave for its decision.]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📌 KEY LEGAL POINTS FOR LAWYERS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

- [Key point 1]
- [Key point 2]
- [Key point 3]
- [Key point 4]
- [Key point 5]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔍 PAST CASES REFERENCED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

- [Case name + year if available]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 CASE STRENGTH ANALYSIS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**EVIDENCE PRESENTED:**
[Was evidence strong or weak?]

**MISSING ELEMENTS:**
[What was missing from this case?]

**OVERALL CASE STRENGTH:** [Strong / Medium / Weak]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Document text to summarize:
{document_text}"""


def summarize_case(document_text: str, filename: str) -> dict:
    """Summarize using Groq Llama model."""

    if not document_text or len(document_text.strip()) < 100:
        return {
            "success": False,
            "error": "Document text is too short to summarize."
        }

    if not GROQ_API_KEY:
        return {
            "success": False,
            "error": "GROQ_API_KEY not configured in backend .env"
        }

    text_to_send = document_text
    truncated = False
    if len(document_text) > 15000:
        text_to_send = document_text[:15000]
        truncated = True

    try:
        response = requests.post(
            GROQ_URL,
            headers={
                "Authorization": f"Bearer {GROQ_API_KEY}",
                "Content-Type": "application/json"
            },
            json={
                "model": GROQ_MODEL,
                "messages": [
                    {
                        "role": "system",
                        "content": "You are an expert Pakistani legal analyst. Follow the exact format requested. Do not add extra commentary outside the format."
                    },
                    {
                        "role": "user",
                        "content": SUMMARIZER_PROMPT.format(document_text=text_to_send)
                    }
                ],
                "max_tokens": 3000,
                "temperature": 0.2
            },
            timeout=120
        )

        if response.status_code == 401:
            return {"success": False, "error": "Invalid Groq API key. Check GROQ_API_KEY in backend .env"}

        if response.status_code == 429:
            return {"success": False, "error": "Groq rate limit reached. Please try again in a moment."}

        if response.status_code != 200:
            return {"success": False, "error": f"Groq API error {response.status_code}: {response.text[:300]}"}

        summary_text = response.json()["choices"][0]["message"]["content"].strip()

        return {
            "success": True,
            "summary": summary_text,
            "filename": filename,
            "truncated": truncated,
            "original_length": len(document_text),
            "summary_length": len(summary_text)
        }

    except requests.Timeout:
        return {"success": False, "error": "Request timed out. Try a shorter document."}
    except Exception as e:
        return {"success": False, "error": f"AI summarization failed: {str(e)}"}
