from typing import List, Optional
from pydantic import BaseModel

class SkillCompetencyResponse(BaseModel):
    id: int
    name: str
    category: str
    industry_demand_pct: float
    student_mastery_pct: float
    gap_percentage: float
    status: str # GAP, SURPLUS, MATCH
    recommendation: str
    audit_tier: str
    skkni_code: Optional[str] = None
    validated_units: int
    evidence_logs_count: int

    class Config:
        from_attributes = True

class IndustryGapSummary(BaseModel):
    student_name: str
    target_role: str = "Belum Ditentukan"
    readiness_index_pct: float = 0.0
    validated_dudi_units: int = 0
    evidence_logs_count: int = 0
    telemetry_sync_status: str = "Real-time"
    period: str = "-"
    skills: List[SkillCompetencyResponse]
