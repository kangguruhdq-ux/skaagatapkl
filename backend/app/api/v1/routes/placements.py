from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.models.user import User, UserRole
from app.models.placement import CompanyPlacement
from app.schemas.common import ApiResponse
from app.schemas.dashboard import PlacementInfo
from app.api.deps import get_current_user
from app.services.audit_service import log_activity

router = APIRouter()

class CompanyProposalCreate(BaseModel):
    name: str
    address: str
    division: Optional[str] = "Divisi Operasional"
    mentor_name: Optional[str] = None
    mentor_phone: Optional[str] = None
    notes: Optional[str] = None

@router.get("", response_model=ApiResponse[List[PlacementInfo]])
def get_placements(db: Session = Depends(get_db)):
    placements = db.query(CompanyPlacement).filter(CompanyPlacement.is_active == True).all()
    results = []
    for c in placements:
        results.append(
            PlacementInfo(
                id=c.id,
                company_name=c.name,
                division=c.division or "",
                address=c.address,
                mentor_name=c.mentor_name or "",
                supervisor_name=c.supervisor_name or "",
                period_string=f"{c.period_start} - {c.period_end}",
                current_week=c.current_week,
                total_weeks=c.total_weeks,
                progress_pct=int((c.current_week / c.total_weeks) * 100),
                status="Active"
            )
        )
    return ApiResponse(
        success=True,
        data=results,
        message="Daftar mitra DUDI berhasil dimuat."
    )

@router.post("/propose", response_model=ApiResponse[dict], status_code=status.HTTP_201_CREATED)
def propose_company(
    payload: CompanyProposalCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    comp = CompanyPlacement(
        name=payload.name,
        division=payload.division or "Divisi Operasional",
        address=payload.address,
        latitude=-7.78542,
        longitude=110.37219,
        mentor_name=payload.mentor_name or f"Pengusul: {current_user.full_name}",
        mentor_phone=payload.mentor_phone,
        code="PROPOSED",
        is_active=False
    )
    db.add(comp)
    db.commit()
    db.refresh(comp)

    log_activity(
        db=db,
        actor_id=current_user.id,
        actor_name=current_user.full_name,
        actor_role=current_user.role.value,
        action="PROPOSE_NEW_COMPANY",
        module="COMPANY",
        target_type="CompanyPlacement",
        target_id=str(comp.id),
        description=f"Siswa/Pengguna {current_user.full_name} mengusulkan tempat PKL baru: '{comp.name}' ({comp.address}). Catatan: {payload.notes or '-'}"
    )

    return ApiResponse(
        success=True,
        data={"id": comp.id, "name": comp.name, "status": "PROPOSED"},
        message="Usulan tempat mitra PKL baru berhasil dikirim dan menunggu persetujuan Guru Pembimbing / Admin."
    )

@router.get("/proposals", response_model=ApiResponse[List[dict]])
def get_company_proposals(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    proposals = db.query(CompanyPlacement).filter(
        (CompanyPlacement.code == "PROPOSED") | (CompanyPlacement.is_active == False)
    ).order_by(CompanyPlacement.id.desc()).all()

    items = []
    for c in proposals:
        items.append({
            "id": c.id,
            "name": c.name,
            "division": c.division,
            "address": c.address,
            "mentor_name": c.mentor_name,
            "mentor_phone": c.mentor_phone,
            "is_active": c.is_active,
            "created_at": c.created_at.isoformat() if c.created_at else None,
        })

    return ApiResponse(
        success=True,
        data=items,
        message=f"Berhasil memuat {len(items)} usulan mitra baru."
    )

@router.post("/{id}/approve", response_model=ApiResponse[dict])
def approve_company_proposal(
    id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if current_user.role not in [UserRole.GURU, UserRole.ADMIN]:
        raise HTTPException(status_code=403, detail="Hanya Guru atau Admin yang berhak menyetujui usulan mitra.")

    comp = db.query(CompanyPlacement).filter(CompanyPlacement.id == id).first()
    if not comp:
        raise HTTPException(status_code=404, detail="Data usulan mitra tidak ditemukan.")

    comp.is_active = True
    comp.code = "PKL-APPROVED"
    db.commit()
    db.refresh(comp)

    log_activity(
        db=db,
        actor_id=current_user.id,
        actor_name=current_user.full_name,
        actor_role=current_user.role.value,
        action="APPROVE_COMPANY_PROPOSAL",
        module="COMPANY",
        target_type="CompanyPlacement",
        target_id=str(comp.id),
        description=f"{current_user.full_name} menyetujui usulan mitra baru '{comp.name}'. Kini aktif untuk semua siswa."
    )

    return ApiResponse(
        success=True,
        data={"id": comp.id, "name": comp.name, "is_active": True},
        message=f"Tempat mitra '{comp.name}' berhasil disetujui (ACC) dan kini aktif!"
    )

@router.post("/{id}/reject", response_model=ApiResponse[dict])
def reject_company_proposal(
    id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if current_user.role not in [UserRole.GURU, UserRole.ADMIN]:
        raise HTTPException(status_code=403, detail="Hanya Guru atau Admin yang berhak menolak usulan mitra.")

    comp = db.query(CompanyPlacement).filter(CompanyPlacement.id == id).first()
    if not comp:
        raise HTTPException(status_code=404, detail="Data usulan mitra tidak ditemukan.")

    name = comp.name
    db.delete(comp)
    db.commit()

    return ApiResponse(
        success=True,
        data={"deleted_id": id},
        message=f"Usulan mitra '{name}' telah ditolak/dihapus."
    )
