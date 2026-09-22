import enum
from datetime import datetime
from sqlalchemy import Column, Integer, String, Boolean, DateTime, Enum, Text
from sqlalchemy.orm import relationship
from app.db.session import Base

class UserRole(str, enum.Enum):
    SISWA = "siswa"
    GURU = "guru"
    MITRA = "mitra"
    ADMIN = "admin"

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(100), unique=True, index=True, nullable=False) # NISN, NIP, or Partner ID
    email = Column(String(255), unique=True, index=True, nullable=True)
    full_name = Column(String(255), nullable=False)
    hashed_password = Column(String(255), nullable=False)
    role = Column(Enum(UserRole), default=UserRole.SISWA, nullable=False)
    department = Column(String(150), nullable=True) # Jurusan
    student_class = Column(String(50), nullable=True) # e.g. XII TKJ 1
    phone = Column(String(50), nullable=True)
    avatar_url = Column(String(500), nullable=True)
    device_id = Column(String(100), nullable=True) # SKGT-DEV-8842
    device_model = Column(String(100), nullable=True) # Samsung Galaxy A54 5G
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    attendances = relationship("AttendanceRecord", back_populates="student", foreign_keys="AttendanceRecord.student_id")
    journals = relationship("DailyJournal", back_populates="student", foreign_keys="DailyJournal.student_id")
    notifications = relationship("NotificationItem", back_populates="user")
    placements = relationship("PlacementAssignment", back_populates="student")
