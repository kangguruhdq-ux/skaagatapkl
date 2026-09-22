from datetime import datetime
from sqlalchemy import Column, Integer, String, Text, DateTime, ForeignKey
from app.db.session import Base

class JournalHistory(Base):
    __tablename__ = "journal_history"
    id = Column(Integer, primary_key=True)
    journal_id = Column(Integer, ForeignKey("daily_journals.id"), nullable=False, index=True)
    previous_status = Column(String(50), nullable=True)
    new_status = Column(String(50), nullable=False)
    actor_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    reviewer = Column(String(255), nullable=False)
    comment = Column(Text, nullable=True)
    timestamp = Column(DateTime, default=datetime.utcnow, nullable=False)
