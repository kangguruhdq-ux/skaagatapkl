from typing import Optional, List, Any
from datetime import datetime
from pydantic import BaseModel

class SkillTag(BaseModel):
    name: str
    score: int # percentage, e.g. 98

class JournalCreate(BaseModel):
    work_summary: str
    hours_spent: Optional[float] = 8.5
    standard_competency: Optional[str] = "Admin Jaringan Lv. 2"
    competency_category: Optional[str] = "SKKNI Kategori J.61"
    complexity_level: Optional[str] = "INTERMEDIATE"
    complexity_tier: Optional[str] = "Tier: Teknisi Madya"
    workflow_stage: Optional[int] = 1 # 1: Draft, 2: Submit, 3: AI Sync, 4: Review, 5: Approved

class JournalUpdate(BaseModel):
    work_summary: Optional[str] = None
    hours_spent: Optional[float] = None
    standard_competency: Optional[str] = None
    complexity_level: Optional[str] = None
    workflow_stage: Optional[int] = None
    status: Optional[str] = None
    revision_notes: Optional[str] = None

class JournalReviewRequest(BaseModel):
    approved: Optional[bool] = None
    status: Optional[str] = None
    notes: Optional[str] = None

class AiAnalysisRequest(BaseModel):
    text: str

class AiAnalysisResponse(BaseModel):
    match_percentage: float
    standard_competency: str
    competency_category: str
    complexity_level: str
    complexity_tier: str
    extracted_skills: List[SkillTag]
    detected_tools: List[str]

class EvidenceResponse(BaseModel):
    id: int
    journal_id: Optional[int] = None
    file_name: str
    file_path: str
    file_type: str
    file_size_bytes: int

    class Config:
        from_attributes = True

class JournalResponse(BaseModel):
    id: int
    student_id: int
    placement_id: int
    date: str
    day_number: int
    hours_spent: float
    work_summary: str
    standard_competency: str
    competency_category: str
    complexity_level: str
    complexity_tier: str
    ai_match_percentage: float
    ai_extracted_skills: Optional[str] = None
    detected_tools: Optional[str] = None
    workflow_stage: int
    status: str
    revision_notes: Optional[str] = None
    is_urgent_revision: bool
    student_name: Optional[str] = None
    reviewer_name: Optional[str] = None
    reviewed_at: Optional[datetime] = None
    created_at: datetime
    photo_url: Optional[str] = None
    attachments: List[EvidenceResponse] = []

    class Config:
        from_attributes = True

class JournalHistoryResponse(BaseModel):
    id: int
    journal_id: int
    previous_status: Optional[str] = None
    new_status: str
    actor_id: int
    reviewer: str
    comment: Optional[str] = None
    timestamp: datetime

    class Config:
        from_attributes = True
