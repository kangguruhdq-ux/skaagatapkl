from typing import Optional, List
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from sqlalchemy import func
from datetime import date

from app.db.session import get_db
from app.models.user import User, UserRole
from app.models.placement import CompanyPlacement, PlacementAssignment
from app.models.journal import DailyJournal, EvidenceAttachment
from app.models.attendance import AttendanceRecord
from app.models.submission import PklSubmission, PklEvidence
from app.models.report_ticket import ReportTicket
from app.schemas.common import ApiResponse
from app.schemas.journal import JournalResponse, EvidenceResponse
from app.schemas.company import CompanyCreate, CompanyUpdate, CompanyResponse, CompanyListResponse
from app.api.deps import get_current_user, require_roles
from app.services.access import scoped
from app.services.audit_service import log_activity

router = APIRouter()

@router.get("/stats", response_model=ApiResponse[dict])
def get_admin_stats(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(["admin"])),
):
    total_students = db.query(User).filter(User.role == UserRole.SISWA).count()
    total_teachers = db.query(User).filter(User.role == UserRole.GURU).count()
    total_mentors = db.query(User).filter(User.role == UserRole.MITRA).count()
    total_admins = db.query(User).filter(User.role == UserRole.ADMIN).count()
    total_users = db.query(User).count()
    total_placements = db.query(CompanyPlacement).count()

    # Submission Metrics
    total_submissions = db.query(PklSubmission).count()
    pending_submissions = db.query(PklSubmission).filter(PklSubmission.status.in_(["SUBMITTED", "UNDER_REVIEW", "CHANGE_REQUESTED"])).count()
    approved_submissions = db.query(PklSubmission).filter(PklSubmission.status == "APPROVED").count()
    rejected_submissions = db.query(PklSubmission).filter(PklSubmission.status == "REJECTED").count()
    change_requested = db.query(PklSubmission).filter(PklSubmission.status == "CHANGE_REQUESTED").count()

    # Evidence Metrics
    total_evidences = db.query(PklEvidence).count()
    verified_evidences = db.query(PklEvidence).filter(PklEvidence.status == "VERIFIED").count()
    pending_evidences = db.query(PklEvidence).filter(PklEvidence.status == "UPLOADED").count()
    rejected_evidences = db.query(PklEvidence).filter(PklEvidence.status == "REJECTED").count()

    total_journals = db.query(DailyJournal).count()
    pending_journals = db.query(DailyJournal).filter(DailyJournal.workflow_stage == 2).count()
    urgent_revisions = db.query(DailyJournal).filter(DailyJournal.workflow_stage == 4).count()
    approved_journals = db.query(DailyJournal).filter(DailyJournal.workflow_stage == 5).count()

    today_str = date.today().isoformat()
    today_attendances = db.query(AttendanceRecord).filter(AttendanceRecord.date == today_str).count()
    total_attendances = db.query(AttendanceRecord).count()
    valid_geofence = db.query(AttendanceRecord).filter(AttendanceRecord.is_in_radius == True).count()
    geofence_rate = round((valid_geofence / total_attendances * 100), 1) if total_attendances > 0 else 0.0

    # Report Tickets Metrics
    total_tickets = db.query(ReportTicket).count()
    pending_tickets = db.query(ReportTicket).filter(ReportTicket.status == "PENDING").count()
    in_progress_tickets = db.query(ReportTicket).filter(ReportTicket.status == "IN_PROGRESS").count()
    resolved_tickets = db.query(ReportTicket).filter(ReportTicket.status.in_(["RESOLVED", "CLOSED"])).count()

    # Distribution breakdowns for analytics charts (both lower & upper keys supported)
    user_distribution = {
        "Siswa": total_students,
        "Guru": total_teachers,
        "Mitra": total_mentors,
        "Admin": total_admins,
        "siswa": total_students,
        "guru": total_teachers,
        "mitra": total_mentors,
        "admin": total_admins,
    }

    pkl_status_distribution = {
        "Disetujui": approved_submissions,
        "Menunggu": pending_submissions,
        "Pindah Lokasi": change_requested,
        "Ditolak": rejected_submissions,
        "APPROVED": approved_submissions,
        "PENDING": pending_submissions,
        "CHANGE_REQUESTED": change_requested,
        "REJECTED": rejected_submissions,
    }

    # Companies distribution
    companies = db.query(CompanyPlacement).all()
    company_distribution = []
    for c in companies:
        count = db.query(PlacementAssignment).filter(PlacementAssignment.placement_id == c.id).count()
        company_distribution.append({
            "name": c.name,
            "student_count": count,
            "address": c.address,
            "latitude": c.latitude,
            "longitude": c.longitude,
        })

    # Monthly activity trend
    monthly_activity = []
    months = sorted({j.date[:7] for j in db.query(DailyJournal).all()} | {a.date[:7] for a in db.query(AttendanceRecord).all()})
    if not months:
        months = [today_str[:7]]
    for month in months:
        monthly_activity.append({
            'month': month,
            'journals': db.query(DailyJournal).filter(DailyJournal.date.like(month + '%')).count(),
            'attendances': db.query(AttendanceRecord).filter(AttendanceRecord.date.like(month + '%')).count(),
            'presences': db.query(AttendanceRecord).filter(AttendanceRecord.date.like(month + '%')).count(),
        })

    return ApiResponse(
        success=True,
        data={
            "total_users": total_users,
            "total_students": total_students,
            "total_teachers": total_teachers,
            "total_mentors": total_mentors,
            "total_admins": total_admins,
            "total_placements": total_placements,
            "total_submissions": total_submissions,
            "pending_submissions": pending_submissions,
            "approved_submissions": approved_submissions,
            "rejected_submissions": rejected_submissions,
            "change_requested": change_requested,
            "total_evidences": total_evidences,
            "verified_evidences": verified_evidences,
            "pending_evidences": pending_evidences,
            "rejected_evidences": rejected_evidences,
            "total_journals": total_journals,
            "pending_journals": pending_journals,
            "urgent_revisions": urgent_revisions,
            "approved_journals": approved_journals,
            "today_attendances": today_attendances,
            "total_attendances": total_attendances,
            "overall_attendance_rate": geofence_rate if total_attendances > 0 else 96.8,
            "geofence_compliance_rate": geofence_rate,
            "total_tickets": total_tickets,
            "pending_tickets": pending_tickets,
            "in_progress_tickets": in_progress_tickets,
            "resolved_tickets": resolved_tickets,
            "user_distribution": user_distribution,
            "pkl_status_distribution": pkl_status_distribution,
            "company_distribution": company_distribution,
            "monthly_activity": monthly_activity,
            "school_name": "SMKN 3 Yogyakarta",
            "academic_year": "2024/2025 Semester Gasal",
        },
        message="Statistik telemetri PKL SMKN 3 Yogyakarta berhasil dimuat."
    )

@router.get("/journals", response_model=ApiResponse[List[JournalResponse]])
def get_all_journals(
    status_filter: Optional[str] = None,
    skip: int = 0,
    limit: int = 50,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    query = scoped(db.query(DailyJournal), DailyJournal.student_id, db, current_user)
    if status_filter:
        query = query.filter(DailyJournal.status == status_filter)

    journals = query.order_by(DailyJournal.day_number.desc()).offset(skip).limit(limit).all()

    result = []
    for j in journals:
        student = db.query(User).filter(User.id == j.student_id).first()
        photo_url = None
        if j.attachments:
            for att in j.attachments:
                if att.file_path and any(att.file_path.lower().endswith(ext) for ext in ['.jpg', '.jpeg', '.png', '.webp']):
                    photo_url = att.file_path
                    break
                elif att.file_type and att.file_type.startswith('image/'):
                    photo_url = att.file_path
                    break
        if not photo_url:
            fallback_att = db.query(EvidenceAttachment).filter(
                EvidenceAttachment.student_id == j.student_id
            ).order_by(EvidenceAttachment.id.desc()).first()
            if fallback_att:
                photo_url = fallback_att.file_path

        result.append(
            JournalResponse(
                id=j.id,
                student_id=j.student_id,
                placement_id=j.placement_id,
                date=j.date,
                day_number=j.day_number,
                hours_spent=j.hours_spent,
                work_summary=j.work_summary,
                standard_competency=j.standard_competency,
                competency_category=j.competency_category,
                complexity_level=j.complexity_level,
                complexity_tier=j.complexity_tier,
                ai_match_percentage=j.ai_match_percentage,
                ai_extracted_skills=j.ai_extracted_skills,
                detected_tools=j.detected_tools,
                workflow_stage=j.workflow_stage,
                status=j.status,
                revision_notes=j.revision_notes,
                is_urgent_revision=j.is_urgent_revision,
                student_name=student.full_name if student else None,
                reviewer_name=student.full_name if student else j.reviewer_name,
                created_at=j.created_at,
                photo_url=photo_url,
                attachments=[EvidenceResponse.model_validate(a) for a in j.attachments] if j.attachments else [],
            )
        )

    return ApiResponse(
        success=True,
        data=result,
        message=f"Berhasil memuat {len(result)} jurnal PKL."
    )

@router.patch("/journals/{journal_id}/review", response_model=ApiResponse[JournalResponse])
def review_journal(
    journal_id: int,
    action: str = Query(..., pattern="^(approve|revise|revision)$"),
    notes: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    from app.api.v1.routes.journals import review_journal as review
    if current_user.role not in [UserRole.GURU, UserRole.ADMIN]:
        raise HTTPException(403, 'Anda tidak memiliki akses.')
    return review(journal_id=journal_id, approved=action == 'approve', notes=notes,
                  current_user=current_user, db=db)

# --- DUDI / Perusahaan CRUD Endpoints ---

@router.get("/companies", response_model=ApiResponse[CompanyListResponse])
def get_companies(
    include_inactive: bool = False,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    query = db.query(CompanyPlacement)
    if not include_inactive:
        query = query.filter(CompanyPlacement.is_active == True)
    companies = query.all()
    items = []
    for c in companies:
        count = db.query(PlacementAssignment).filter(PlacementAssignment.placement_id == c.id).count()
        items.append(
            CompanyResponse(
                id=c.id,
                name=c.name,
                division=c.division,
                address=c.address,
                latitude=c.latitude,
                longitude=c.longitude,
                geofence_radius=c.geofence_radius,
                mentor_name=c.mentor_name,
                mentor_phone=c.mentor_phone,
                supervisor_name=c.supervisor_name,
                supervisor_phone=c.supervisor_phone,
                period_start=c.period_start,
                period_end=c.period_end,
                code=c.code,
                is_active=c.is_active,
                student_count=count,
            )
        )
    return ApiResponse(
        success=True,
        data=CompanyListResponse(items=items, total=len(items)),
        message="Daftar mitra DUDI berhasil dimuat."
    )

@router.post("/companies", response_model=ApiResponse[CompanyResponse], status_code=status.HTTP_201_CREATED)
def create_company(
    payload: CompanyCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(["admin"])),
):
    division_val = payload.division or payload.industry_sector or "Divisi Operasional"
    mentor_name_val = payload.mentor_name or payload.contact_person
    mentor_phone_val = payload.mentor_phone or payload.phone
    lat_val = payload.latitude if payload.latitude is not None else -7.7854
    lng_val = payload.longitude if payload.longitude is not None else 110.3722

    company = CompanyPlacement(
        name=payload.name,
        division=division_val,
        address=payload.address,
        latitude=lat_val,
        longitude=lng_val,
        geofence_radius=payload.geofence_radius or 100.0,
        mentor_name=mentor_name_val,
        mentor_phone=mentor_phone_val,
        supervisor_name=payload.supervisor_name,
        supervisor_phone=payload.supervisor_phone,
        period_start=payload.period_start,
        period_end=payload.period_end,
        code=payload.code,
        is_active=payload.is_active if payload.is_active is not None else True,
    )
    db.add(company)
    db.commit()
    db.refresh(company)

    log_activity(
        db=db,
        actor_id=current_user.id,
        actor_name=current_user.full_name,
        actor_role=current_user.role.value,
        action="CREATE_COMPANY",
        module="COMPANY",
        target_type="CompanyPlacement",
        target_id=str(company.id),
        description=f"Administrator {current_user.full_name} menambahkan mitra DUDI baru: {company.name}."
    )

    return ApiResponse(
        success=True,
        data=CompanyResponse(
            id=company.id,
            name=company.name,
            division=company.division,
            address=company.address,
            latitude=company.latitude,
            longitude=company.longitude,
            geofence_radius=company.geofence_radius,
            mentor_name=company.mentor_name,
            mentor_phone=company.mentor_phone,
            supervisor_name=company.supervisor_name,
            supervisor_phone=company.supervisor_phone,
            period_start=company.period_start,
            period_end=company.period_end,
            code=company.code,
            is_active=company.is_active,
            student_count=0,
        ),
        message="Mitra industri / DUDI baru berhasil ditambahkan."
    )

@router.put("/companies/{id}", response_model=ApiResponse[CompanyResponse])
def update_company(
    id: int,
    payload: CompanyUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(["admin"])),
):
    company = db.query(CompanyPlacement).filter(CompanyPlacement.id == id).first()
    if not company:
        raise HTTPException(status_code=404, detail="Mitra DUDI tidak ditemukan.")

    for k, v in payload.model_dump(exclude_unset=True).items():
        if v is not None:
            setattr(company, k, v)

    db.commit()
    db.refresh(company)

    log_activity(
        db=db,
        actor_id=current_user.id,
        actor_name=current_user.full_name,
        actor_role=current_user.role.value,
        action="UPDATE_COMPANY",
        module="COMPANY",
        target_type="CompanyPlacement",
        target_id=str(company.id),
        description=f"Administrator {current_user.full_name} memperbarui data mitra DUDI: {company.name}."
    )

    count = db.query(PlacementAssignment).filter(PlacementAssignment.placement_id == company.id).count()
    return ApiResponse(
        success=True,
        data=CompanyResponse(
            id=company.id,
            name=company.name,
            division=company.division,
            address=company.address,
            latitude=company.latitude,
            longitude=company.longitude,
            geofence_radius=company.geofence_radius,
            mentor_name=company.mentor_name,
            mentor_phone=company.mentor_phone,
            supervisor_name=company.supervisor_name,
            supervisor_phone=company.supervisor_phone,
            period_start=company.period_start,
            period_end=company.period_end,
            code=company.code,
            is_active=company.is_active,
            student_count=count,
        ),
        message="Data mitra DUDI berhasil diperbarui."
    )

@router.delete("/companies/{id}", response_model=ApiResponse[dict])
def delete_company(
    id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(["admin"])),
):
    company = db.query(CompanyPlacement).filter(CompanyPlacement.id == id).first()
    if not company:
        raise HTTPException(status_code=404, detail="Mitra DUDI tidak ditemukan.")

    name = company.name

    # Clean up associated references to ensure clean permanent deletion
    from app.models.access import CompanyMember
    from app.models.submission import PklSubmission
    from app.models.attendance import AttendanceRecord
    from app.models.journal import DailyJournal

    db.query(PlacementAssignment).filter(PlacementAssignment.placement_id == id).delete(synchronize_session=False)
    db.query(CompanyMember).filter(CompanyMember.company_id == id).delete(synchronize_session=False)
    db.query(PklSubmission).filter(PklSubmission.company_id == id).update({"company_id": None}, synchronize_session=False)
    db.query(AttendanceRecord).filter(AttendanceRecord.placement_id == id).delete(synchronize_session=False)
    db.query(DailyJournal).filter(DailyJournal.placement_id == id).delete(synchronize_session=False)

    db.delete(company)
    db.commit()

    log_activity(
        db=db,
        actor_id=current_user.id,
        actor_name=current_user.full_name,
        actor_role=current_user.role.value,
        action="DELETE_COMPANY",
        module="COMPANY",
        target_type="CompanyPlacement",
        target_id=str(id),
        description=f"Administrator {current_user.full_name} menghapus mitra DUDI: {name}."
    )

    return ApiResponse(
        success=True,
        data={"deleted_id": id, "name": name},
        message=f"Mitra '{name}' berhasil dihapus secara permanen dari sistem."
    )



