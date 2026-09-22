from typing import Optional, List
from pydantic import BaseModel
from app.schemas.journal import JournalResponse
from app.schemas.attendance import AttendanceResponse

class PlacementInfo(BaseModel):
    id: int
    company_name: str
    division: Optional[str] = ""
    address: str
    mentor_name: Optional[str] = ""
    supervisor_name: Optional[str] = ""
    period_string: str
    current_week: int
    total_weeks: int
    progress_pct: int
    status: str

class UrgentAlert(BaseModel):
    id: int
    title: str
    badge_label: str
    notes: str
    action_label: str
    target_route: str
    journal_id: Optional[int] = None

class QuickTelemetrySummary(BaseModel):
    attendance_rate_pct: float
    total_present_days: int
    permitted_days: int
    alpha_days: int
    last_gps_distance_meters: float
    is_in_geofence: bool

class DashboardSummaryResponse(BaseModel):
    student_id: int
    student_name: str
    nisn: str
    student_class: str
    department: str
    avatar_url: Optional[str] = None
    is_telemetry_online: bool = True
    placement: Optional[PlacementInfo] = None
    urgent_alert: Optional[UrgentAlert] = None
    telemetry_strip: QuickTelemetrySummary
    active_tasks_count: int = 0
    draft_journals_count: int = 0
