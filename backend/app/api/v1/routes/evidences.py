from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import Optional

from app.db.session import get_db
from app.models.user import User, UserRole
from app.models.submission import PklEvidence
from app.schemas.common import ApiResponse
from app.schemas.submission import (
    EvidenceCreate,
    EvidenceVerify,
    EvidenceResponse,
    EvidenceListResponse,
)
from app.api.deps import get_current_user, require_roles
from app.services.audit_service import log_activity

router = APIRouter()

def _format_evidence(ev: PklEvidence) -> EvidenceResponse:
    company_name = None
    if ev.submission and ev.submission.company_name:
        company_name = ev.submission.company_name
    elif ev.student and hasattr(ev.student, 'placements') and ev.student.placements:
        p = ev.student.placements[0]
        if p and p.company:
            company_name = p.company.name
    if not company_name:
        company_name = "PT Telkom Indonesia (Witel Yogyakarta)"

    return EvidenceResponse(
        id=ev.id,
        student_id=ev.student_id,
        student_name=ev.student.full_name if ev.student else None,
        student_class=ev.student.student_class if ev.student else None,
        company_name=company_name,
        submission_id=ev.submission_id,
        title=ev.title,
        category=ev.category,
        file_url=ev.file_url,
        description=ev.description,
        activity_date=ev.activity_date,
        status=ev.status,
        verifier_id=ev.verifier_id,
        verifier_name=ev.verifier.full_name if ev.verifier else None,
        verifier_notes=ev.verifier_notes,
        verified_at=ev.verified_at,
        created_at=ev.created_at,
    )

@router.get("", response_model=ApiResponse[EvidenceListResponse])
def get_evidences(
    student_id: Optional[int] = None,
    status: Optional[str] = None,
    category: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    query = db.query(PklEvidence)

    if current_user.role == UserRole.SISWA:
        query = query.filter(PklEvidence.student_id == current_user.id)
    elif student_id:
        query = query.filter(PklEvidence.student_id == student_id)

    if status:
        query = query.filter(PklEvidence.status == status.upper())
    if category:
        query = query.filter(PklEvidence.category == category.upper())

    evidences = query.order_by(PklEvidence.created_at.desc()).all()
    items = [_format_evidence(e) for e in evidences]

    return ApiResponse(
        success=True,
        data=EvidenceListResponse(items=items, total=len(items)),
        message="Daftar bukti kegiatan PKL berhasil dimuat."
    )

@router.post("", response_model=ApiResponse[EvidenceResponse], status_code=status.HTTP_201_CREATED)
def upload_evidence(
    payload: EvidenceCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    evidence = PklEvidence(
        student_id=current_user.id,
        submission_id=payload.submission_id,
        title=payload.title,
        category=payload.category.upper(),
        file_url=payload.file_url,
        description=payload.description,
        activity_date=payload.activity_date or datetime.now().strftime("%d %b %Y"),
        status="UPLOADED",
    )
    db.add(evidence)
    db.commit()
    db.refresh(evidence)

    log_activity(
        db=db,
        actor_id=current_user.id,
        actor_name=current_user.full_name,
        actor_role=current_user.role.value,
        action="UPLOAD_PKL_EVIDENCE",
        module="EVIDENCE",
        target_type="PklEvidence",
        target_id=str(evidence.id),
        description=f"Siswa {current_user.full_name} mengunggah bukti {evidence.category}: '{evidence.title}'."
    )

    return ApiResponse(
        success=True,
        data=_format_evidence(evidence),
        message="Bukti kegiatan berhasil diunggah dan siap diverifikasi oleh Guru."
    )

@router.patch("/{id}/verify", response_model=ApiResponse[EvidenceResponse])
@router.post("/{id}/verify", response_model=ApiResponse[EvidenceResponse])
def verify_evidence(
    id: int,
    payload: EvidenceVerify,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(["guru", "admin", "mitra"]))
):
    ev = db.query(PklEvidence).filter(PklEvidence.id == id).first()
    if not ev:
        raise HTTPException(status_code=404, detail="Bukti kegiatan tidak ditemukan.")

    raw_action = payload.action or payload.status or "VERIFY"
    action = raw_action.upper()
    if action in ["APPROVED", "VERIFIED"]:
        action = "VERIFY"
    elif action in ["REJECTED"]:
        action = "REJECT"
    elif action in ["REVISE", "REVISION_REQUIRED"]:
        action = "REVISION"

    ev.verifier_id = current_user.id
    ev.verifier_notes = payload.notes or payload.review_notes or ev.verifier_notes

    if action == "VERIFY":
        ev.status = "VERIFIED"
        ev.verified_at = datetime.utcnow()
        desc_action = "memverifikasi"
    elif action == "REJECT":
        ev.status = "REJECTED"
        desc_action = "menolak"
    elif action == "REVISION":
        ev.status = "REVISION_REQUIRED"
        desc_action = "meminta revisi"
    else:
        raise HTTPException(status_code=400, detail="Aksi tidak valid. Gunakan VERIFY, REJECT, atau REVISION.")

    db.commit()
    db.refresh(ev)

    log_activity(
        db=db,
        actor_id=current_user.id,
        actor_name=current_user.full_name,
        actor_role=current_user.role.value,
        action=f"VERIFY_EVIDENCE_{action}",
        module="EVIDENCE",
        target_type="PklEvidence",
        target_id=str(ev.id),
        description=f"{current_user.full_name} ({current_user.role.value}) {desc_action} bukti '{ev.title}' milik {ev.student.full_name if ev.student else 'Siswa'}."
    )

    return ApiResponse(
        success=True,
        data=_format_evidence(ev),
        message=f"Bukti berhasil diproses ({ev.status})."
    )

@router.delete("/{id}", response_model=ApiResponse[dict])
def delete_evidence(
    id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    ev = db.query(PklEvidence).filter(PklEvidence.id == id).first()
    if not ev:
        raise HTTPException(status_code=404, detail="Bukti kegiatan tidak ditemukan.")

    if current_user.role == UserRole.SISWA and ev.student_id != current_user.id:
        raise HTTPException(status_code=403, detail="Akses ditolak.")

    title = ev.title
    db.delete(ev)
    db.commit()

    log_activity(
        db=db,
        actor_id=current_user.id,
        actor_name=current_user.full_name,
        actor_role=current_user.role.value,
        action="DELETE_EVIDENCE",
        module="EVIDENCE",
        target_type="PklEvidence",
        target_id=str(id),
        description=f"Bukti '{title}' dihapus oleh {current_user.full_name}."
    )

    return ApiResponse(
        success=True,
        data={"deleted_id": id},
        message="Bukti kegiatan berhasil dihapus."
    )
