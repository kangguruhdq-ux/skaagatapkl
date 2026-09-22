from typing import Optional, List
from pydantic import BaseModel

class CompanyCreate(BaseModel):
    name: str
    division: Optional[str] = "Divisi Operasional"
    industry_sector: Optional[str] = None
    address: str
    latitude: Optional[float] = -7.7854
    longitude: Optional[float] = 110.3722
    geofence_radius: Optional[float] = 100.0
    mentor_name: Optional[str] = None
    contact_person: Optional[str] = None
    mentor_phone: Optional[str] = None
    phone: Optional[str] = None
    quota: Optional[int] = 10
    supervisor_name: Optional[str] = None
    supervisor_phone: Optional[str] = None
    period_start: Optional[str] = "15 Jul 2024"
    period_end: Optional[str] = "15 Des 2024"
    code: Optional[str] = "PKL-2024"
    is_active: Optional[bool] = True

class CompanyUpdate(BaseModel):
    name: Optional[str] = None
    division: Optional[str] = None
    industry_sector: Optional[str] = None
    address: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    geofence_radius: Optional[float] = None
    mentor_name: Optional[str] = None
    contact_person: Optional[str] = None
    mentor_phone: Optional[str] = None
    phone: Optional[str] = None
    quota: Optional[int] = None
    supervisor_name: Optional[str] = None
    supervisor_phone: Optional[str] = None
    is_active: Optional[bool] = None

class CompanyResponse(BaseModel):
    id: int
    name: str
    division: Optional[str] = None
    address: str
    latitude: float
    longitude: float
    geofence_radius: float
    mentor_name: Optional[str] = None
    mentor_phone: Optional[str] = None
    supervisor_name: Optional[str] = None
    supervisor_phone: Optional[str] = None
    period_start: Optional[str] = None
    period_end: Optional[str] = None
    code: Optional[str] = None
    is_active: bool
    student_count: Optional[int] = 0

    class Config:
        from_attributes = True

class CompanyListResponse(BaseModel):
    items: List[CompanyResponse]
    total: int
