from datetime import datetime
from sqlalchemy import Column, Integer, String, Float, Boolean, DateTime, ForeignKey, Text
from sqlalchemy.orm import relationship
from app.db.session import Base

class CompanyPlacement(Base):
    __tablename__ = "company_placements"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=False) # e.g. PT Telkom Indonesia Tbk
    division = Column(String(255), nullable=True) # Witel Yogyakarta • Network Ops & Maintenance
    address = Column(Text, nullable=False) # Jl. Yos Sudarso No.9 Kotabaru
    latitude = Column(Float, nullable=False, default=-7.78542)
    longitude = Column(Float, nullable=False, default=110.37219)
    geofence_radius = Column(Float, nullable=False, default=100.0) # meters
    mentor_name = Column(String(255), nullable=True) # Ir. Bambang Hermanto, S.T.
    mentor_phone = Column(String(50), nullable=True)
    supervisor_name = Column(String(255), nullable=True) # Dra. Sri Wahyuningsih, M.Pd.
    supervisor_phone = Column(String(50), nullable=True)
    period_start = Column(String(50), nullable=True) # 15 Jul 2024
    period_end = Column(String(50), nullable=True) # 15 Des 2024
    total_weeks = Column(Integer, default=22)
    current_week = Column(Integer, default=14)
    code = Column(String(50), default="PKL-TKJ-2024")
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    assignments = relationship("PlacementAssignment", back_populates="company")
    attendances = relationship("AttendanceRecord", back_populates="placement")
    journals = relationship("DailyJournal", back_populates="placement")

class PlacementAssignment(Base):
    __tablename__ = "placement_assignments"

    id = Column(Integer, primary_key=True, index=True)
    student_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    placement_id = Column(Integer, ForeignKey("company_placements.id"), nullable=False)
    status = Column(String(50), default="ACTIVE") # ACTIVE, COMPLETED, SUSPENDED
    assigned_at = Column(DateTime, default=datetime.utcnow)

    student = relationship("User", back_populates="placements")
    company = relationship("CompanyPlacement", back_populates="assignments")
