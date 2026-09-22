from datetime import datetime
from sqlalchemy import Column, Integer, String, Float, Boolean, DateTime, ForeignKey, Text
from sqlalchemy.orm import relationship
from app.db.session import Base

class DailyJournal(Base):
    __tablename__ = "daily_journals"

    id = Column(Integer, primary_key=True, index=True)
    student_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    placement_id = Column(Integer, ForeignKey("company_placements.id"), nullable=False)
    date = Column(String(50), nullable=False) # e.g. 2024-10-19
    day_number = Column(Integer, default=58)
    hours_spent = Column(Float, default=8.5)
    work_summary = Column(Text, nullable=False)
    standard_competency = Column(String(255), default="Admin Jaringan Lv. 2")
    competency_category = Column(String(100), default="SKKNI Kategori J.61")
    complexity_level = Column(String(50), default="INTERMEDIATE")
    complexity_tier = Column(String(100), default="Tier: Teknisi Madya")
    ai_match_percentage = Column(Float, default=98.6)
    ai_extracted_skills = Column(Text, nullable=True) # JSON encoded
    detected_tools = Column(Text, nullable=True) # JSON encoded
    workflow_stage = Column(Integer, default=4) # 1: Draft, 2: Submit, 3: AI Sync, 4: Review, 5: Approved
    status = Column(String(50), default="REVIEW") # DRAFT, SUBMITTED, AI_SYNC, REVIEW, APPROVED, REVISION_REQUIRED
    revision_notes = Column(Text, nullable=True)
    is_urgent_revision = Column(Boolean, default=False)
    reviewer_name = Column(String(255), default="Ir. Bambang Hermanto, S.T.")
    reviewed_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    student = relationship("User", back_populates="journals")
    placement = relationship("CompanyPlacement", back_populates="journals")
    attachments = relationship("EvidenceAttachment", back_populates="journal", cascade="all, delete-orphan")

class EvidenceAttachment(Base):
    __tablename__ = "evidence_attachments"

    id = Column(Integer, primary_key=True, index=True)
    journal_id = Column(Integer, ForeignKey("daily_journals.id"), nullable=True)
    student_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    file_name = Column(String(255), nullable=False)
    file_path = Column(String(500), nullable=False)
    file_type = Column(String(50), nullable=False) # image/png, application/pdf
    file_size_bytes = Column(Integer, default=0)
    uploaded_at = Column(DateTime, default=datetime.utcnow)

    journal = relationship("DailyJournal", back_populates="attachments")
