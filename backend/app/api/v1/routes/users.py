from typing import Optional, List
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from sqlalchemy import or_

from app.db.session import get_db
from app.core.security import verify_password, get_password_hash
from app.models.user import User, UserRole
from app.schemas.common import ApiResponse
from app.schemas.auth import UserResponse
from app.schemas.user import UserCreate, UserUpdate, ProfileUpdate, PasswordChange, UserListResponse
from app.services.access import scoped
from app.services.events import audit
from app.api.deps import get_current_user, get_current_admin

router = APIRouter()

@router.get("", response_model=ApiResponse[UserListResponse])
def get_users(
    q: Optional[str] = None,
    role: Optional[str] = None,
    include_inactive: bool = False,
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    query = scoped(db.query(User), User.id, db, current_user)
    if not include_inactive:
        query = query.filter(User.is_active == True)
    if role and role.lower() != 'semua':
        query = query.filter(User.role == role.upper())
    if q:
        search = f"%{q.strip()}%"
        query = query.filter(
            or_(
                User.username.ilike(search),
                User.full_name.ilike(search),
                User.email.ilike(search),
                User.student_class.ilike(search),
                User.department.ilike(search),
            )
        )

    total = query.count()
    items = query.order_by(User.id.desc()).offset(skip).limit(limit).all()

    return ApiResponse(
        success=True,
        data=UserListResponse(
            total=total,
            items=[UserResponse.model_validate(item) for item in items]
        ),
        message=f"Berhasil mengambil {len(items)} pengguna."
    )

@router.get("/me", response_model=ApiResponse[UserResponse])
def get_current_user_profile(
    current_user: User = Depends(get_current_user),
):
    return ApiResponse(
        success=True,
        data=UserResponse.model_validate(current_user),
        message="Profil pengguna berhasil dimuat."
    )

@router.put("/me/profile", response_model=ApiResponse[UserResponse])
def update_current_user_profile(
    payload: ProfileUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if payload.full_name is not None:
        current_user.full_name = payload.full_name
    if payload.email is not None:
        current_user.email = payload.email
    if payload.phone is not None:
        current_user.phone = payload.phone
    if payload.student_class is not None:
        current_user.student_class = payload.student_class
    if payload.department is not None:
        current_user.department = payload.department
    if payload.avatar_url is not None:
        raise HTTPException(400, "Gunakan unggah foto profil.")

    db.commit()
    db.refresh(current_user)

    return ApiResponse(
        success=True,
        data=UserResponse.model_validate(current_user),
        message="Profil berhasil diperbarui."
    )

@router.put("/me/password", response_model=ApiResponse[dict])
def change_password(
    payload: PasswordChange,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if not verify_password(payload.old_password, current_user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Kata sandi lama salah."
        )

    if len(payload.new_password) < 6:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Kata sandi baru minimal 6 karakter."
        )

    current_user.hashed_password = get_password_hash(payload.new_password)
    db.commit()

    return ApiResponse(
        success=True,
        data={"updated": True},
        message="Kata sandi berhasil diperbarui."
    )

from pydantic import BaseModel
class DeviceUpdateRequest(BaseModel):
    device_id: str
    device_model: Optional[str] = None

@router.put("/me/device", response_model=ApiResponse[UserResponse])
def update_current_user_device(
    payload: DeviceUpdateRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    current_user.device_id = payload.device_id
    if payload.device_model:
        current_user.device_model = payload.device_model
    db.commit()
    db.refresh(current_user)

    return ApiResponse(
        success=True,
        data=UserResponse.model_validate(current_user),
        message="Biometrik perangkat berhasil diperbarui."
    )

@router.get("/{user_id}", response_model=ApiResponse[UserResponse])
def get_user_by_id(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Pengguna tidak ditemukan.")
    return ApiResponse(
        success=True,
        data=UserResponse.model_validate(user),
        message="Detail pengguna ditemukan."
    )

@router.post("", response_model=ApiResponse[UserResponse])
def create_user(
    payload: UserCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_admin),
):
    existing = db.query(User).filter(User.username == payload.username).first()
    if existing:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Username / NISN sudah terdaftar.")

    try:
        user_role = UserRole(payload.role.lower())
    except ValueError:
        user_role = UserRole.SISWA

    new_user = User(
        username=payload.username.strip(),
        full_name=payload.full_name.strip(),
        email=payload.email.strip() if payload.email else None,
        hashed_password=get_password_hash(payload.password),
        role=user_role,
        department=payload.department,
        student_class=payload.student_class,
        phone=payload.phone,
        avatar_url=payload.avatar_url,
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    return ApiResponse(
        success=True,
        data=UserResponse.model_validate(new_user),
        message=f"Pengguna '{new_user.full_name}' berhasil ditambahkan ke sistem."
    )

@router.put("/{user_id}", response_model=ApiResponse[UserResponse])
@router.patch("/{user_id}", response_model=ApiResponse[UserResponse])
def update_user(
    user_id: int,
    payload: UserUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_admin),
):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Pengguna tidak ditemukan.")

    if payload.full_name is not None:
        user.full_name = payload.full_name
    if payload.email is not None:
        user.email = payload.email
    if payload.department is not None:
        user.department = payload.department
    if payload.student_class is not None:
        user.student_class = payload.student_class
    if payload.phone is not None:
        user.phone = payload.phone
    if payload.avatar_url is not None:
        raise HTTPException(400, "Gunakan unggah foto profil.")
    if payload.is_active is not None:
        user.is_active = payload.is_active
    if payload.role is not None:
        try:
            user.role = UserRole(payload.role.lower())
        except ValueError:
            pass
    if payload.password is not None and len(payload.password) >= 6:
        user.hashed_password = get_password_hash(payload.password)

    db.commit()
    db.refresh(user)

    return ApiResponse(
        success=True,
        data=UserResponse.model_validate(user),
        message=f"Data pengguna '{user.full_name}' berhasil diperbarui."
    )

@router.delete("/{user_id}", response_model=ApiResponse[dict])
def delete_user(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_admin),
):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Pengguna tidak ditemukan.")

    if user.id == current_user.id:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Tidak dapat menghapus akun Anda sendiri.")

    full_name = user.full_name

    # Clean up associated records across the database
    from app.models.report_ticket import ReportTicket, TicketMessage
    from app.models.journal import DailyJournal, EvidenceAttachment
    from app.models.journal_history import JournalHistory
    from app.models.submission import PklSubmission, PklEvidence
    from app.models.placement import PlacementAssignment
    from app.models.access import CompanyMember
    from app.models.attendance import AttendanceRecord
    from app.models.skill import SkillCompetency
    from app.models.notification import NotificationItem
    from app.models.audit_log import AuditLog

    # Clean tickets and messages
    db.query(TicketMessage).filter(TicketMessage.sender_id == user_id).delete(synchronize_session=False)
    db.query(ReportTicket).filter(ReportTicket.user_id == user_id).delete(synchronize_session=False)

    # Clean journals and attachments
    user_journals = db.query(DailyJournal).filter(DailyJournal.student_id == user_id).all()
    for j in user_journals:
        db.query(EvidenceAttachment).filter(EvidenceAttachment.journal_id == j.id).delete(synchronize_session=False)
        db.query(JournalHistory).filter(JournalHistory.journal_id == j.id).delete(synchronize_session=False)
        db.delete(j)

    # Clean submissions and evidences
    user_subs = db.query(PklSubmission).filter((PklSubmission.student_id == user_id) | (PklSubmission.teacher_id == user_id)).all()
    for s in user_subs:
        db.query(PklEvidence).filter(PklEvidence.submission_id == s.id).delete(synchronize_session=False)
        db.delete(s)
    db.query(PklEvidence).filter((PklEvidence.student_id == user_id) | (PklEvidence.verifier_id == user_id)).delete(synchronize_session=False)

    # Clean placements, members, attendances, competencies, notifications, audit logs, and actor histories
    db.query(JournalHistory).filter(JournalHistory.actor_id == user_id).delete(synchronize_session=False)
    db.query(PlacementAssignment).filter(PlacementAssignment.student_id == user_id).delete(synchronize_session=False)
    db.query(CompanyMember).filter(CompanyMember.user_id == user_id).delete(synchronize_session=False)
    db.query(AttendanceRecord).filter(AttendanceRecord.student_id == user_id).delete(synchronize_session=False)
    db.query(SkillCompetency).filter(SkillCompetency.student_id == user_id).delete(synchronize_session=False)
    db.query(NotificationItem).filter(NotificationItem.user_id == user_id).delete(synchronize_session=False)
    db.query(AuditLog).filter(AuditLog.actor_id == user_id).delete(synchronize_session=False)

    db.delete(user)
    db.commit()

    return ApiResponse(
        success=True,
        data={"deleted_id": user_id},
        message=f"Pengguna '{full_name}' telah dihapus secara permanen dari sistem."
    )
