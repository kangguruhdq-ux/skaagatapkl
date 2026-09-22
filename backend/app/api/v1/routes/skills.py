from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.models.user import User, UserRole
from app.models.skill import SkillCompetency
from app.schemas.common import ApiResponse
from app.schemas.skill import IndustryGapSummary, SkillCompetencyResponse
from app.api.deps import get_current_user

router = APIRouter()

@router.get("/gap-analysis", response_model=ApiResponse[IndustryGapSummary])
def get_gap_analysis(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if current_user.role != UserRole.SISWA:
        from fastapi import HTTPException
        raise HTTPException(403, "Analisis kompetensi hanya dapat melihat data akun sendiri.")
    student = current_user

    skills = db.query(SkillCompetency).filter(
        SkillCompetency.student_id == student.id
    ).all()

    return ApiResponse(
        success=True,
        data=IndustryGapSummary(
            student_name=student.full_name,
            target_role="Praktikan PKL" if skills else "Belum Menentukan Target Peran",
            readiness_index_pct=round(sum(s.student_mastery_pct for s in skills) / len(skills), 1) if skills else 0.0,
            validated_dudi_units=len([s for s in skills if s.audit_tier == "SUPERVISOR"]),
            evidence_logs_count=len(skills),
            telemetry_sync_status="Real-time",
            period="T.A. 2024/2025" if skills else "-",
            skills=[SkillCompetencyResponse.model_validate(s) for s in skills]
        ),
        message="Analisis kebutuhan industri dan kesiapan siswa berhasil dimuat."
    )

