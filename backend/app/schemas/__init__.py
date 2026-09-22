from app.schemas.common import ApiResponse, ApiErrorResponse, ErrorDetail
from app.schemas.auth import LoginRequest, RegisterRequest, RefreshTokenRequest, TokenResponse, UserResponse, DapodikVerificationResponse
from app.schemas.dashboard import DashboardSummaryResponse, PlacementInfo, UrgentAlert, QuickTelemetrySummary
from app.schemas.attendance import CheckInRequest, CheckOutRequest, AttendanceResponse, AttendanceStatusResponse
from app.schemas.journal import JournalCreate, JournalUpdate, JournalResponse, AiAnalysisRequest, AiAnalysisResponse, EvidenceResponse
from app.schemas.skill import SkillCompetencyResponse, IndustryGapSummary
from app.schemas.notification import NotificationResponse

__all__ = [
    "ApiResponse",
    "ApiErrorResponse",
    "ErrorDetail",
    "LoginRequest",
    "RegisterRequest",
    "RefreshTokenRequest",
    "TokenResponse",
    "UserResponse",
    "DapodikVerificationResponse",
    "DashboardSummaryResponse",
    "PlacementInfo",
    "UrgentAlert",
    "QuickTelemetrySummary",
    "CheckInRequest",
    "CheckOutRequest",
    "AttendanceResponse",
    "AttendanceStatusResponse",
    "JournalCreate",
    "JournalUpdate",
    "JournalResponse",
    "AiAnalysisRequest",
    "AiAnalysisResponse",
    "EvidenceResponse",
    "SkillCompetencyResponse",
    "IndustryGapSummary",
    "NotificationResponse",
]
