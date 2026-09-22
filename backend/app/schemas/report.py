from typing import Optional, List
from datetime import datetime
from pydantic import BaseModel

class TicketMessageCreate(BaseModel):
    message: str
    photo_url: Optional[str] = None

class TicketMessageResponse(BaseModel):
    id: int
    ticket_id: int
    sender_id: int
    sender_name: str
    sender_role: str
    message: str
    photo_url: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True

class ReportTicketCreate(BaseModel):
    title: str
    category: Optional[str] = "BUG"
    priority: Optional[str] = "NORMAL"
    description: str
    photo_url: Optional[str] = None

class ReportTicketUpdate(BaseModel):
    status: Optional[str] = None
    admin_notes: Optional[str] = None

class ReportTicketResponse(BaseModel):
    id: int
    ticket_number: str
    user_id: int
    user_name: str
    user_role: str
    user_department: Optional[str] = None
    user_class: Optional[str] = None
    title: str
    category: str
    priority: str
    description: str
    photo_url: Optional[str] = None
    status: str
    admin_notes: Optional[str] = None
    created_at: datetime
    updated_at: datetime
    messages: List[TicketMessageResponse] = []

    class Config:
        from_attributes = True
