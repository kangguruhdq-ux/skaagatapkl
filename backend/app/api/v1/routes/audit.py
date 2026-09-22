from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import Optional

from app.db.session import get_db
from app.models.user import User, UserRole
from app.models.audit_log import AuditLog
from app.schemas.common import ApiResponse
from app.schemas.audit import AuditLogResponse, AuditLogListResponse
from app.api.deps import require_roles

router = APIRouter()

@router.get("/logs", response_model=ApiResponse[AuditLogListResponse])
def get_audit_logs(
    role: Optional[str] = None,
    module: Optional[str] = None,
    action: Optional[str] = None,
    search: Optional[str] = None,
    limit: int = Query(50, ge=1, le=200),
    skip: int = Query(0, ge=0),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(["admin", "guru"]))
):
    query = db.query(AuditLog)

    if role:
        query = query.filter(AuditLog.actor_role == role.lower())
    if module:
        query = query.filter(AuditLog.module == module.upper())
    if action:
        query = query.filter(AuditLog.action.ilike(f"%{action}%"))
    if search:
        s = f"%{search}%"
        query = query.filter(
            (AuditLog.description.ilike(s)) |
            (AuditLog.actor_name.ilike(s)) |
            (AuditLog.action.ilike(s))
        )

    total = query.count()
    logs = query.order_by(AuditLog.timestamp.desc()).offset(skip).limit(limit).all()

    items = [AuditLogResponse.model_validate(log) for log in logs]

    return ApiResponse(
        success=True,
        data=AuditLogListResponse(items=items, total=total),
        message="Daftar log audit sistem berhasil dimuat."
    )

@router.delete("/logs/{id}", response_model=ApiResponse[dict])
def delete_audit_log(
    id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(["admin"]))
):
    log = db.query(AuditLog).filter(AuditLog.id == id).first()
    if not log:
        raise HTTPException(status_code=404, detail="Log audit tidak ditemukan.")
    db.delete(log)
    db.commit()
    return ApiResponse(success=True, data={"id": id}, message="Log audit berhasil dihapus.")

@router.delete("/logs", response_model=ApiResponse[dict])
def clear_audit_logs(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(["admin"]))
):
    count = db.query(AuditLog).delete()
    db.commit()
    return ApiResponse(success=True, data={"deleted_count": count}, message=f"Semua log audit ({count} entri) berhasil dibersihkan.")

