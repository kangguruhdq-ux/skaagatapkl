from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import Optional

from app.db.session import get_db
from app.models.user import User, UserRole
from app.models.submission import PklSubmission, PklEvidence
from app.models.placement import CompanyPlacement, PlacementAssignment
from app.schemas.common import ApiResponse
from app.schemas.submission import (
    SubmissionCreate,
    SubmissionUpdate,
    SubmissionChangeRequest,
    SubmissionReview,
    SubmissionResponse,
    SubmissionListResponse,
)
from app.api.deps import get_current_user, require_roles
from app.services.audit_service import log_activity

router = APIRouter()

def _format_submission(sub: PklSubmission) -> SubmissionResponse:
    return SubmissionResponse(
        id=sub.id,
        student_id=sub.student_id,
        student_name=sub.student.full_name if sub.student else None,
        student_class=sub.student.student_class if sub.student else None,
        company_id=sub.company_id,
        company_name=sub.company_name,
        company_address=sub.company_address,
        company_phone=sub.company_phone,
        company_email=sub.company_email,
        company_website=sub.company_website,
        industry_sector=sub.industry_sector,
        division=sub.division,
        start_date=sub.start_date,
        end_date=sub.end_date,
        latitude=sub.latitude,
        longitude=sub.longitude,
        mentor_name=sub.mentor_name,
        mentor_contact=sub.mentor_contact,
        teacher_id=sub.teacher_id,
        teacher_name=sub.teacher.full_name if sub.teacher else None,
        status=sub.status,
        teacher_notes=sub.teacher_notes,
        change_reason=sub.change_reason,
        previous_company_name=sub.previous_company_name,
        document_url=sub.document_url,
        created_at=sub.created_at,
    )

@router.get("", response_model=ApiResponse[SubmissionListResponse])
def get_submissions(
    status: Optional[str] = None,
    student_id: Optional[int] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    query = db.query(PklSubmission)

    # Students only see their own submissions
    if current_user.role == UserRole.SISWA:
        query = query.filter(PklSubmission.student_id == current_user.id)
    elif student_id:
        query = query.filter(PklSubmission.student_id == student_id)

    if status:
        query = query.filter(PklSubmission.status == status.upper())

    submissions = query.order_by(PklSubmission.created_at.desc()).all()
    items = [_format_submission(s) for s in submissions]

    return ApiResponse(
        success=True,
        data=SubmissionListResponse(items=items, total=len(items)),
        message="Daftar pengajuan PKL berhasil dimuat."
    )

@router.post("", response_model=ApiResponse[SubmissionResponse], status_code=status.HTTP_201_CREATED)
def create_submission(
    payload: SubmissionCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    # Find teacher if not provided
    teacher_id = payload.teacher_id
    if not teacher_id:
        teacher = db.query(User).filter(User.role == UserRole.GURU).first()
        if teacher:
            teacher_id = teacher.id

    submission = PklSubmission(
        student_id=current_user.id,
        company_name=payload.company_name,
        company_address=payload.company_address,
        company_phone=payload.company_phone,
        company_email=payload.company_email,
        company_website=payload.company_website,
        industry_sector=payload.industry_sector,
        division=payload.division,
        start_date=payload.start_date,
        end_date=payload.end_date,
        latitude=payload.latitude or -7.78542,
        longitude=payload.longitude or 110.37219,
        mentor_name=payload.mentor_name,
        mentor_contact=payload.mentor_contact,
        teacher_id=teacher_id,
        status="SUBMITTED",
        document_url=payload.document_url,
    )
    db.add(submission)
    db.commit()
    db.refresh(submission)

    log_activity(
        db=db,
        actor_id=current_user.id,
        actor_name=current_user.full_name,
        actor_role=current_user.role.value,
        action="CREATE_PKL_SUBMISSION",
        module="SUBMISSION",
        target_type="PklSubmission",
        target_id=str(submission.id),
        description=f"Siswa {current_user.full_name} mengajukan tempat PKL di {submission.company_name}."
    )

    return ApiResponse(
        success=True,
        data=_format_submission(submission),
        message="Pengajuan PKL berhasil dibuat dan diteruskan ke Guru Pembimbing."
    )

@router.get("/{id}", response_model=ApiResponse[SubmissionResponse])
def get_submission_detail(
    id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    sub = db.query(PklSubmission).filter(PklSubmission.id == id).first()
    if not sub:
        raise HTTPException(status_code=404, detail="Data pengajuan PKL tidak ditemukan.")

    if current_user.role == UserRole.SISWA and sub.student_id != current_user.id:
        raise HTTPException(status_code=403, detail="Akses ditolak.")

    return ApiResponse(
        success=True,
        data=_format_submission(sub),
        message="Detail pengajuan PKL berhasil dimuat."
    )

@router.put("/{id}", response_model=ApiResponse[SubmissionResponse])
def update_submission(
    id: int,
    payload: SubmissionUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    sub = db.query(PklSubmission).filter(PklSubmission.id == id).first()
    if not sub:
        raise HTTPException(status_code=404, detail="Data pengajuan PKL tidak ditemukan.")

    if current_user.role == UserRole.SISWA and sub.student_id != current_user.id:
        raise HTTPException(status_code=403, detail="Akses ditolak.")

    if sub.status in ["APPROVED"] and current_user.role != UserRole.ADMIN:
        raise HTTPException(status_code=400, detail="Pengajuan yang sudah disetujui tidak dapat diubah langsung. Gunakan alur Ganti Tempat PKL.")

    update_dict = payload.model_dump(exclude_unset=True)
    for key, value in update_dict.items():
        if value is not None:
            setattr(sub, key, value)

    # Re-evaluate status if previously revision requested
    if sub.status == "REVISION_REQUIRED":
        sub.status = "SUBMITTED"

    db.commit()
    db.refresh(sub)

    log_activity(
        db=db,
        actor_id=current_user.id,
        actor_name=current_user.full_name,
        actor_role=current_user.role.value,
        action="UPDATE_PKL_SUBMISSION",
        module="SUBMISSION",
        target_type="PklSubmission",
        target_id=str(sub.id),
        description=f"Pembaruan data pengajuan PKL di {sub.company_name} oleh {current_user.full_name}."
    )

    return ApiResponse(
        success=True,
        data=_format_submission(sub),
        message="Pengajuan PKL berhasil diperbarui."
    )

@router.post("/{id}/change-request", response_model=ApiResponse[SubmissionResponse])
@router.post("/{id}/request-change", response_model=ApiResponse[SubmissionResponse])
def request_company_change(
    id: int,
    payload: SubmissionChangeRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    sub = None
    if id > 0:
        sub = db.query(PklSubmission).filter(PklSubmission.id == id).first()
    if not sub and current_user.role == UserRole.SISWA:
        sub = db.query(PklSubmission).filter(PklSubmission.student_id == current_user.id).first()
        if not sub:
            sub = PklSubmission(
                student_id=current_user.id,
                company_name="PT Telkom Indonesia (Witel Yogyakarta)",
                company_address="Jl. Yos Sudarso No.9 Kotabaru Yogyakarta",
                start_date="2024-07-15",
                end_date="2024-12-15",
                status="APPROVED"
            )
            db.add(sub)
            db.commit()
            db.refresh(sub)

    if not sub:
        raise HTTPException(status_code=404, detail="Data pengajuan PKL tidak ditemukan.")

    if current_user.role == UserRole.SISWA and sub.student_id != current_user.id:
        raise HTTPException(status_code=403, detail="Akses ditolak.")

    # If target_company_id is provided, resolve company info
    target_comp = None
    if payload.target_company_id:
        target_comp = db.query(CompanyPlacement).filter(CompanyPlacement.id == payload.target_company_id).first()

    new_company_name = payload.new_company_name or (target_comp.name if target_comp else "Industri Baru")
    new_address = payload.new_address or (target_comp.address if target_comp else "-")
    new_contact = payload.new_contact or (target_comp.mentor_phone if target_comp else None)

    # Archive previous company info
    sub.previous_company_name = sub.company_name
    sub.company_name = new_company_name
    sub.company_address = new_address
    sub.company_phone = new_contact
    sub.change_reason = payload.change_reason
    if payload.new_start_date:
        sub.start_date = payload.new_start_date
    if payload.new_end_date:
        sub.end_date = payload.new_end_date
    if payload.latitude:
        sub.latitude = payload.latitude
    elif target_comp:
        sub.latitude = target_comp.latitude
    if payload.longitude:
        sub.longitude = payload.longitude
    elif target_comp:
        sub.longitude = target_comp.longitude
    if payload.supporting_doc_url:
        sub.document_url = payload.supporting_doc_url

    sub.status = "CHANGE_REQUESTED"
    db.commit()
    db.refresh(sub)

    log_activity(
        db=db,
        actor_id=current_user.id,
        actor_name=current_user.full_name,
        actor_role=current_user.role.value,
        action="REQUEST_COMPANY_CHANGE",
        module="SUBMISSION",
        target_type="PklSubmission",
        target_id=str(sub.id),
        description=f"Siswa {current_user.full_name} mengajukan perubahan tempat PKL ke {sub.company_name}. Alasan: {payload.change_reason}"
    )

    return ApiResponse(
        success=True,
        data=_format_submission(sub),
        message="Permohonan pindah tempat PKL telah diajukan dan menunggu persetujuan Guru Pembimbing."
    )

@router.post("/{id}/review", response_model=ApiResponse[SubmissionResponse])
def review_submission(
    id: int,
    payload: SubmissionReview,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(["guru", "admin"]))
):
    sub = db.query(PklSubmission).filter(PklSubmission.id == id).first()
    if not sub:
        raise HTTPException(status_code=404, detail="Data pengajuan PKL tidak ditemukan.")

    action = payload.action.upper()
    sub.teacher_notes = payload.notes or sub.teacher_notes

    if action == "APPROVE":
        sub.status = "APPROVED"
        action_desc = "menyetujui"

        # Sinkronisasi ke PlacementAssignment & CompanyPlacement
        comp = db.query(CompanyPlacement).filter(CompanyPlacement.name.ilike(sub.company_name)).first()
        if not comp:
            comp = CompanyPlacement(
                name=sub.company_name,
                address=sub.company_address or "Alamat PKL",
                latitude=sub.latitude or -7.78542,
                longitude=sub.longitude or 110.37219,
                mentor_phone=sub.company_phone,
                is_active=True
            )
            db.add(comp)
            db.commit()
            db.refresh(comp)

        assignment = db.query(PlacementAssignment).filter(PlacementAssignment.student_id == sub.student_id).first()
        if assignment:
            assignment.placement_id = comp.id
            assignment.status = "ACTIVE"
        else:
            assignment = PlacementAssignment(student_id=sub.student_id, placement_id=comp.id, status="ACTIVE")
            db.add(assignment)

    elif action == "REJECT":
        sub.status = "REJECTED"
        action_desc = "menolak"
    elif action == "REVISION":
        sub.status = "REVISION_REQUIRED"
        action_desc = "meminta revisi pada"
    else:
        raise HTTPException(status_code=400, detail="Aksi review tidak valid. Gunakan APPROVE, REJECT, atau REVISION.")

    db.commit()
    db.refresh(sub)

    log_activity(
        db=db,
        actor_id=current_user.id,
        actor_name=current_user.full_name,
        actor_role=current_user.role.value,
        action=f"REVIEW_PKL_{action}",
        module="SUBMISSION",
        target_type="PklSubmission",
        target_id=str(sub.id),
        description=f"{current_user.full_name} ({current_user.role.value}) {action_desc} pengajuan PKL {sub.student.full_name if sub.student else 'Siswa'}. Catatan: {payload.notes or '-'}"
    )

    return ApiResponse(
        success=True,
        data=_format_submission(sub),
        message=f"Pengajuan PKL berhasil diproses ({sub.status})."
    )

@router.delete("/{id}", response_model=ApiResponse[dict])
def delete_submission(
    id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    sub = db.query(PklSubmission).filter(PklSubmission.id == id).first()
    if not sub:
        raise HTTPException(status_code=404, detail="Data pengajuan PKL tidak ditemukan.")

    if current_user.role == UserRole.SISWA:
        if sub.student_id != current_user.id:
            raise HTTPException(status_code=403, detail="Akses ditolak.")
        if sub.status in ["APPROVED", "COMPLETED"]:
            raise HTTPException(status_code=400, detail="Pengajuan yang telah disetujui tidak dapat dihapus.")

    company_name = sub.company_name
    db.delete(sub)
    db.commit()

    log_activity(
        db=db,
        actor_id=current_user.id,
        actor_name=current_user.full_name,
        actor_role=current_user.role.value,
        action="DELETE_PKL_SUBMISSION",
        module="SUBMISSION",
        target_type="PklSubmission",
        target_id=str(id),
        description=f"Pengajuan PKL di {company_name} dihapus oleh {current_user.full_name}."
    )

    return ApiResponse(
        success=True,
        data={"deleted_id": id},
        message="Pengajuan PKL berhasil dibatalkan/dihapus."
    )
