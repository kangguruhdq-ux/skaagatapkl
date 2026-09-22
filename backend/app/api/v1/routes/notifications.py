from typing import List
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.models.user import User
from app.models.notification import NotificationItem
from app.schemas.common import ApiResponse
from app.schemas.notification import NotificationResponse
from app.api.deps import get_current_user

router = APIRouter()

@router.get("", response_model=ApiResponse[List[NotificationResponse]])
def get_notifications(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    notifications = db.query(NotificationItem).filter(
        NotificationItem.user_id == current_user.id
    ).order_by(NotificationItem.id.desc()).all()

    return ApiResponse(
        success=True,
        data=[NotificationResponse.model_validate(n) for n in notifications],
        message="Notifikasi berhasil dimuat."
    )

@router.patch("/{notification_id}/read", response_model=ApiResponse[NotificationResponse])
def mark_notification_read(
    notification_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    item = db.query(NotificationItem).filter(
        NotificationItem.id == notification_id,
        NotificationItem.user_id == current_user.id
    ).first()

    if item:
        item.is_read = True
        db.commit()
        db.refresh(item)

    return ApiResponse(
        success=True,
        data=NotificationResponse.model_validate(item) if item else None,
        message="Status notifikasi diperbarui."
    )

@router.delete("/{notification_id}", response_model=ApiResponse[dict])
def delete_notification(
    notification_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    item = db.query(NotificationItem).filter(
        NotificationItem.id == notification_id,
        NotificationItem.user_id == current_user.id
    ).first()

    if not item:
        return ApiResponse(
            success=False,
            error="Notifikasi tidak ditemukan.",
            message="Notifikasi tidak ditemukan."
        )

    db.delete(item)
    db.commit()

    return ApiResponse(
        success=True,
        data={"deleted_id": notification_id},
        message="Notifikasi berhasil dihapus."
    )

@router.delete("", response_model=ApiResponse[dict])
def clear_all_notifications(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    deleted_count = db.query(NotificationItem).filter(
        NotificationItem.user_id == current_user.id
    ).delete(synchronize_session=False)
    db.commit()

    return ApiResponse(
        success=True,
        data={"deleted_count": deleted_count},
        message=f"{deleted_count} notifikasi berhasil dibersihkan."
    )

