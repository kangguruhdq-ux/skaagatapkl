from fastapi import APIRouter, Depends, HTTPException, Query
from fastapi.responses import HTMLResponse
from sqlalchemy.orm import Session
from typing import Optional

from jose import jwt, JWTError
from app.core.config import settings
from app.db.session import get_db
from app.models.user import User, UserRole
from app.models.journal import DailyJournal
from app.models.placement import CompanyPlacement, PlacementAssignment
from app.models.submission import PklSubmission
from app.api.deps import get_current_user

from app.api.deps import oauth2_scheme_optional

router = APIRouter()

def get_user_for_report(
    token_query: Optional[str] = Query(None, alias="token"),
    header_token: Optional[str] = Depends(oauth2_scheme_optional),
    db: Session = Depends(get_db),
) -> User:
    token = header_token or token_query
    if not token:
        raise HTTPException(
            status_code=401,
            detail="Token otentikasi tidak valid atau telah kedaluwarsa.",
            headers={"WWW-Authenticate": "Bearer"},
        )
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        user_id_str: str = payload.get("sub")
        token_type: str = payload.get("type")
        if user_id_str is None or token_type != "access":
            raise HTTPException(401, "Token tidak valid.")
        user_id = int(user_id_str)
    except (JWTError, ValueError):
        raise HTTPException(401, "Token tidak valid.")

    user = db.query(User).filter(User.id == user_id).first()
    if not user or not user.is_active:
        raise HTTPException(401, "Pengguna tidak ditemukan atau tidak aktif.")
    return user

@router.get("/logbook/html", response_class=HTMLResponse)
def get_logbook_html(
    student_id: Optional[int] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_user_for_report)
):
    if current_user.role == UserRole.SISWA:
        if student_id is not None and student_id != current_user.id: raise HTTPException(403, 'Anda hanya dapat mengunduh logbook sendiri.')
        target_student_id = current_user.id
    elif student_id is not None:
        target_student_id = student_id
        if current_user.role == UserRole.GURU and not db.query(PklSubmission.id).filter(PklSubmission.student_id == student_id, PklSubmission.teacher_id == current_user.id).first(): raise HTTPException(403, 'Siswa bukan bimbingan Anda.')
    else:
        raise HTTPException(400, 'student_id wajib diisi untuk Guru/Admin.')

    student = db.query(User).filter(User.id == target_student_id).first()
    if not student:
        raise HTTPException(status_code=404, detail="Data siswa tidak ditemukan.")

    # Fetch company placement
    company_name = company_addr = mentor_name = mentor_phone = "-"

    assignment = db.query(PlacementAssignment).filter(PlacementAssignment.student_id == student.id).first()
    if assignment and assignment.company:
        company_name = assignment.company.name
        company_addr = assignment.company.address
        mentor_name = assignment.company.mentor_name or mentor_name
        mentor_phone = assignment.company.mentor_phone or mentor_phone

    # Fetch teacher
    teacher_sub = db.query(PklSubmission.teacher_id).filter(PklSubmission.student_id == student.id, PklSubmission.teacher_id.isnot(None)).order_by(PklSubmission.updated_at.desc()).first()
    teacher_id = teacher_sub[0] if teacher_sub else None
    teacher = db.query(User).filter(User.id == teacher_id).first() if teacher_id else None
    teacher_name = teacher.full_name if teacher else "-"
    teacher_nip = teacher.username if teacher else "-"

    # Fetch journals
    journals = db.query(DailyJournal).filter(DailyJournal.student_id == student.id).order_by(DailyJournal.date.asc()).all()

    # Build HTML rows
    rows_html = ""
    for idx, j in enumerate(journals, 1):
        status_badge = "Disetujui" if j.status in ["APPROVED", "VERIFIED"] else ("Perlu Revisi" if j.status in ["REVISION_REQUIRED", "REVISION"] else "Menunggu")
        status_color = "#15803d" if j.status in ["APPROVED", "VERIFIED"] else ("#b45309" if j.status in ["REVISION_REQUIRED", "REVISION"] else "#0369a1")
        note = getattr(j, 'revision_notes', None) or "-"
        rows_html += f"""
        <tr>
            <td style="text-align: center;">{idx}</td>
            <td style="white-space: nowrap;">{j.date.strftime('%d/%m/%Y') if hasattr(j.date, 'strftime') else str(j.date)}</td>
            <td>{j.work_summary}</td>
            <td style="text-align: center;">{j.hours_spent} Jam</td>
            <td style="text-align: center; color: {status_color}; font-weight: bold;">{status_badge}</td>
            <td style="font-size: 11px; color: #475569;">{note}</td>
        </tr>
        """

    if not rows_html:
        rows_html = """
        <tr>
            <td colspan="6" style="text-align: center; padding: 20px; color: #64748b;">Belum ada entri log kegiatan harian yang tercatat.</td>
        </tr>
        """

    html_content = f"""<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Buku Jurnal PKL Resmi — {student.full_name} ({student.username})</title>
    <style>
        @page {{
            size: A4;
            margin: 15mm 15mm 20mm 15mm;
        }}
        body {{
            font-family: 'Times New Roman', Times, serif;
            font-size: 12pt;
            line-height: 1.4;
            color: #000;
            background: #f1f5f9;
            margin: 0;
            padding: 20px;
        }}
        .no-print-bar {{
            background: #0f766e;
            color: #fff;
            padding: 12px 24px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            border-radius: 8px;
            max-width: 800px;
            margin: 0 auto 20px auto;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
        }}
        .btn-print {{
            background: #f59e0b;
            color: #000;
            font-weight: bold;
            padding: 8px 18px;
            border: none;
            border-radius: 6px;
            cursor: pointer;
            font-size: 14px;
        }}
        .btn-print:hover {{
            background: #d97706;
            color: #fff;
        }}
        .document-page {{
            background: #fff;
            max-width: 800px;
            margin: 0 auto;
            padding: 40px;
            box-shadow: 0 4px 12px rgba(0,0,0,0.08);
            border-radius: 4px;
        }}
        .kop-header {{
            text-align: center;
            border-bottom: 3px double #000;
            padding-bottom: 12px;
            margin-bottom: 20px;
        }}
        .kop-header h3 {{
            margin: 0;
            font-size: 13pt;
            font-weight: normal;
        }}
        .kop-header h2 {{
            margin: 2px 0;
            font-size: 15pt;
            font-weight: bold;
            letter-spacing: 0.5px;
        }}
        .kop-header p {{
            margin: 2px 0;
            font-size: 10pt;
        }}
        .doc-title {{
            text-align: center;
            font-weight: bold;
            font-size: 14pt;
            margin: 16px 0;
            text-decoration: underline;
        }}
        .meta-table {{
            width: 100%;
            margin-bottom: 20px;
            font-size: 11pt;
            border-collapse: collapse;
        }}
        .meta-table td {{
            padding: 4px 6px;
            vertical-align: top;
        }}
        .meta-table td.label {{
            width: 28%;
            font-weight: bold;
        }}
        .journal-table {{
            width: 100%;
            border-collapse: collapse;
            font-size: 10pt;
            margin-top: 15px;
        }}
        .journal-table th, .journal-table td {{
            border: 1px solid #000;
            padding: 6px 8px;
        }}
        .journal-table th {{
            background-color: #f8fafc;
            text-align: center;
            font-weight: bold;
        }}
        .signatures {{
            margin-top: 40px;
            width: 100%;
            page-break-inside: avoid;
        }}
        .signatures td {{
            text-align: center;
            vertical-align: top;
            width: 33%;
            padding: 10px;
        }}
        .sig-space {{
            height: 70px;
        }}
        @media print {{
            body {{
                background: #fff;
                padding: 0;
            }}
            .no-print-bar {{
                display: none;
            }}
            .document-page {{
                box-shadow: none;
                padding: 0;
                margin: 0;
                max-width: 100%;
            }}
        }}
    </style>
</head>
<body>

<div class="no-print-bar">
    <div>
        <strong>Format Cetak Logbook PKL SMKN 3 Yogyakarta</strong>
        <div style="font-size: 12px; opacity: 0.9;">Gunakan menu Cetak di browser atau tombol di kanan untuk Simpan PDF.</div>
    </div>
    <button class="btn-print" onclick="window.print()">🖨️ Cetak / Unduh PDF</button>
</div>

<div class="document-page">
    <div class="kop-header">
        <h3>PEMERINTAH DAERAH DAERAH ISTIMEWA YOGYAKARTA</h3>
        <h3>DINAS PENDIDIKAN, PEMUDA DAN OLAHRAGA</h3>
        <h2>SMK NEGERI 3 YOGYAKARTA</h2>
        <p>Jl. RW. Monginsidi No.2, Cokrodiningratan, Kec. Jetis, Kota Yogyakarta, DIY 55233</p>
        <p>Telepon: (0274) 513503 • Pos-el: smkn3jogja@skagata.sch.id • Laman: smkn3jogja.sch.id</p>
    </div>

    <div class="doc-title">BUKU JURNAL & REKAPITULASI KEGIATAN PRAKTIK KERJA LAPANGAN (PKL)</div>

    <table class="meta-table">
        <tr>
            <td class="label">Nama Siswa</td>
            <td>: {student.full_name}</td>
            <td class="label">Kelas / Jurusan</td>
            <td>: {student.student_class or 'XII TKJ 1'} • {student.department or 'Teknik Jaringan Komputer'}</td>
        </tr>
        <tr>
            <td class="label">NISN / Identitas</td>
            <td>: {student.username}</td>
            <td class="label">Guru Pembimbing</td>
            <td>: {teacher_name} (NIP: {teacher_nip})</td>
        </tr>
        <tr>
            <td class="label">Tempat / Industri</td>
            <td>: {company_name}</td>
            <td class="label">Pembimbing Industri</td>
            <td>: {mentor_name} ({mentor_phone})</td>
        </tr>
        <tr>
            <td class="label">Alamat Industri</td>
            <td colspan="3">: {company_addr}</td>
        </tr>
    </table>

    <table class="journal-table">
        <thead>
            <tr>
                <th style="width: 5%;">No</th>
                <th style="width: 12%;">Tanggal</th>
                <th style="width: 48%;">Uraian Tugas & Kegiatan Praktik</th>
                <th style="width: 10%;">Durasi</th>
                <th style="width: 12%;">Status</th>
                <th style="width: 13%;">Catatan Pembimbing</th>
            </tr>
        </thead>
        <tbody>
            {rows_html}
        </tbody>
    </table>

    <table class="signatures">
        <tr>
            <td>
                Mengetahui,<br>
                Pembimbing Industri / DUDI<br>
                <div class="sig-space"></div>
                <strong><u>{mentor_name}</u></strong><br>
                {company_name}
            </td>
            <td>
                Yogyakarta, {student.created_at.strftime('%d %B %Y') if hasattr(student.created_at, 'strftime') else '2024'}<br>
                Siswa Praktikan<br>
                <div class="sig-space"></div>
                <strong><u>{student.full_name}</u></strong><br>
                NISN: {student.username}
            </td>
            <td>
                Menyetujui,<br>
                Guru Pembimbing Sekolah<br>
                <div class="sig-space"></div>
                <strong><u>{teacher_name}</u></strong><br>
                NIP: {teacher_nip}
            </td>
        </tr>
        <tr>
            <td colspan="3" style="padding-top: 30px;">
                Mengesahkan,<br>
                Kepala Program Keahlian / Hubungan Industri (Hubin)<br>
                SMK Negeri 3 Yogyakarta<br>
                <div class="sig-space"></div>
                <strong><u>Drs. H. M. Zainal Arifin, M.Eng.</u></strong><br>
                NIP: 197103151998021002
            </td>
        </tr>
    </table>
</div>

</body>
</html>"""
    return HTMLResponse(content=html_content)
