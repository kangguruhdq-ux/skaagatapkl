from typing import Optional
from fastapi import APIRouter, Depends, UploadFile, File, Form, HTTPException
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.models.user import User
from app.models.journal import DailyJournal, EvidenceAttachment
from app.schemas.common import ApiResponse
from app.schemas.journal import EvidenceResponse
from app.services.storage import storage_service
from app.api.deps import get_current_user

router = APIRouter()

@router.post("/profile", response_model=ApiResponse[dict])
async def upload_profile_photo(file: UploadFile = File(...), current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    saved = await storage_service.save_file(file)
    if saved['file_type'] == 'application/pdf':
        raise HTTPException(400, 'Foto profil harus berupa JPG, JPEG, atau PNG.')
    current_user.avatar_url = saved['file_path']
    db.commit(); db.refresh(current_user)
    return ApiResponse(success=True, data={'avatar_url': current_user.avatar_url}, message='Foto profil berhasil diperbarui.')

@router.post("", response_model=ApiResponse[EvidenceResponse])
async def upload_evidence_file(
    file: UploadFile = File(...),
    journal_id: Optional[int] = Form(None),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    saved_meta = await storage_service.save_file(file)

    attachment = EvidenceAttachment(
        journal_id=journal_id,
        student_id=current_user.id,
        file_name=saved_meta["file_name"],
        file_path=saved_meta["file_path"],
        file_type=saved_meta["file_type"],
        file_size_bytes=saved_meta["file_size_bytes"]
    )
    db.add(attachment)
    db.commit()
    db.refresh(attachment)

    return ApiResponse(
        success=True,
        data=EvidenceResponse.model_validate(attachment),
        message="Berkas bukti kegiatan berhasil diunggah."
    )
