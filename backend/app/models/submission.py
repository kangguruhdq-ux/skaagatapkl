from datetime import datetime
from sqlalchemy import Column, Integer, String, Text, Float, DateTime, ForeignKey, Boolean
from sqlalchemy.orm import relationship
from app.db.session import Base

class PklSubmission(Base):
    __tablename__ = "pkl_submissions"

    id = Column(Integer, primary_key=True, index=True)
    student_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    company_id = Column(Integer, ForeignKey("company_placements.id"), nullable=True)
    company_name = Column(String(255), nullable=False)
    company_address = Column(Text, nullable=False)
    company_phone = Column(String(50), nullable=True)
    company_email = Column(String(100), nullable=True)
    company_website = Column(String(150), nullable=True)
    industry_sector = Column(String(100), nullable=True)
    division = Column(String(100), nullable=True)
    start_date = Column(String(50), nullable=False)
    end_date = Column(String(50), nullable=False)
    latitude = Column(Float, nullable=True)
    longitude = Column(Float, nullable=True)
    mentor_name = Column(String(255), nullable=True)
    mentor_contact = Column(String(100), nullable=True)
    teacher_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    status = Column(String(50), default="SUBMITTED", index=True) # DRAFT, SUBMITTED, UNDER_REVIEW, APPROVED, REJECTED, REVISION_REQUIRED, CHANGE_REQUESTED
    teacher_notes = Column(Text, nullable=True)
    change_reason = Column(Text, nullable=True)
    previous_company_name = Column(String(255), nullable=True)
    document_url = Column(String(500), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    student = relationship("User", foreign_keys=[student_id])
    teacher = relationship("User", foreign_keys=[teacher_id])
    company = relationship("CompanyPlacement", foreign_keys=[company_id])
    evidences = relationship("PklEvidence", back_populates="submission", cascade="all, delete-orphan")


class PklEvidence(Base):
    __tablename__ = "pkl_evidences"

    id = Column(Integer, primary_key=True, index=True)
    student_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    submission_id = Column(Integer, ForeignKey("pkl_submissions.id"), nullable=True)
    title = Column(String(255), nullable=False)
    category = Column(String(50), nullable=False) # FOTO_KEGIATAN, SURAT, DOKUMEN, SERTIFIKAT, LAPORAN
    file_url = Column(String(500), nullable=False)
    description = Column(Text, nullable=True)
    activity_date = Column(String(50), nullable=True)
    status = Column(String(50), default="UPLOADED", index=True) # UPLOADED, UNDER_REVIEW, VERIFIED, REJECTED, REVISION_REQUIRED
    verifier_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    verifier_notes = Column(Text, nullable=True)
    verified_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    # Relationships
    student = relationship("User", foreign_keys=[student_id])
    verifier = relationship("User", foreign_keys=[verifier_id])
    submission = relationship("PklSubmission", back_populates="evidences")
