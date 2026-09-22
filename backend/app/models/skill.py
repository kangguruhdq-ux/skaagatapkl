from datetime import datetime
from sqlalchemy import Column, Integer, String, Float, Boolean, DateTime, ForeignKey, Text
from app.db.session import Base

class SkillCompetency(Base):
    __tablename__ = "skill_competencies"

    id = Column(Integer, primary_key=True, index=True)
    student_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    name = Column(String(255), nullable=False) # e.g. Python Scripting
    category = Column(String(100), nullable=False) # e.g. Automation, Infrastructure
    industry_demand_pct = Column(Float, nullable=False) # 91.0
    student_mastery_pct = Column(Float, nullable=False) # 45.0
    gap_percentage = Column(Float, nullable=False) # -46.0
    status = Column(String(50), nullable=False) # GAP, SURPLUS, MATCH
    recommendation = Column(Text, nullable=False)
    audit_tier = Column(String(50), default="SUPERVISOR") # AI_DETECTED, SUPERVISOR, SMKN 3
    skkni_code = Column(String(100), nullable=True) # J.611000.005.01
    validated_units = Column(Integer, default=1)
    evidence_logs_count = Column(Integer, default=4)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
