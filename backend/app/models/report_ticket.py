from datetime import datetime
from sqlalchemy import Column, Integer, String, Text, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from app.db.session import Base

class ReportTicket(Base):
    __tablename__ = "report_tickets"

    id = Column(Integer, primary_key=True, index=True)
    ticket_number = Column(String(50), unique=True, index=True, nullable=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    title = Column(String(255), nullable=False)
    category = Column(String(100), default="BUG") # BUG, PRESENSI, PENEMPATAN, JURNAL, LAINNYA
    priority = Column(String(50), default="NORMAL") # NORMAL, TINGGI, MENDESAK
    description = Column(Text, nullable=False)
    photo_url = Column(String(500), nullable=True)
    status = Column(String(50), default="PENDING") # PENDING, IN_PROGRESS, RESOLVED, CLOSED
    admin_notes = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    user = relationship("User", foreign_keys=[user_id])
    messages = relationship(
        "TicketMessage",
        back_populates="ticket",
        cascade="all, delete-orphan",
        order_by="TicketMessage.created_at.asc()"
    )

class TicketMessage(Base):
    __tablename__ = "ticket_messages"

    id = Column(Integer, primary_key=True, index=True)
    ticket_id = Column(Integer, ForeignKey("report_tickets.id"), nullable=False)
    sender_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    message = Column(Text, nullable=False)
    photo_url = Column(String(500), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    ticket = relationship("ReportTicket", back_populates="messages")
    sender = relationship("User", foreign_keys=[sender_id])
