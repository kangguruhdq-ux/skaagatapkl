from datetime import datetime
from sqlalchemy import Column, Integer, String, Float, Boolean, DateTime, ForeignKey, Text
from sqlalchemy.orm import relationship
from app.db.session import Base

class AttendanceRecord(Base):
    __tablename__ = "attendance_records"

    id = Column(Integer, primary_key=True, index=True)
    student_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    placement_id = Column(Integer, ForeignKey("company_placements.id"), nullable=False)
    date = Column(String(20), nullable=False) # YYYY-MM-DD
    check_in_time = Column(DateTime, nullable=True)
    check_out_time = Column(DateTime, nullable=True)
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    distance_meters = Column(Float, nullable=False)
    is_in_radius = Column(Boolean, default=True)
    accuracy_meters = Column(Float, default=4.2)
    mock_location_detected = Column(Boolean, default=False)
    device_fingerprint = Column(String(100), default="SKGT-DEV-8842")
    status = Column(String(50), default="HADIR") # HADIR, IZIN, SAKIT, ALPA
    notes = Column(Text, nullable=True)
    shift_name = Column(String(100), default="Shift Reguler Pagi (08:00 - 16:30 WIB)")
    selfie_url = Column(String(255), nullable=True)
    approval_status = Column(String(50), default="PENDING") # PENDING, APPROVED, REJECTED
    verified_by_mentor = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    student = relationship("User", back_populates="attendances")
    placement = relationship("CompanyPlacement", back_populates="attendances")
