from typing import Optional
from pydantic import BaseModel
from app.models.user import UserRole

class LoginRequest(BaseModel):
    username: str # NISN, NIP, Partner ID, or Admin
    password: str
    role: Optional[str] = None # siswa, guru, mitra, admin
    device_id: Optional[str] = "SKGT-DEV-8842"
    device_model: Optional[str] = "Samsung Galaxy A54 5G"

class RegisterRequest(BaseModel):
    username: str # NISN 10 digits
    full_name: str
    email: Optional[str] = None
    password: str
    role: str = "siswa"
    department: str = "Teknik Komputer dan Jaringan"
    student_class: Optional[str] = "XII TKJ 1"
    phone: Optional[str] = None
    device_id: Optional[str] = "SKGT-DEV-8842"
    device_model: Optional[str] = "Samsung Galaxy A54 5G"

class RefreshTokenRequest(BaseModel):
    refresh_token: str

class UserResponse(BaseModel):
    id: int
    username: str
    full_name: str
    email: Optional[str] = None
    role: str
    department: Optional[str] = None
    student_class: Optional[str] = None
    phone: Optional[str] = None
    avatar_url: Optional[str] = None
    device_id: Optional[str] = None
    device_model: Optional[str] = None

    class Config:
        from_attributes = True

class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    user: UserResponse

class DapodikVerificationResponse(BaseModel):
    nisn: str
    full_name: str
    school_name: str = "SMKN 3 Yogyakarta"
    department: str
    student_class: str
    status: str = "TERVERIFIKASI_DAPODIK"
