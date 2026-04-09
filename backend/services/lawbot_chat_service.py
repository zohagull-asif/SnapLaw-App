"""
LawBot Chat Service — Gemini-powered Pakistani law chatbot.
Handles any legal question related to Pakistani law and responds
with accurate, structured answers citing specific laws and sections.
"""

import os
import logging
import google.generativeai as genai
from dotenv import load_dotenv

load_dotenv()
logger = logging.getLogger(__name__)

genai.configure(api_key=os.getenv("GEMINI_API_KEY"))

SYSTEM_PROMPT = """You are LawBot, the official AI legal assistant for SnapLaw — a Pakistani legal platform.

You are an expert in Pakistani law. You help users by answering any legal question related to Pakistan.
Users may ask in English, Urdu, or Roman Urdu. Always respond in the same language the user uses.

YOUR RULES:
1. ONLY answer questions related to Pakistani law. If someone asks about another country's law, politely say you specialize in Pakistani law only.
2. Always cite specific law names, section numbers, and punishments where applicable.
3. Keep answers clear, simple, and actionable — avoid unnecessary legal jargon.
4. If a question involves multiple legal areas, cover all of them.
5. Always mention what steps the user should take.
6. If you are not sure about something, say so honestly rather than making up information.

YOUR KNOWLEDGE COVERS:
- Pakistan Penal Code (PPC) 1860
- Code of Criminal Procedure (CrPC) 1898
- Code of Civil Procedure (CPC) 1908
- Constitution of Pakistan 1973
- Family Laws: Muslim Family Laws Ordinance 1961, Khula, Divorce, Custody, Maintenance, Mehr
- Property Laws: Transfer of Property Act 1882, Registration Act 1908, Land Revenue Act
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
- Punjab/Sindh/KP/Balochistan specific provincial laws
- Islamic law principles as applied in Pakistani courts (Hudood, Qisas, Diyat)

RESPONSE FORMAT:
- Start with a direct answer to the question
- Cite specific laws with section numbers
- Mention punishments/penalties where relevant
- Give practical steps the user should take
- End with a brief disclaimer that this is AI guidance, not legal advice, and they should consult a qualified lawyer for their specific case

Keep responses focused and helpful. Do not be overly verbose — be concise but thorough."""


_chat_sessions = {}


def chat_with_lawbot(message: str, session_id: str = "default") -> dict:
    """Send a message to LawBot and get a response about Pakistani law."""
    if not message or len(message.strip()) < 3:
        return {
            "response": "Please type your legal question so I can help you.",
            "session_id": session_id,
        }

    if len(message) > 3000:
        message = message[:3000]

    try:
        # Get or create chat session for conversation history
        if session_id not in _chat_sessions:
            model = genai.GenerativeModel(
                model_name="gemini-2.5-flash",
                system_instruction=SYSTEM_PROMPT,
            )
            _chat_sessions[session_id] = model.start_chat(history=[])

        chat = _chat_sessions[session_id]
        response = chat.send_message(message)
        answer = response.text.strip()

        return {
            "response": answer,
            "session_id": session_id,
        }

    except Exception as e:
        logger.error(f"LawBot chat failed: {e}", exc_info=True)
        return {
            "response": f"Sorry, I couldn't process your question right now. Please try again.\n\nError: {str(e)}",
            "session_id": session_id,
            "error": str(e),
        }


def clear_chat_session(session_id: str = "default"):
    """Clear a chat session to start fresh."""
    if session_id in _chat_sessions:
        del _chat_sessions[session_id]
    return {"status": "cleared", "session_id": session_id}
