from typing import Optional, List
from datetime import datetime
from pydantic import BaseModel

class SubmissionCreate(BaseModel):
    company_name: str
    company_address: str
    company_phone: Optional[str] = None
    company_email: Optional[str] = None
    company_website: Optional[str] = None
    industry_sector: Optional[str] = None
    division: Optional[str] = None
    start_date: str
    end_date: str
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    mentor_name: Optional[str] = None
    mentor_contact: Optional[str] = None
    teacher_id: Optional[int] = None
    document_url: Optional[str] = None

class SubmissionUpdate(BaseModel):
    company_name: Optional[str] = None
    company_address: Optional[str] = None
    company_phone: Optional[str] = None
    company_email: Optional[str] = None
    company_website: Optional[str] = None
    industry_sector: Optional[str] = None
    division: Optional[str] = None
    start_date: Optional[str] = None
    end_date: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    mentor_name: Optional[str] = None
    mentor_contact: Optional[str] = None
    document_url: Optional[str] = None

class SubmissionChangeRequest(BaseModel):
    target_company_id: Optional[int] = None
    new_company_name: Optional[str] = None
    new_address: Optional[str] = None
    new_contact: Optional[str] = None
    change_reason: str
    new_start_date: Optional[str] = None
    new_end_date: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    supporting_doc_url: Optional[str] = None

class SubmissionReview(BaseModel):
    action: Optional[str] = None # "APPROVE", "REJECT", "REVISION"
    status: Optional[str] = None
    notes: Optional[str] = None
    supervisor_notes: Optional[str] = None

class SubmissionResponse(BaseModel):
    id: int
    student_id: int
    student_name: Optional[str] = None
    student_class: Optional[str] = None
    company_id: Optional[int] = None
    company_name: str
    company_address: str
    company_phone: Optional[str] = None
    company_email: Optional[str] = None
    company_website: Optional[str] = None
    industry_sector: Optional[str] = None
    division: Optional[str] = None
    start_date: str
    end_date: str
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    mentor_name: Optional[str] = None
    mentor_contact: Optional[str] = None
    teacher_id: Optional[int] = None
    teacher_name: Optional[str] = None
    status: str
    teacher_notes: Optional[str] = None
    change_reason: Optional[str] = None
    previous_company_name: Optional[str] = None
    document_url: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True

class SubmissionListResponse(BaseModel):
    items: List[SubmissionResponse]
    total: int

class EvidenceCreate(BaseModel):
    title: str
    category: str # FOTO_KEGIATAN, SURAT, DOKUMEN, SERTIFIKAT, LAPORAN
    file_url: str
    description: Optional[str] = None
    activity_date: Optional[str] = None
    submission_id: Optional[int] = None

class EvidenceVerify(BaseModel):
    action: Optional[str] = None # "VERIFY", "REJECT", "REVISION"
    status: Optional[str] = None
    notes: Optional[str] = None
    review_notes: Optional[str] = None

class EvidenceResponse(BaseModel):
    id: int
    student_id: int
    student_name: Optional[str] = None
    student_class: Optional[str] = None
    company_name: Optional[str] = None
    submission_id: Optional[int] = None
    title: str
    category: str
    file_url: str
    description: Optional[str] = None
    activity_date: Optional[str] = None
    status: str
    verifier_id: Optional[int] = None
    verifier_name: Optional[str] = None
    verifier_notes: Optional[str] = None
    verified_at: Optional[datetime] = None
    created_at: datetime

    class Config:
        from_attributes = True

class EvidenceListResponse(BaseModel):
    items: List[EvidenceResponse]
    total: int
