import os
import json
import requests

GROQ_API_KEY = os.getenv("GROQ_API_KEY", "")
GROQ_URL = "https://api.groq.com/openai/v1/chat/completions"


def detect_abuse(text: str) -> dict:
    if not GROQ_API_KEY:
        return {"error": "GROQ_API_KEY not configured"}

    prompt = f"""You are an abuse and harassment detection expert specializing in Pakistani law.

Analyze the following text and determine if it contains harassment, abuse, threats, hate speech, or discriminatory language.

Text to analyze:
\"\"\"{text}\"\"\"

Respond in this exact JSON format:
{{
  "is_abusive": true or false,
  "abuse_type": "harassment / threat / hate speech / physical abuse / stalking / none",
  "severity": "high / medium / low / none",
  "offensive_elements": ["list what specific parts are offensive"],
  "explanation": "explain clearly what is wrong with this text",
  "pakistani_laws_violated": ["Protection Against Harassment of Women at Workplace Act 2010", "Pakistan Penal Code Section 509", "etc"],
  "immediate_actions": [
    "Step 1: what the victim should do right now",
    "Step 2: next action",
    "Step 3: etc"
  ],
  "where_to_report": [
    "Call 15 (Police Emergency)",
    "Call 1122 (Rescue)",
    "Call 0800-22227 (Umang Helpline for women)",
    "Visit nearest FIA Cybercrime wing if online harassment",
    "File FIR at local police station under PPC Section 509"
  ],
  "legal_remedies": "explain what legal action they can take under Pakistani law"
}}"""

    headers = {
        "Authorization": f"Bearer {GROQ_API_KEY}",
        "Content-Type": "application/json"
    }
    body = {
        "model": "llama-3.3-70b-versatile",
        "messages": [{"role": "user", "content": prompt}],
        "max_tokens": 1500,
        "temperature": 0.3,
        "response_format": {"type": "json_object"}
    }
    response = requests.post(GROQ_URL, headers=headers, json=body, timeout=30)
    response.raise_for_status()
    content = response.json()["choices"][0]["message"]["content"]
    return json.loads(content)
