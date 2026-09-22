from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.models.user import User, UserRole
from app.models.placement import CompanyPlacement, PlacementAssignment
from app.models.attendance import AttendanceRecord
from app.models.journal import DailyJournal
from app.schemas.common import ApiResponse
from app.schemas.dashboard import (
    DashboardSummaryResponse,
    PlacementInfo,
    UrgentAlert,
    QuickTelemetrySummary,
)
from app.api.deps import get_current_user

router = APIRouter()

@router.get("/summary", response_model=ApiResponse[DashboardSummaryResponse])
def get_dashboard_summary(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if current_user.role != UserRole.SISWA:
        raise HTTPException(403, 'Dashboard Intelligence Hub hanya tersedia untuk data akun siswa sendiri.')
    student = current_user
    # Fetch placement assignment
    assignment = db.query(PlacementAssignment).filter(
        PlacementAssignment.student_id == student.id,
        PlacementAssignment.status == "ACTIVE"
    ).first()

    company = None
    if assignment and assignment.placement_id:
        company = db.query(CompanyPlacement).filter(CompanyPlacement.id == assignment.placement_id).first()
    if not company:
        from app.models.submission import PklSubmission
        approved_sub = db.query(PklSubmission).filter(
            PklSubmission.student_id == student.id,
            PklSubmission.status == "APPROVED"
        ).order_by(PklSubmission.updated_at.desc()).first()
        if approved_sub and approved_sub.company_id:
            company = db.query(CompanyPlacement).filter(CompanyPlacement.id == approved_sub.company_id).first()

    placement_info = None
    if company:
        supervisor_name = company.supervisor_name or "Guru Pembimbing"
        placement_info = PlacementInfo(
            id=company.id,
            company_name=company.name,
            division=company.division or "-",
            address=company.address or "-",
            mentor_name=company.mentor_name or "Pembimbing DUDI",
            supervisor_name=supervisor_name,
            period_string=f"{company.period_start or 'Mulai'} – {company.period_end or 'Selesai'}",
            current_week=company.current_week or 1,
            total_weeks=company.total_weeks or 12,
            progress_pct=int((company.current_week / company.total_weeks) * 100) if company.total_weeks else 0,
            status="Active Placement"
        )

    # Check urgent journal revision
    urgent_journal = db.query(DailyJournal).filter(
        DailyJournal.student_id == student.id,
        DailyJournal.is_urgent_revision == True
    ).first()

    urgent_alert = None
    if urgent_journal:
        urgent_alert = UrgentAlert(
            id=urgent_journal.id,
            title="Perlu Tindakan: Revisi Jurnal",
            badge_label="Urgent",
            notes=urgent_journal.revision_notes or "Harap periksa catatan revisi jurnal Anda.",
            action_label="Buka Revisi",
            target_route=f"/journal/{urgent_journal.id}",
            journal_id=urgent_journal.id
        )

    # Attendance telemetry metrics
    attendances = db.query(AttendanceRecord).filter(AttendanceRecord.student_id == student.id).all()
    present_days = sum(1 for a in attendances if a.status == "HADIR" and a.approval_status == "APPROVED")
    permitted_days = sum(1 for a in attendances if a.status in ["IZIN", "SAKIT"] and a.approval_status == "APPROVED")
    alpha_days = sum(1 for a in attendances if a.status == "ALPA" and a.approval_status == "APPROVED")
    total_records = len(attendances)
    attendance_rate = round((present_days / total_records) * 100, 1) if total_records else 0.0

    last_att = attendances[-1] if attendances else None
    last_distance = last_att.distance_meters if last_att else 0.0
    in_geofence = last_att.is_in_radius if last_att else False

    telemetry = QuickTelemetrySummary(
        attendance_rate_pct=attendance_rate,
        total_present_days=present_days,
        permitted_days=permitted_days,
        alpha_days=alpha_days,
        last_gps_distance_meters=last_distance,
        is_in_geofence=in_geofence
    )

    active_tasks = db.query(DailyJournal).filter(DailyJournal.student_id == student.id, DailyJournal.status.in_(["SUBMITTED", "REVIEW", "REVISION_REQUIRED"])).count()
    draft_journals = db.query(DailyJournal).filter(
        DailyJournal.student_id == student.id,
        DailyJournal.status == "DRAFT"
    ).count()

    return ApiResponse(
        success=True,
        data=DashboardSummaryResponse(
            student_id=student.id,
            student_name=student.full_name,
            nisn=student.username,
            student_class=student.student_class or "-",
            department=student.department or "-",
            avatar_url=student.avatar_url,
            is_telemetry_online=True,
            placement=placement_info,
            urgent_alert=urgent_alert,
            telemetry_strip=telemetry,
            active_tasks_count=active_tasks,
            draft_journals_count=draft_journals
        ),
        message="Data Intelligence Hub berhasil disinkronisasi."
    )
