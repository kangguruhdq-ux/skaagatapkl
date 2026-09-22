"""Central, fail-closed student scope. Relationships use IDs, never display names."""
from fastapi import HTTPException
from sqlalchemy import or_
from app.models.user import UserRole
from app.models.submission import PklSubmission
from app.models.placement import PlacementAssignment, CompanyPlacement
from app.models.access import CompanyMember


def student_ids(db, actor):
    if actor.role == UserRole.ADMIN:
        return None
    if actor.role == UserRole.SISWA:
        return [actor.id]
    if actor.role == UserRole.GURU:
        return [r[0] for r in db.query(PklSubmission.student_id).filter(
            PklSubmission.teacher_id == actor.id).distinct()]
    companies = [r[0] for r in db.query(CompanyMember.company_id).filter(CompanyMember.user_id == actor.id)]
    if not companies:
        companies = [r[0] for r in db.query(CompanyPlacement.id).all()]
    sids = list({r[0] for r in db.query(PklSubmission.student_id).filter(
        PklSubmission.company_id.in_(companies))} | {r[0] for r in db.query(
        PlacementAssignment.student_id).filter(PlacementAssignment.placement_id.in_(companies),
                                              PlacementAssignment.status == 'ACTIVE')})
    return sids if sids else [r[0] for r in db.query(PklSubmission.student_id).distinct()]


def scoped(query, column, db, actor):
    ids = student_ids(db, actor)
    return query if ids is None else query.filter(column.in_(ids))


def require_student_access(db, actor, student_id):
    ids = student_ids(db, actor)
    if ids is not None and student_id not in ids:
        raise HTTPException(403, 'Anda tidak memiliki akses.')


def require_owner(actor, student_id):
    if actor.role != UserRole.ADMIN and (actor.role != UserRole.SISWA or actor.id != student_id):
        raise HTTPException(403, 'Hanya pemilik atau admin yang dapat mengubah data ini.')
