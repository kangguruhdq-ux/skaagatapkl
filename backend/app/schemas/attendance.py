from typing import Optional
from datetime import datetime
from pydantic import BaseModel

class CheckInRequest(BaseModel):
    latitude: float
    longitude: float
    accuracy_meters: Optional[float] = 4.2
    device_fingerprint: Optional[str] = "SKGT-DEV-8842"
    notes: Optional[str] = "Presensi mandiri biometrik terverifikasi"
    selfie_url: Optional[str] = None

class CheckOutRequest(BaseModel):
    latitude: float
    longitude: float
    accuracy_meters: Optional[float] = 4.2
    notes: Optional[str] = "Selesai jam kerja harian"

class AttendanceReviewRequest(BaseModel):
    action: str # APPROVE or REJECT
    notes: Optional[str] = None

class AttendanceResponse(BaseModel):
    id: int
    student_id: int
    placement_id: int
    date: str
    check_in_time: Optional[datetime] = None
    check_out_time: Optional[datetime] = None
    latitude: float
    longitude: float
    distance_meters: float
    is_in_radius: bool
    accuracy_meters: float
    mock_location_detected: bool
    device_fingerprint: str
    status: str
    notes: Optional[str] = None
    shift_name: str
    verified_by_mentor: bool
    selfie_url: Optional[str] = None
    approval_status: Optional[str] = "PENDING"
    student_name: Optional[str] = None
    student_nisn: Optional[str] = None

    class Config:
        from_attributes = True

class AttendanceStatusResponse(BaseModel):
    has_checked_in_today: bool
    has_checked_out_today: bool
    today_record: Optional[AttendanceResponse] = None
    target_latitude: float
    target_longitude: float
    geofence_radius: float
    company_name: str
    shift_name: str = "Shift Reguler Pagi (08:00 - 16:30 WIB)"
    total_days_attended: int = 0
    total_days_permitted: int = 0
    total_days_alpha: int = 0
    attendance_rate_pct: float = 0.0
