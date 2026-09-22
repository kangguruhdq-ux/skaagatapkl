from datetime import datetime, date
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.core.config import settings
from app.db.session import get_db
from app.models.user import User, UserRole
from app.models.placement import CompanyPlacement, PlacementAssignment
from app.models.submission import PklSubmission
from app.models.attendance import AttendanceRecord
from app.schemas.common import ApiResponse
from app.schemas.attendance import CheckInRequest, CheckOutRequest, AttendanceResponse, AttendanceStatusResponse, AttendanceReviewRequest
from app.services.geofence import verify_geofence
from app.services.storage import storage_service
from app.services.audit_service import log_activity
from app.api.deps import get_current_user

router=APIRouter()

def student_company(db, student):
    assignment=db.query(PlacementAssignment).filter(PlacementAssignment.student_id==student.id, PlacementAssignment.status=='ACTIVE').first()
    if assignment: return db.query(CompanyPlacement).filter(CompanyPlacement.id==assignment.placement_id).first()
    submission=db.query(PklSubmission).filter(PklSubmission.student_id==student.id, PklSubmission.status=='APPROVED').order_by(PklSubmission.updated_at.desc()).first()
    return db.query(CompanyPlacement).filter(CompanyPlacement.id==submission.company_id).first() if submission and submission.company_id else None

def allowed_student(db, actor, student_id):
    if actor.role == UserRole.ADMIN or actor.role == UserRole.SISWA and actor.id == student_id: return True
    if actor.role == UserRole.GURU:
        return db.query(PklSubmission.id).filter(PklSubmission.student_id==student_id, PklSubmission.teacher_id==actor.id).first() is not None
    return False

def format_attendance(r, db):
    data=AttendanceResponse.model_validate(r)
    student=r.student or db.query(User).filter(User.id==r.student_id).first()
    if student: data.student_name=student.full_name; data.student_nisn=student.username
    return data

@router.get('/status', response_model=ApiResponse[AttendanceStatusResponse])
def get_attendance_status(current_user: User=Depends(get_current_user), db: Session=Depends(get_db)):
    if current_user.role != UserRole.SISWA: raise HTTPException(403, 'Status presensi tersedia untuk akun siswa.')
    company=student_company(db,current_user)
    today=date.today().isoformat(); record=db.query(AttendanceRecord).filter_by(student_id=current_user.id,date=today).first()
    rows=db.query(AttendanceRecord).filter(AttendanceRecord.student_id==current_user.id).all()
    present=sum(1 for r in rows if r.status=='HADIR' and r.approval_status=='APPROVED')
    permitted=sum(1 for r in rows if r.status in ('IZIN','SAKIT') and r.approval_status=='APPROVED')
    alpha=sum(1 for r in rows if r.status=='ALPA' and r.approval_status=='APPROVED')
    rate=round(present/len(rows)*100,1) if rows else 0.0
    return ApiResponse(
        success=True,
        data=AttendanceStatusResponse(
            has_checked_in_today=bool(record and record.check_in_time),
            has_checked_out_today=bool(record and record.check_out_time),
            today_record=format_attendance(record,db) if record else None,
            target_latitude=company.latitude if company else 0.0,
            target_longitude=company.longitude if company else 0.0,
            geofence_radius=company.geofence_radius if company else 0.0,
            company_name=company.name if company else 'Belum Ada Penempatan',
            shift_name='Shift Reguler Pagi (08:00 - 16:30 WIB)' if company else '-',
            total_days_attended=present,
            total_days_permitted=permitted,
            total_days_alpha=alpha,
            attendance_rate_pct=rate
        ),
        message='Status presensi berhasil dimuat.'
    )

@router.post('/check-in', response_model=ApiResponse[AttendanceResponse])
def check_in(request: CheckInRequest,current_user: User=Depends(get_current_user),db: Session=Depends(get_db)):
    if current_user.role != UserRole.SISWA: raise HTTPException(403,'Hanya siswa yang dapat melakukan presensi.')
    if not request.selfie_url or not request.selfie_url.startswith('/uploads/'):
        raise HTTPException(422,'Foto selfie wajib diunggah sebelum presensi.')
    storage_service.resolve(request.selfie_url)
    company=student_company(db,current_user)
    if not company: raise HTTPException(409,'Penempatan PKL aktif belum tersedia.')
    inside,distance=verify_geofence(request.latitude,request.longitude,company.latitude,company.longitude,company.geofence_radius)
    today=date.today().isoformat(); existing=db.query(AttendanceRecord).filter_by(student_id=current_user.id,date=today).first()
    now=datetime.utcnow(); values=dict(check_in_time=now,latitude=request.latitude,longitude=request.longitude,distance_meters=distance,is_in_radius=inside,accuracy_meters=request.accuracy_meters,device_fingerprint=request.device_fingerprint or current_user.device_id,status='HADIR' if inside else 'DILUAR_RADIUS',selfie_url=request.selfie_url,approval_status='PENDING',verified_by_mentor=False,notes=request.notes,placement_id=company.id,shift_name='Shift Reguler Pagi (08:00 - 16:30 WIB)')
    if existing:
        for key,val in values.items(): setattr(existing,key,val)
        record=existing
    else: record=AttendanceRecord(student_id=current_user.id,date=today,**values); db.add(record)
    db.commit(); db.refresh(record)
    log_activity(db,current_user.id,current_user.full_name,current_user.role.value,'CHECK_IN','ATTENDANCE','AttendanceRecord',str(record.id),'Presensi selfie dan GPS dikirim untuk persetujuan guru.')
    return ApiResponse(success=True,data=format_attendance(record,db),message='Presensi dikirim. Menunggu ACC Guru.')

@router.post('/check-out', response_model=ApiResponse[AttendanceResponse])
def check_out(request: CheckOutRequest,current_user: User=Depends(get_current_user),db: Session=Depends(get_db)):
    if current_user.role != UserRole.SISWA: raise HTTPException(403,'Hanya siswa yang dapat melakukan presensi.')
    record=db.query(AttendanceRecord).filter_by(student_id=current_user.id,date=date.today().isoformat()).first()
    if not record: raise HTTPException(400,'Anda belum melakukan presensi masuk hari ini.')
    record.check_out_time=datetime.utcnow(); record.notes=(record.notes or '') + (f' | Pulang: {request.notes}' if request.notes else '')
    db.commit(); db.refresh(record); return ApiResponse(success=True,data=format_attendance(record,db),message='Presensi pulang tercatat.')

@router.get('/history', response_model=ApiResponse[list[AttendanceResponse]])
def history(current_user: User=Depends(get_current_user),db: Session=Depends(get_db)):
    if current_user.role != UserRole.SISWA: raise HTTPException(403,'Gunakan daftar presensi guru untuk akun pembimbing.')
    rows=db.query(AttendanceRecord).filter_by(student_id=current_user.id).order_by(AttendanceRecord.id.desc()).limit(100).all()
    return ApiResponse(success=True,data=[format_attendance(r,db) for r in rows],message='Riwayat presensi berhasil dimuat.')

@router.get('/records', response_model=ApiResponse[list[AttendanceResponse]])
def records(current_user: User=Depends(get_current_user),db: Session=Depends(get_db)):
    if current_user.role not in (UserRole.GURU,UserRole.ADMIN): raise HTTPException(403,'Hanya Guru/Admin yang dapat melihat seluruh presensi.')
    query=db.query(AttendanceRecord)
    if current_user.role == UserRole.GURU:
        query=query.join(PklSubmission,PklSubmission.student_id==AttendanceRecord.student_id).filter(PklSubmission.teacher_id==current_user.id)
    rows=query.order_by(AttendanceRecord.id.desc()).distinct().all()
    return ApiResponse(success=True,data=[format_attendance(r,db) for r in rows],message=f'Berhasil memuat {len(rows)} data presensi.')

@router.patch('/{id}/review', response_model=ApiResponse[AttendanceResponse])
def review(id:int,payload:AttendanceReviewRequest,db:Session=Depends(get_db),current_user:User=Depends(get_current_user)):
    if current_user.role not in (UserRole.GURU,UserRole.ADMIN): raise HTTPException(403,'Hanya Guru atau Admin yang dapat menyetujui presensi.')
    record=db.query(AttendanceRecord).filter_by(id=id).first()
    if not record: raise HTTPException(404,'Data presensi tidak ditemukan.')
    if not allowed_student(db,current_user,record.student_id): raise HTTPException(403,'Siswa bukan bimbingan Anda.')
    action=payload.action.upper()
    if action not in ('APPROVE','REJECT'): raise HTTPException(400,'Aksi harus APPROVE atau REJECT.')
    record.approval_status='APPROVED' if action=='APPROVE' else 'REJECTED'; record.verified_by_mentor=action=='APPROVE'
    if payload.notes: record.notes=f'{record.notes or ""} [Catatan Guru: {payload.notes}]'
    db.commit(); db.refresh(record)
    log_activity(db,current_user.id,current_user.full_name,current_user.role.value,f'ATTENDANCE_{action}','ATTENDANCE','AttendanceRecord',str(id),f'Presensi {action.lower()} oleh guru.')
    return ApiResponse(success=True,data=format_attendance(record,db),message=f'Presensi berhasil di-{action}.')

@router.delete('/{id}', response_model=ApiResponse[dict])
def delete(id:int,db:Session=Depends(get_db),current_user:User=Depends(get_current_user)):
    if current_user.role not in (UserRole.GURU,UserRole.ADMIN): raise HTTPException(403,'Hanya Guru/Admin yang dapat menghapus riwayat presensi.')
    record=db.query(AttendanceRecord).filter_by(id=id).first()
    if not record: raise HTTPException(404,'Data presensi tidak ditemukan.')
    if not allowed_student(db,current_user,record.student_id): raise HTTPException(403,'Siswa bukan bimbingan Anda.')
    db.delete(record); db.commit(); log_activity(db,current_user.id,current_user.full_name,current_user.role.value,'DELETE_ATTENDANCE','ATTENDANCE','AttendanceRecord',str(id),'Riwayat presensi dihapus oleh Guru/Admin.')
    return ApiResponse(success=True,data={'deleted_id':id},message='Riwayat presensi berhasil dihapus.')
