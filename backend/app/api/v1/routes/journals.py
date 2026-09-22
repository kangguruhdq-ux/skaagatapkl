import json
from datetime import datetime, date
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status, Body
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.models.user import User, UserRole
from app.models.placement import CompanyPlacement, PlacementAssignment
from app.models.submission import PklSubmission
from app.models.journal import DailyJournal, EvidenceAttachment
from app.schemas.common import ApiResponse
from app.schemas.journal import (
    JournalCreate,
    JournalUpdate,
    JournalReviewRequest,
    JournalResponse,
    JournalHistoryResponse,
    AiAnalysisRequest,
    AiAnalysisResponse,
)
from app.services.ai_extractor import analyze_journal_entry
from app.api.deps import get_current_user, get_current_supervisor
from app.services.access import require_student_access, require_owner
from app.models.journal_history import JournalHistory
from app.models.audit_log import AuditLog

router = APIRouter()

def _to_journal_response(j: DailyJournal, db: Session) -> JournalResponse:
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
    
    resp = JournalResponse.model_validate(j)
    resp.student_name = student.full_name if student else None
    resp.photo_url = photo_url
    return resp

@router.post("/analyze-ai", response_model=ApiResponse[AiAnalysisResponse])
def analyze_logbook(request: AiAnalysisRequest):
    analysis = analyze_journal_entry(request.text)
    return ApiResponse(
        success=True,
        data=AiAnalysisResponse(**analysis),
        message="Analisis semantik AI berhasil diselesaikan."
    )

@router.get("", response_model=ApiResponse[List[JournalResponse]])
def get_journals(
    status_filter: Optional[str] = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    query = db.query(DailyJournal)
    if current_user.role == UserRole.SISWA:
        query = query.filter(DailyJournal.student_id == current_user.id)
    elif current_user.role == UserRole.GURU:
        allowed = db.query(PklSubmission.student_id).filter(PklSubmission.teacher_id == current_user.id).subquery()
        query = query.filter(DailyJournal.student_id.in_(allowed))
    elif current_user.role != UserRole.ADMIN:
        raise HTTPException(403, 'Akses jurnal ditolak.')
    if status_filter:
        query = query.filter(DailyJournal.status == status_filter)

    journals = query.order_by(DailyJournal.id.desc()).all()
    return ApiResponse(
        success=True,
        data=[_to_journal_response(j, db) for j in journals],
        message="Daftar jurnal berhasil dimuat."
    )

@router.post("", response_model=ApiResponse[JournalResponse])
def create_journal(
    request: JournalCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if current_user.role != UserRole.SISWA:
        raise HTTPException(403, "Hanya siswa yang dapat membuat jurnal.")
    student = current_user
    assignment = db.query(PlacementAssignment).filter(PlacementAssignment.student_id == student.id, PlacementAssignment.status == "ACTIVE").first()
    company = db.query(CompanyPlacement).filter(CompanyPlacement.id == assignment.placement_id).first() if assignment else None
    if not company:
        raise HTTPException(409, "Penempatan PKL aktif belum tersedia.")

    # Perform AI semantic analysis on summary
    analysis = analyze_journal_entry(request.work_summary)

    today_str = date.today().isoformat()
    journal_count = db.query(DailyJournal).filter(DailyJournal.student_id == student.id).count()

    journal = DailyJournal(
        student_id=student.id,
        placement_id=company.id,
        date=today_str,
        day_number=58 + journal_count,
        hours_spent=request.hours_spent or 8.5,
        work_summary=request.work_summary,
        standard_competency=analysis["standard_competency"],
        competency_category=analysis["competency_category"],
        complexity_level=analysis["complexity_level"],
        complexity_tier=analysis["complexity_tier"],
        ai_match_percentage=analysis["match_percentage"],
        ai_extracted_skills=json.dumps(analysis["extracted_skills"]),
        detected_tools=json.dumps(analysis["detected_tools"]),
        workflow_stage=request.workflow_stage or 1,
        status="SUBMITTED" if (request.workflow_stage or 1) >= 2 else "DRAFT",
        is_urgent_revision=False,
        reviewer_name=company.mentor_name
    )
    db.add(journal)
    db.commit()
    db.refresh(journal)

    return ApiResponse(
        success=True,
        data=_to_journal_response(journal, db),
        message="Jurnal kegiatan berhasil disimpan dan dianalisis AI."
    )

@router.get("/{journal_id}", response_model=ApiResponse[JournalResponse])
def get_journal_detail(
    journal_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    journal = db.query(DailyJournal).filter(DailyJournal.id == journal_id).first()
    if not journal:
        raise HTTPException(status_code=404, detail="Jurnal tidak ditemukan.")

    require_student_access(db, current_user, journal.student_id)
    return ApiResponse(
        success=True,
        data=_to_journal_response(journal, db),
        message="Detail jurnal berhasil dimuat."
    )

@router.patch("/{journal_id}", response_model=ApiResponse[JournalResponse])
def update_journal(
    journal_id: int,
    request: JournalUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    journal = db.query(DailyJournal).filter(DailyJournal.id == journal_id).first()
    if not journal:
        raise HTTPException(status_code=404, detail="Jurnal tidak ditemukan.")

    require_owner(current_user, journal.student_id)
    if request.work_summary is not None:
        journal.work_summary = request.work_summary
        analysis = analyze_journal_entry(request.work_summary)
        journal.ai_match_percentage = analysis["match_percentage"]
        journal.ai_extracted_skills = json.dumps(analysis["extracted_skills"])
        journal.detected_tools = json.dumps(analysis["detected_tools"])

    previous_status = journal.status
    if request.hours_spent is not None:
        journal.hours_spent = request.hours_spent
    if request.workflow_stage is not None:
        journal.workflow_stage = request.workflow_stage
    if request.status is not None:
        journal.status = request.status
        if request.status in ["SUBMITTED", "REVIEW", "RESUBMITTED"]:
            journal.is_urgent_revision = False
    if request.revision_notes is not None:
        journal.revision_notes = request.revision_notes

    # If student is updating an item that required revision, transition to RESUBMITTED
    if previous_status == "REVISION_REQUIRED" and (request.status in ["RESUBMITTED", "REVIEW", "SUBMITTED"] or request.workflow_stage == 4):
        journal.status = "RESUBMITTED"
        journal.is_urgent_revision = False
        db.add(JournalHistory(
            journal_id=journal.id,
            previous_status=previous_status,
            new_status="RESUBMITTED",
            actor_id=current_user.id,
            reviewer=current_user.full_name,
            comment="Siswa memperbarui uraian aktivitas dan mengajukan ulang jurnal."
        ))
        db.add(AuditLog(
            actor_id=current_user.id,
            actor_name=current_user.full_name,
            actor_role=current_user.role,
            action="RESUBMIT_JOURNAL",
            module="JOURNAL",
            target_type="DailyJournal",
            target_id=str(journal.id),
            description=f"Siswa {current_user.full_name} mengajukan ulang jurnal #{journal.id} setelah revisi."
        ))

    db.commit()
    db.refresh(journal)

    return ApiResponse(
        success=True,
        data=_to_journal_response(journal, db),
        message="Jurnal berhasil diperbarui."
    )

@router.post("/{journal_id}/submit", response_model=ApiResponse[JournalResponse])
def submit_journal(
    journal_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    journal = db.query(DailyJournal).filter(DailyJournal.id == journal_id).first()
    if not journal:
        raise HTTPException(status_code=404, detail="Jurnal tidak ditemukan.")

    require_owner(current_user, journal.student_id)
    previous_status = journal.status
    journal.workflow_stage = 4  # Review
    journal.status = "RESUBMITTED" if previous_status == "REVISION_REQUIRED" else "REVIEW"
    journal.is_urgent_revision = False

    db.add(JournalHistory(
        journal_id=journal.id,
        previous_status=previous_status,
        new_status=journal.status,
        actor_id=current_user.id,
        reviewer=current_user.full_name,
        comment="Siswa mengajukan jurnal untuk validasi pembimbing."
    ))
    db.add(AuditLog(
        actor_id=current_user.id,
        actor_name=current_user.full_name,
        actor_role=current_user.role,
        action="SUBMIT_JOURNAL" if journal.status == "REVIEW" else "RESUBMIT_JOURNAL",
        module="JOURNAL",
        target_type="DailyJournal",
        target_id=str(journal.id),
        description=f"Siswa {current_user.full_name} mengajukan jurnal #{journal.id} (Status: {journal.status})."
    ))
    db.commit()
    db.refresh(journal)

    return ApiResponse(
        success=True,
        data=_to_journal_response(journal, db),
        message="Jurnal berhasil diajukan untuk validasi pembimbing DUDI."
    )

@router.post("/{journal_id}/review", response_model=ApiResponse[JournalResponse])
def review_journal(
    journal_id: int,
    payload: Optional[JournalReviewRequest] = Body(None),
    approved: Optional[bool] = None,
    status: Optional[str] = None,
    notes: Optional[str] = None,
    current_user: User = Depends(get_current_supervisor),
    db: Session = Depends(get_db)
):
    journal = db.query(DailyJournal).filter(DailyJournal.id == journal_id).first()
    if not journal:
        raise HTTPException(status_code=404, detail="Jurnal tidak ditemukan.")

    if isinstance(payload, JournalReviewRequest):
        if payload.status is not None:
            status = payload.status
        if payload.approved is not None:
            approved = payload.approved
        if payload.notes is not None:
            notes = payload.notes

    require_student_access(db, current_user, journal.student_id)
    previous_status = journal.status
    journal.reviewer_name = current_user.full_name
    journal.reviewed_at = datetime.utcnow()

    # Determine status
    if status is not None:
        final_status = status.upper()
    elif approved is not None:
        final_status = "APPROVED" if approved else "REVISION_REQUIRED"
    else:
        final_status = "APPROVED"

    # Enforce mandatory non-empty revision notes
    if final_status == "REVISION_REQUIRED":
        if not notes or not notes.strip():
            raise HTTPException(
                status_code=400,
                detail="Catatan / alasan revisi wajib diisi agar siswa mengetahui perbaikan yang diperlukan."
            )

    journal.status = final_status
    if final_status in ["APPROVED", "REVIEWED"]:
        journal.workflow_stage = 5
        journal.is_urgent_revision = False
    elif final_status in ["REVISION_REQUIRED", "REJECTED"]:
        journal.workflow_stage = 4
        journal.is_urgent_revision = True
        journal.revision_notes = notes.strip() if notes else ("Jurnal ditolak pembimbing." if final_status == "REJECTED" else "Harap perbaiki dokumentasi sebelum validasi.")
    else:
        journal.workflow_stage = 4
        journal.is_urgent_revision = False

    db.add(JournalHistory(
        journal_id=journal.id,
        previous_status=previous_status,
        new_status=journal.status,
        actor_id=current_user.id,
        reviewer=current_user.full_name,
        comment=notes
    ))
    db.add(AuditLog(
        actor_id=current_user.id,
        actor_name=current_user.full_name,
        actor_role=current_user.role,
        action=f"REVIEW_JOURNAL_{final_status}",
        module="JOURNAL",
        target_type="DailyJournal",
        target_id=str(journal.id),
        description=f"{current_user.full_name} ({current_user.role}) memvalidasi jurnal #{journal.id} menjadi {final_status}. Catatan: {notes or '-'}"
    ))
    db.commit()
    db.refresh(journal)

    return ApiResponse(
        success=True,
        data=_to_journal_response(journal, db),
        message="Validasi pembimbing berhasil disimpan."
    )

@router.get("/{journal_id}/history", response_model=ApiResponse[List[JournalHistoryResponse]])
def get_journal_history(
    journal_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    journal = db.query(DailyJournal).filter(DailyJournal.id == journal_id).first()
    if not journal:
        raise HTTPException(status_code=404, detail="Jurnal tidak ditemukan.")

    require_student_access(db, current_user, journal.student_id)
    history = db.query(JournalHistory).filter(JournalHistory.journal_id == journal_id).order_by(JournalHistory.timestamp.asc()).all()
    return ApiResponse(
        success=True,
        data=[JournalHistoryResponse.model_validate(h) for h in history],
        message="Riwayat status jurnal berhasil dimuat."
    )

@router.delete("/clear-all", response_model=ApiResponse[dict])
def clear_all_journals(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    query = db.query(DailyJournal)
    if current_user.role == UserRole.SISWA:
        query = query.filter(DailyJournal.student_id == current_user.id)
    elif current_user.role == UserRole.GURU:
        allowed = db.query(PklSubmission.student_id).filter(PklSubmission.teacher_id == current_user.id).subquery()
        query = query.filter(DailyJournal.student_id.in_(allowed))
    elif current_user.role != UserRole.ADMIN:
        raise HTTPException(403, 'Akses jurnal ditolak.')
    
    journals = query.all()
    count = len(journals)
    for j in journals:
        db.query(EvidenceAttachment).filter(EvidenceAttachment.journal_id == j.id).delete()
        db.query(JournalHistory).filter(JournalHistory.journal_id == j.id).delete()
        db.delete(j)

    db.add(AuditLog(
        actor_id=current_user.id,
        actor_name=current_user.full_name,
        actor_role=current_user.role,
        action="CLEAR_ALL_JOURNALS",
        module="JOURNAL",
        target_type="DailyJournal",
        target_id="ALL",
        description=f"{current_user.full_name} ({current_user.role}) menghapus seluruh riwayat log jurnal ({count} entri)."
    ))
    db.commit()

    return ApiResponse(
        success=True,
        data={"deleted_count": count},
        message=f"Berhasil menghapus {count} seluruh riwayat jurnal."
    )

@router.delete("/{journal_id}", response_model=ApiResponse[dict])
def delete_journal(
    journal_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    journal = db.query(DailyJournal).filter(DailyJournal.id == journal_id).first()
    if not journal:
        raise HTTPException(status_code=404, detail="Jurnal tidak ditemukan.")

    if current_user.role == UserRole.SISWA and journal.student_id != current_user.id:
        raise HTTPException(
            status_code=403,
            detail="Akses ditolak. Siswa hanya dapat menghapus log jurnal milik sendiri."
        )

    # Delete attachments and history cascade
    db.query(EvidenceAttachment).filter(EvidenceAttachment.journal_id == journal_id).delete()
    db.query(JournalHistory).filter(JournalHistory.journal_id == journal_id).delete()
    
    db.delete(journal)

    db.add(AuditLog(
        actor_id=current_user.id,
        actor_name=current_user.full_name,
        actor_role=current_user.role,
        action="DELETE_JOURNAL",
        module="JOURNAL",
        target_type="DailyJournal",
        target_id=str(journal_id),
        description=f"{current_user.full_name} ({current_user.role}) menghapus entri jurnal #{journal_id}."
    ))
    db.commit()

    return ApiResponse(
        success=True,
        data={"deleted_id": journal_id},
        message="Jurnal harian berhasil dihapus."
    )



