from sqlalchemy import create_engine, Column, Integer, String, Text, DateTime, Float
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from datetime import datetime

DATABASE_URL = "sqlite:///./citizen_snaplaw.db"

engine = create_engine(DATABASE_URL, connect_args={"check_same_thread": False})
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()


class GuidanceArticle(Base):
    __tablename__ = "guidance_articles"
    id = Column(Integer, primary_key=True, index=True)
    category = Column(String, index=True)
    title = Column(String)
    content = Column(Text)
    relevant_law = Column(String)
    created_at = Column(DateTime, default=datetime.utcnow)


class JusticeStat(Base):
    __tablename__ = "justice_stats"
    id = Column(Integer, primary_key=True, index=True)
    court_type = Column(String)
    city = Column(String)
    total_pending_cases = Column(Integer)
    avg_resolution_days = Column(Integer)
    cases_resolved_this_month = Column(Integer)
    cases_filed_this_month = Column(Integer)
    last_updated = Column(DateTime, default=datetime.utcnow)


class CaseTypeStat(Base):
    __tablename__ = "case_type_stats"
    id = Column(Integer, primary_key=True, index=True)
    case_type = Column(String)
    avg_days_to_resolve = Column(Integer)
    success_rate_percent = Column(Integer)
    total_cases_2023 = Column(Integer)


class QuizQuestion(Base):
    __tablename__ = "quiz_questions"
    id = Column(Integer, primary_key=True, index=True)
    level = Column(Integer, index=True)
    question = Column(Text)
    option_a = Column(String)
    option_b = Column(String)
    option_c = Column(String)
    option_d = Column(String)
    correct_answer = Column(String)  # 'a', 'b', 'c', or 'd'
    explanation = Column(Text)
    category = Column(String)


class FAQ(Base):
    __tablename__ = "faqs"
    id = Column(Integer, primary_key=True, index=True)
    question = Column(Text)
    answer = Column(Text)
    category = Column(String)


def init_db():
    Base.metadata.create_all(bind=engine)


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
