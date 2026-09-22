from typing import Optional, List
from pydantic import BaseModel
from app.schemas.auth import UserResponse

class UserCreate(BaseModel):
    username: str
    password: str
    full_name: str
    email: Optional[str] = None
    role: str = "siswa" # siswa, guru, mitra, admin
    department: Optional[str] = "Teknik Komputer dan Jaringan"
    student_class: Optional[str] = None
    phone: Optional[str] = None
    avatar_url: Optional[str] = None

class UserUpdate(BaseModel):
    full_name: Optional[str] = None
    email: Optional[str] = None
    role: Optional[str] = None
    department: Optional[str] = None
    student_class: Optional[str] = None
    phone: Optional[str] = None
    password: Optional[str] = None
    avatar_url: Optional[str] = None
    is_active: Optional[bool] = None

class ProfileUpdate(BaseModel):
    full_name: Optional[str] = None
    email: Optional[str] = None
    phone: Optional[str] = None
    student_class: Optional[str] = None
    department: Optional[str] = None
    avatar_url: Optional[str] = None

class PasswordChange(BaseModel):
    old_password: str
    new_password: str

class UserListResponse(BaseModel):
    total: int
    items: List[UserResponse]
