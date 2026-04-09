import os
from google import genai
from google.genai import types
from dotenv import load_dotenv

load_dotenv()

client = genai.Client(api_key=os.getenv("GEMINI_API_KEY"))

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
(list all main arguments made by complainant side)

**DEFENDANT / RESPONDENT ARGUED:**
- [Key argument 1]
- [Key argument 2]
- [Key argument 3]
(list all main arguments made by defense side)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📜 LAWS AND SECTIONS CITED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

List every law section mentioned in the judgment:
- [Law name + Section number]: [What it covers — one sentence]
- [Law name + Section number]: [What it covers — one sentence]
(include ALL sections cited, PPC, CrPC, MVO, constitutional articles, etc.)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚖️ COURT'S DECISION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**VERDICT:**
[Guilty / Not Guilty / Appeal Allowed / Appeal Dismissed /
Case Remanded / Acquitted / Convicted — state clearly]

**PUNISHMENT / ORDER:**
[Exact sentence given — years imprisonment, fine amount,
compensation ordered, property returned, etc.]

**WHO WON:**
[Complainant / Defendant — state clearly who the court sided with]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🧠 REASONING — WHY COURT DECIDED THIS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[3-5 sentences explaining the main reasons the court gave
for its decision. What evidence or logic convinced the judge?
Write clearly — no unnecessary jargon.]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📌 KEY LEGAL POINTS FOR LAWYERS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[List 3-5 important legal principles or takeaways from
this judgment that a lawyer can use in future similar cases.
These are the most valuable parts for legal research.]

- [Key point 1]
- [Key point 2]
- [Key point 3]
- [Key point 4]
- [Key point 5]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔍 PAST CASES REFERENCED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[List any past judgments / precedents the court cited
to support its decision. If none mentioned write "None cited".]

- [Case name + year if available]
- [Case name + year if available]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 CASE STRENGTH ANALYSIS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**EVIDENCE PRESENTED:**
[Was evidence strong or weak? What type of evidence was used?]

**MISSING ELEMENTS:**
[What was missing from this case that could have changed outcome?]

**OVERALL CASE STRENGTH:** [Strong / Medium / Weak]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Document text to summarize:
{document_text}"""


def summarize_case(document_text: str, filename: str) -> dict:
    """Main summarization function using google-genai SDK"""

    if not document_text or len(document_text.strip()) < 100:
        return {
            "success": False,
            "error": "Document text is too short to summarize."
        }

    text_to_send = document_text
    truncated = False
    # 15,000 chars (~2,500 words) is enough for accurate summarization
    # and keeps Gemini response time under 30 seconds
    if len(document_text) > 15000:
        text_to_send = document_text[:15000]
        truncated = True

    try:
        response = client.models.generate_content(
            model="gemini-2.5-flash",
            contents=SUMMARIZER_PROMPT.format(document_text=text_to_send),
            config=types.GenerateContentConfig(
                temperature=0.2,
                max_output_tokens=3000,
            ),
        )

        summary_text = response.text.strip()

        return {
            "success": True,
            "summary": summary_text,
            "filename": filename,
            "truncated": truncated,
            "original_length": len(document_text),
            "summary_length": len(summary_text)
        }

    except Exception as e:
        return {
            "success": False,
            "error": f"AI summarization failed: {str(e)}"
        }
