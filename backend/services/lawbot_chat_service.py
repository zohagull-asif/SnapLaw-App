"""
LawBot Chat Service — Groq-powered Pakistani law chatbot.
Uses LLaMA 3.3-70b via Groq API for fast, accurate legal answers.
Maintains conversation history per session.
Supports English, Urdu, and Roman Urdu.
"""

import os
import logging
import requests
from dotenv import load_dotenv

load_dotenv()
logger = logging.getLogger(__name__)

GROQ_API_KEY = os.getenv("GROQ_API_KEY", "")
GROQ_URL = "https://api.groq.com/openai/v1/chat/completions"
GROQ_MODEL = "llama-3.3-70b-versatile"

SYSTEM_PROMPT = """You are LawBot, the official AI legal assistant for SnapLaw — a Pakistani legal platform.

You are an expert in ALL areas of Pakistani law. You help users by answering any legal question
related to Pakistan in a detailed, accurate, and practical way.
Users may ask in English, Urdu, or Roman Urdu. Always respond in the same language the user uses.

YOUR RULES:
1. ONLY answer questions related to Pakistani law.
2. Always cite specific law names, section numbers, and punishments.
3. Keep answers clear, simple, and actionable.
4. If a question involves multiple legal areas, cover all of them.
5. Always mention practical steps the user should take.
6. If unsure, say so honestly.
7. For emergencies (violence, threats, abuse), always mention: Police 15, Rescue 1122.

YOUR KNOWLEDGE COVERS:
- Pakistan Penal Code (PPC) 1860
- Code of Criminal Procedure (CrPC) 1898
- Code of Civil Procedure (CPC) 1908
- Constitution of Pakistan 1973
- Muslim Family Laws Ordinance 1961 (divorce, khula, custody, maintenance, mehr)
- Transfer of Property Act 1882, Registration Act 1908, Land Revenue Act
- Labor Laws: Industrial Relations Act, Payment of Wages Act, Factories Act, EOBI
- Contract Act 1872
- Prevention of Electronic Crimes Act (PECA) 2016
- Protection Against Harassment of Women at Workplace Act 2010
- Anti-Terrorism Act 1997
- National Accountability Bureau (NAB) Ordinance 1999
- Companies Act 2017
- Consumer Protection Laws
- Rent Restriction Ordinances
- Negotiable Instruments Act 1881 (Cheque Bounce)
- Qanun-e-Shahadat (Evidence) Order 1984
- Juvenile Justice System Act 2018
- Zainab Alert Act 2020
- Anti-Rape (Investigation and Trial) Act 2021
- Domestic Violence (Prevention & Protection) Act
- All provincial laws (Punjab, Sindh, KP, Balochistan)
- Islamic law as applied in Pakistani courts (Hudood, Qisas, Diyat)

RESPONSE FORMAT:
- Start with a direct, comprehensive answer
- Cite specific laws with section numbers
- Mention punishments/penalties where relevant
- Give practical step-by-step guidance
- End with: "For your specific case, please consult a qualified lawyer."

Be thorough and detailed. Users depend on you for real legal guidance."""

# In-memory conversation history per session
_chat_histories: dict = {}


def chat_with_lawbot(message: str, session_id: str = "default") -> dict:
    """Send a message to LawBot and get a detailed response about Pakistani law."""
    if not message or len(message.strip()) < 3:
        return {
            "response": "Please type your legal question so I can help you.",
            "session_id": session_id,
        }

    if len(message) > 3000:
        message = message[:3000]

    if not GROQ_API_KEY:
        return {
            "response": "AI service not configured. Please contact support.",
            "session_id": session_id,
            "error": "GROQ_API_KEY not set",
        }

    try:
        # Get or create conversation history for this session
        if session_id not in _chat_histories:
            _chat_histories[session_id] = []

        history = _chat_histories[session_id]

        # Build messages array: system + history + new message
        messages = [{"role": "system", "content": SYSTEM_PROMPT}]
        messages.extend(history)
        messages.append({"role": "user", "content": message})

        headers = {
            "Authorization": f"Bearer {GROQ_API_KEY}",
            "Content-Type": "application/json",
        }
        payload = {
            "model": GROQ_MODEL,
            "messages": messages,
            "max_tokens": 1500,
            "temperature": 0.7,
        }

        response = requests.post(GROQ_URL, headers=headers, json=payload, timeout=45)
        response.raise_for_status()
        data = response.json()
        answer = data["choices"][0]["message"]["content"].strip()

        # Save to history (keep last 10 exchanges = 20 messages)
        history.append({"role": "user", "content": message})
        history.append({"role": "assistant", "content": answer})
        if len(history) > 20:
            history = history[-20:]
        _chat_histories[session_id] = history

        return {
            "response": answer,
            "session_id": session_id,
        }

    except requests.exceptions.Timeout:
        logger.error("Groq API timeout")
        return {
            "response": "I'm taking too long to respond. Please try again.",
            "session_id": session_id,
            "error": "timeout",
        }
    except Exception as e:
        logger.error(f"LawBot chat failed: {e}", exc_info=True)
        return {
            "response": "Sorry, I couldn't process your question right now. Please try again.",
            "session_id": session_id,
            "error": str(e),
        }


def clear_chat_session(session_id: str = "default"):
    """Clear a chat session to start fresh."""
    if session_id in _chat_histories:
        del _chat_histories[session_id]
    return {"status": "cleared", "session_id": session_id}
