import random
from datetime import datetime
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status, UploadFile, File
from sqlalchemy.orm import Session
from sqlalchemy import or_

from app.db.session import get_db
from app.models.user import User, UserRole
from app.models.report_ticket import ReportTicket, TicketMessage
from app.schemas.common import ApiResponse
from app.schemas.report import (
    ReportTicketCreate,
    ReportTicketUpdate,
    ReportTicketResponse,
    TicketMessageCreate,
    TicketMessageResponse,
)
from app.services.storage import storage_service
from app.api.deps import get_current_user

router = APIRouter()

@router.post("/upload-photo", response_model=ApiResponse[dict])
async def upload_ticket_photo(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
):
    saved_meta = await storage_service.save_file(file)
    return ApiResponse(
        success=True,
        data={
            "file_path": saved_meta["file_path"],
            "file_name": saved_meta["file_name"],
            "file_size_bytes": saved_meta["file_size_bytes"],
        },
        message="Foto bukti kendala berhasil diunggah."
    )

def _to_message_response(msg: TicketMessage, db: Session) -> TicketMessageResponse:
    sender = db.query(User).filter(User.id == msg.sender_id).first()
    sender_name = sender.full_name if sender else "Pengguna"
    sender_role = (sender.role.value if hasattr(sender.role, 'value') else str(sender.role)) if sender else "USER"
    return TicketMessageResponse(
        id=msg.id,
        ticket_id=msg.ticket_id,
        sender_id=msg.sender_id,
        sender_name=sender_name,
        sender_role=sender_role,
        message=msg.message,
        photo_url=msg.photo_url,
        created_at=msg.created_at,
    )

def _to_ticket_response(ticket: ReportTicket, db: Session) -> ReportTicketResponse:
    user = db.query(User).filter(User.id == ticket.user_id).first()
    user_name = user.full_name if user else "Pengguna"
    user_role = (user.role.value if hasattr(user.role, 'value') else str(user.role)) if user else "USER"
    
    messages_resp = [_to_message_response(m, db) for m in ticket.messages]
    
    return ReportTicketResponse(
        id=ticket.id,
        ticket_number=ticket.ticket_number,
        user_id=ticket.user_id,
        user_name=user_name,
        user_role=user_role,
        user_department=user.department if user else None,
        user_class=user.student_class if user else None,
        title=ticket.title,
        category=ticket.category,
        priority=ticket.priority,
        description=ticket.description,
        photo_url=ticket.photo_url,
        status=ticket.status,
        admin_notes=ticket.admin_notes,
        created_at=ticket.created_at,
        updated_at=ticket.updated_at,
        messages=messages_resp,
    )

@router.get("", response_model=ApiResponse[List[ReportTicketResponse]])
def get_tickets(
    status_filter: Optional[str] = Query(None, alias="status"),
    q: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    query = db.query(ReportTicket)
    
    # Non-admin users only see their own tickets
    if current_user.role != UserRole.ADMIN:
        query = query.filter(ReportTicket.user_id == current_user.id)
        
    if status_filter and status_filter.lower() != "all":
        query = query.filter(ReportTicket.status == status_filter.upper())
        
    if q:
        search = f"%{q.strip()}%"
        query = query.filter(
            or_(
                ReportTicket.ticket_number.ilike(search),
                ReportTicket.title.ilike(search),
                ReportTicket.description.ilike(search),
            )
        )
        
    tickets = query.order_by(ReportTicket.created_at.desc()).all()
    results = [_to_ticket_response(t, db) for t in tickets]
    
    return ApiResponse(
        success=True,
        data=results,
        message=f"Berhasil memuat {len(results)} tiket laporan."
    )

@router.post("", response_model=ApiResponse[ReportTicketResponse], status_code=status.HTTP_201_CREATED)
def create_ticket(
    ticket_in: ReportTicketCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    # Generate unique ticket number: RPT-YYYY-XXXXX
    year = datetime.utcnow().year
    random_code = random.randint(1000, 9999)
    count = db.query(ReportTicket).count() + 1
    ticket_number = f"RPT-{year}-{count:04d}-{random_code}"
    
    new_ticket = ReportTicket(
        ticket_number=ticket_number,
        user_id=current_user.id,
        title=ticket_in.title.strip(),
        category=(ticket_in.category or "BUG").upper(),
        priority=(ticket_in.priority or "NORMAL").upper(),
        description=ticket_in.description.strip(),
        photo_url=ticket_in.photo_url,
        status="PENDING",
    )
    db.add(new_ticket)
    db.commit()
    db.refresh(new_ticket)
    
    return ApiResponse(
        success=True,
        data=_to_ticket_response(new_ticket, db),
        message=f"Tiket laporan {new_ticket.ticket_number} berhasil dibuat."
    )

@router.get("/{id}", response_model=ApiResponse[ReportTicketResponse])
def get_ticket_detail(
    id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    ticket = db.query(ReportTicket).filter(ReportTicket.id == id).first()
    if not ticket:
        raise HTTPException(status_code=404, detail="Tiket laporan tidak ditemukan.")
        
    if current_user.role != UserRole.ADMIN and ticket.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Anda tidak memiliki akses ke tiket ini.")
        
    return ApiResponse(
        success=True,
        data=_to_ticket_response(ticket, db),
        message="Detail tiket laporan berhasil dimuat."
    )

@router.patch("/{id}/status", response_model=ApiResponse[ReportTicketResponse])
def update_ticket_status(
    id: int,
    update_in: ReportTicketUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if current_user.role != UserRole.ADMIN:
        raise HTTPException(status_code=403, detail="Hanya Admin yang dapat mengubah status tiket.")
        
    ticket = db.query(ReportTicket).filter(ReportTicket.id == id).first()
    if not ticket:
        raise HTTPException(status_code=404, detail="Tiket laporan tidak ditemukan.")
        
    if update_in.status:
        ticket.status = update_in.status.upper()
    if update_in.admin_notes is not None:
        ticket.admin_notes = update_in.admin_notes.strip()
        
    ticket.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(ticket)
    
    return ApiResponse(
        success=True,
        data=_to_ticket_response(ticket, db),
        message=f"Status tiket {ticket.ticket_number} berhasil diperbarui menjadi {ticket.status}."
    )

@router.post("/{id}/messages", response_model=ApiResponse[TicketMessageResponse], status_code=status.HTTP_201_CREATED)
def send_ticket_message(
    id: int,
    msg_in: TicketMessageCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    ticket = db.query(ReportTicket).filter(ReportTicket.id == id).first()
    if not ticket:
        raise HTTPException(status_code=404, detail="Tiket laporan tidak ditemukan.")
        
    if current_user.role != UserRole.ADMIN and ticket.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Anda tidak memiliki akses ke tiket ini.")
        
    if not msg_in.message.strip() and not msg_in.photo_url:
        raise HTTPException(status_code=400, detail="Pesan atau lampiran foto tidak boleh kosong.")
        
    message = TicketMessage(
        ticket_id=ticket.id,
        sender_id=current_user.id,
        message=msg_in.message.strip(),
        photo_url=msg_in.photo_url,
    )
    db.add(message)
    
    # If admin replied and ticket was PENDING, auto mark IN_PROGRESS
    if current_user.role == UserRole.ADMIN and ticket.status == "PENDING":
        ticket.status = "IN_PROGRESS"
        
    ticket.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(message)
    
    return ApiResponse(
        success=True,
        data=_to_message_response(message, db),
        message="Pesan balasan tiket berhasil dikirim."
    )

@router.delete("/{id}", response_model=ApiResponse[dict])
def delete_ticket(
    id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    ticket = db.query(ReportTicket).filter(ReportTicket.id == id).first()
    if not ticket:
        raise HTTPException(status_code=404, detail="Tiket laporan tidak ditemukan.")
        
    if current_user.role != UserRole.ADMIN and ticket.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Hanya pemilik tiket atau admin yang dapat menghapus tiket ini.")
        
    ticket_no = ticket.ticket_number
    db.delete(ticket)
    db.commit()
    
    return ApiResponse(
        success=True,
        data={"id": id, "ticket_number": ticket_no},
        message=f"Tiket laporan {ticket_no} berhasil dihapus."
    )
