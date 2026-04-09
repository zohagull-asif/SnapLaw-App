"""SnapLaw Citizen Portal — FastAPI backend on port 8003."""
import os
from fastapi import FastAPI, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse, HTMLResponse
from sqlalchemy.orm import Session
from sqlalchemy import func
from dotenv import load_dotenv

from citizen_db import init_db, get_db, GuidanceArticle, JusticeStat, CaseTypeStat, QuizQuestion, FAQ

load_dotenv()

app = FastAPI(title="SnapLaw Citizen Portal", version="1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

CATEGORY_META = {
    "marriage_family":    {"label": "Marriage & Family", "icon": "👫", "color": "#e74c3c"},
    "property_rights":    {"label": "Property Rights",   "icon": "🏠", "color": "#3498db"},
    "cybercrime_online":  {"label": "Cybercrime & Online","icon": "💻","color": "#9b59b6"},
    "harassment_rights":  {"label": "Harassment Rights", "icon": "⚠️", "color": "#e67e22"},
    "labor_employment":   {"label": "Labor & Employment","icon": "💼", "color": "#27ae60"},
    "criminal_justice":   {"label": "Criminal Justice",  "icon": "⚖️", "color": "#2c3e50"},
}

LEVEL_META = [
    {"level": 1, "name": "Beginner",  "color": "#27ae60", "emoji": "🟢"},
    {"level": 2, "name": "Easy",      "color": "#f1c40f", "emoji": "🟡"},
    {"level": 3, "name": "Medium",    "color": "#e67e22", "emoji": "🟠"},
    {"level": 4, "name": "Hard",      "color": "#e74c3c", "emoji": "🔴"},
    {"level": 5, "name": "Expert",    "color": "#9b59b6", "emoji": "🟣"},
]


@app.on_event("startup")
def startup():
    init_db()
    # Auto-seed if empty
    db = next(get_db())
    if db.query(GuidanceArticle).count() == 0:
        import seed_data
        seed_data.seed_all()
    db.close()
    print("🚀 CITIZEN MODULES READY on http://localhost:8003")


# ─── Serve UI ───
@app.get("/", response_class=HTMLResponse)
def serve_ui():
    path = os.path.join(os.path.dirname(__file__), "citizen_ui.html")
    with open(path, "r", encoding="utf-8") as f:
        return f.read()


# ─── Health ───
@app.get("/health")
def health():
    return {"status": "ok", "service": "SnapLaw Citizen Portal"}


# ════════════════════════════════════════
# MODULE 1 — GUIDANCE LAWS
# ════════════════════════════════════════

@app.get("/api/guidance/categories")
def get_categories(db: Session = Depends(get_db)):
    rows = db.query(GuidanceArticle.category, func.count(GuidanceArticle.id).label("count"))\
             .group_by(GuidanceArticle.category).all()
    result = []
    for cat, count in rows:
        meta = CATEGORY_META.get(cat, {"label": cat, "icon": "📄", "color": "#666"})
        result.append({"key": cat, "label": meta["label"], "icon": meta["icon"],
                        "color": meta["color"], "article_count": count})
    return result


@app.get("/api/guidance/articles/{category}")
def get_articles_by_category(category: str, db: Session = Depends(get_db)):
    articles = db.query(GuidanceArticle).filter(GuidanceArticle.category == category).all()
    return [{"id": a.id, "title": a.title, "content": a.content,
             "relevant_law": a.relevant_law, "category": a.category} for a in articles]


@app.get("/api/guidance/article/{article_id}")
def get_article(article_id: int, db: Session = Depends(get_db)):
    a = db.query(GuidanceArticle).filter(GuidanceArticle.id == article_id).first()
    if not a:
        raise HTTPException(status_code=404, detail="Article not found")
    return {"id": a.id, "title": a.title, "content": a.content,
            "relevant_law": a.relevant_law, "category": a.category}


@app.get("/api/guidance/articles/all")
def get_all_articles(db: Session = Depends(get_db)):
    articles = db.query(GuidanceArticle).all()
    return [{"id": a.id, "title": a.title, "content": a.content,
             "relevant_law": a.relevant_law, "category": a.category} for a in articles]


# ════════════════════════════════════════
# MODULE 2 — JUSTICE TRACKER
# ════════════════════════════════════════

@app.get("/api/justice/courts")
def get_courts(db: Session = Depends(get_db)):
    courts = db.query(JusticeStat).all()
    result = []
    for c in courts:
        if c.total_pending_cases < 20000:
            status = "Manageable"
            status_color = "#27ae60"
        elif c.total_pending_cases < 100000:
            status = "Backlogged"
            status_color = "#f39c12"
        else:
            status = "Severely Backlogged"
            status_color = "#e74c3c"

        result.append({
            "id": c.id, "court_type": c.court_type, "city": c.city,
            "total_pending_cases": c.total_pending_cases,
            "avg_resolution_days": c.avg_resolution_days,
            "cases_resolved_this_month": c.cases_resolved_this_month,
            "cases_filed_this_month": c.cases_filed_this_month,
            "status": status, "status_color": status_color,
        })
    return result


@app.get("/api/justice/case-types")
def get_case_types(db: Session = Depends(get_db)):
    types = db.query(CaseTypeStat).all()
    MAX_DAYS = 900
    result = []
    for t in types:
        pct = min(100, int(t.avg_days_to_resolve / MAX_DAYS * 100))
        if t.avg_days_to_resolve < 365:
            bar_color = "#27ae60"
        elif t.avg_days_to_resolve < 730:
            bar_color = "#f39c12"
        else:
            bar_color = "#e74c3c"
        result.append({
            "id": t.id, "case_type": t.case_type,
            "avg_days_to_resolve": t.avg_days_to_resolve,
            "success_rate_percent": t.success_rate_percent,
            "total_cases_2023": t.total_cases_2023,
            "bar_percent": pct, "bar_color": bar_color,
        })
    return result


@app.get("/api/justice/summary")
def get_summary(db: Session = Depends(get_db)):
    courts = db.query(JusticeStat).all()
    total_pending = sum(c.total_pending_cases for c in courts)
    total_resolved = sum(c.cases_resolved_this_month for c in courts)
    avg_days = int(sum(c.avg_resolution_days for c in courts) / len(courts)) if courts else 0
    return {
        "total_pending_cases": total_pending,
        "courts_tracked": len(courts),
        "avg_resolution_days": avg_days,
        "total_resolved_this_month": total_resolved,
    }


# ════════════════════════════════════════
# MODULE 3 — QUIZ
# ════════════════════════════════════════

@app.get("/api/quiz/levels")
def get_levels():
    return LEVEL_META


@app.get("/api/quiz/questions/{level}")
def get_questions(level: int, db: Session = Depends(get_db)):
    if level == 0:  # special: all
        qs = db.query(QuizQuestion).all()
    else:
        qs = db.query(QuizQuestion).filter(QuizQuestion.level == level).all()
    return [{
        "id": q.id, "level": q.level, "question": q.question,
        "option_a": q.option_a, "option_b": q.option_b,
        "option_c": q.option_c, "option_d": q.option_d,
        "correct_answer": q.correct_answer, "explanation": q.explanation,
        "category": q.category,
    } for q in qs]


@app.get("/api/quiz/questions/all")
def get_all_questions(db: Session = Depends(get_db)):
    qs = db.query(QuizQuestion).all()
    return [{
        "id": q.id, "level": q.level, "question": q.question,
        "option_a": q.option_a, "option_b": q.option_b,
        "option_c": q.option_c, "option_d": q.option_d,
        "correct_answer": q.correct_answer, "explanation": q.explanation,
        "category": q.category,
    } for q in qs]


# ════════════════════════════════════════
# MODULE 4 — FAQs
# ════════════════════════════════════════

@app.get("/api/faqs")
def get_faqs(db: Session = Depends(get_db)):
    faqs = db.query(FAQ).all()
    return [{"id": f.id, "question": f.question, "answer": f.answer,
             "category": f.category} for f in faqs]


@app.get("/api/faqs/{faq_id}")
def get_faq(faq_id: int, db: Session = Depends(get_db)):
    f = db.query(FAQ).filter(FAQ.id == faq_id).first()
    if not f:
        raise HTTPException(status_code=404, detail="FAQ not found")
    return {"id": f.id, "question": f.question, "answer": f.answer, "category": f.category}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8003)
