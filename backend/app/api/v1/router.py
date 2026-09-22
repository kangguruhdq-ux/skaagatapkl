from fastapi import APIRouter
from app.api.v1.routes import (
    auth,
    dashboard,
    attendance,
    journals,
    skills,
    notifications,
    placements,
    uploads,
    users,
    admin,
    submissions,
    evidences,
    audit,
    reports,
    tickets,
)

api_router = APIRouter()

api_router.include_router(auth.router, prefix="/auth", tags=["Authentication"])
api_router.include_router(dashboard.router, prefix="/dashboard", tags=["Dashboard"])
api_router.include_router(attendance.router, prefix="/attendance", tags=["Attendance"])
api_router.include_router(journals.router, prefix="/journals", tags=["Journals"])
api_router.include_router(skills.router, prefix="/skills", tags=["Skills Engine"])
api_router.include_router(notifications.router, prefix="/notifications", tags=["Notifications"])
api_router.include_router(placements.router, prefix="/placements", tags=["Placements"])
api_router.include_router(uploads.router, prefix="/upload", tags=["Uploads"])
api_router.include_router(users.router, prefix="/users", tags=["User Management"])
api_router.include_router(admin.router, prefix="/admin", tags=["Admin Portal"])
api_router.include_router(submissions.router, prefix="/submissions", tags=["PKL Submissions"])
api_router.include_router(evidences.router, prefix="/evidences", tags=["PKL Evidences"])
api_router.include_router(audit.router, prefix="/audit", tags=["Audit Logs"])
api_router.include_router(reports.router, prefix="/reports", tags=["Reports & Exports"])
api_router.include_router(tickets.router, prefix="/tickets", tags=["Helpdesk & Bug Reports"])


