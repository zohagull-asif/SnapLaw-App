"""
Vault Storage — SQLite database for encrypted file metadata and data.
"""

from sqlalchemy import (
    create_engine, Column, String, Integer,
    DateTime, Boolean, LargeBinary, Text
)
from sqlalchemy.orm import declarative_base, sessionmaker
from datetime import datetime
import uuid
import os
import logging

logger = logging.getLogger(__name__)

# Store vault DB in backend directory
DB_PATH = os.path.join(os.path.dirname(os.path.dirname(__file__)), "snaplaw_vault.db")
SQLALCHEMY_DATABASE_URL = f"sqlite:///{DB_PATH}"

engine = create_engine(
    SQLALCHEMY_DATABASE_URL,
    connect_args={"check_same_thread": False}
)
SessionLocal = sessionmaker(bind=engine)
Base = declarative_base()


class VaultFile(Base):
    __tablename__ = "vault_files"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String, nullable=False, index=True)
    filename = Column(String, nullable=False)
    original_filename = Column(String, nullable=False)
    file_type = Column(String, nullable=False)
    file_size = Column(Integer, nullable=False)
    category = Column(String, default="General")
    description = Column(Text, default="")
    encrypted_data = Column(LargeBinary, nullable=False)
    encryption_salt = Column(String, nullable=False)
    share_token = Column(String, nullable=True)
    share_expires_at = Column(DateTime, nullable=True)
    uploaded_at = Column(DateTime, default=datetime.utcnow)
    is_deleted = Column(Boolean, default=False)


# Create tables
Base.metadata.create_all(bind=engine)
logger.info(f"Vault database initialized at {DB_PATH}")


def get_vault_db():
    """Get a database session."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


CATEGORIES = [
    "Property", "Family", "Criminal", "Employment",
    "Contract", "Court Orders", "FIR", "General"
]
