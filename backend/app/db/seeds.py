import json
from datetime import datetime, date, timedelta
from sqlalchemy.orm import Session

from app.db.session import SessionLocal, Base, engine
from app.core.security import get_password_hash
from app.models.user import User, UserRole
from app.models.placement import CompanyPlacement, PlacementAssignment
from app.models.attendance import AttendanceRecord
from app.models.journal import DailyJournal, EvidenceAttachment
from app.models.skill import SkillCompetency
from app.models.notification import NotificationItem
from app.models.submission import PklSubmission, PklEvidence
from app.models.audit_log import AuditLog
from app.models.access import CompanyMember

def init_db():
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()

    try:
        # Check if already seeded base data
        has_users = db.query(User).first() is not None
        if has_users:
            # Ensure teacher username is normalized to 198402172009032004 without spaces
            teacher = db.query(User).filter(User.role == UserRole.GURU).first()
            if teacher and teacher.username != "198402172009032004":
                teacher.username = "198402172009032004"
                db.commit()

            print("Database already initialized. Skipping re-seed.")
            return

        print("Seeding initial data for SKAGATA PKL Intelligence...")

        # 1. Company Placement (Telkom Witel Yogyakarta)
        telkom = CompanyPlacement(
            name="PT Telkom Indonesia Tbk",
            division="Witel Yogyakarta • Network Ops & Maintenance",
            address="Jl. Yos Sudarso No.9 Kotabaru Gondokusuman Yogyakarta",
            latitude=-7.78542,
            longitude=110.37219,
            geofence_radius=100.0,
            mentor_name="Ir. Bambang Hermanto, S.T.",
            mentor_phone="+62 812-3456-7890",
            supervisor_name="Dra. Sri Wahyuningsih, M.Pd.",
            supervisor_phone="+62 813-9876-5432",
            period_start="15 Jul 2024",
            period_end="15 Des 2024",
            total_weeks=22,
            current_week=14,
            code="PKL-TKJ-2024",
            is_active=True
        )
        db.add(telkom)
        db.commit()
        db.refresh(telkom)

        # 2. Users (Student, Teacher, Mentor, Admin)
        student_fikri = User(
            username="0068492011",
            full_name="Muhammad Fikri Pratama",
            email="fikri.tkj@smkn3jogja.sch.id",
            hashed_password=get_password_hash("Skagata123#"),
            role=UserRole.SISWA,
            department="Teknik Komputer dan Jaringan",
            student_class="XII TKJ 1",
            phone="+62 821-1234-5678",
            avatar_url="https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&auto=format&fit=crop",
            device_id="SKGT-DEV-8842",
            device_model="Samsung Galaxy A54 5G",
            is_active=True
        )

        teacher_wahyu = User(
            username="19840217 200801 1 004",
            full_name="Dra. Sri Wahyuningsih, M.Pd.",
            email="wahyuningsih@smkn3jogja.sch.id",
            hashed_password=get_password_hash("GuruAktif2025!"),
            role=UserRole.GURU,
            department="Teknik Komputer dan Jaringan",
            phone="+62 813-9876-5432",
            is_active=True
        )

        mentor_bambang = User(
            username="MITRA-TELKOM-092",
            full_name="Ir. Bambang Hermanto, S.T.",
            email="bambang.hermanto@telkom.co.id",
            hashed_password=get_password_hash("IndustriMitra#1"),
            role=UserRole.MITRA,
            department="Network Operations",
            phone="+62 812-3456-7890",
            is_active=True
        )

        admin_hubin = User(
            username="admin_hubin",
            full_name="Admin Hubin SMKN 3 Yogyakarta",
            email="hubin@smkn3jogja.sch.id",
            hashed_password=get_password_hash("AdminHubin2024!"),
            role=UserRole.ADMIN,
            department="Hubungan Industri & Kerjasama",
            phone="+62 811-2233-4455",
            is_active=True
        )

        db.add_all([student_fikri, teacher_wahyu, mentor_bambang, admin_hubin])
        db.commit()
        db.refresh(student_fikri)

        # 3. Placement Assignment
        assignment = PlacementAssignment(
            student_id=student_fikri.id,
            placement_id=telkom.id,
            status="ACTIVE"
        )
        db.add(assignment)
        db.commit()

        # 4. Past Attendance Records (56 Hadir, 1 Izin)
        today = date.today()
        # Seed 56 past records
        for i in range(1, 57):
            past_date = today - timedelta(days=i)
            is_izin = (i == 12)
            att = AttendanceRecord(
                student_id=student_fikri.id,
                placement_id=telkom.id,
                date=past_date.isoformat(),
                check_in_time=datetime.combine(past_date, datetime.min.time()).replace(hour=7, minute=45),
                check_out_time=datetime.combine(past_date, datetime.min.time()).replace(hour=16, minute=30),
                latitude=-7.78542 + (0.00005 * (i % 3)),
                longitude=110.37219 + (0.00005 * (i % 2)),
                distance_meters=35.0 + (i % 15),
                is_in_radius=True,
                accuracy_meters=4.2,
                mock_location_detected=False,
                device_fingerprint="SKGT-DEV-8842",
                status="IZIN" if is_izin else "HADIR",
                notes="Surat izin dokter terverifikasi" if is_izin else "Presensi reguler hadir tepat waktu",
                shift_name="Shift Reguler Pagi (08:00 - 16:30 WIB)",
                verified_by_mentor=True
            )
            db.add(att)

        # Today's Check-in Record
        today_att = AttendanceRecord(
            student_id=student_fikri.id,
            placement_id=telkom.id,
            date=today.isoformat(),
            check_in_time=datetime.utcnow().replace(hour=7, minute=42, second=0),
            check_out_time=None,
            latitude=-7.78542,
            longitude=110.37219,
            distance_meters=38.0,
            is_in_radius=True,
            accuracy_meters=4.2,
            mock_location_detected=False,
            device_fingerprint="SKGT-DEV-8842",
            status="HADIR",
            notes="Hadir 07:42 WIB • Presensi Geofence Telkom Witel",
            shift_name="Shift Reguler Pagi (08:00 - 16:30 WIB)",
            verified_by_mentor=True
        )
        db.add(today_att)
        db.commit()

        # 5. Daily Journals (including Urgent Revision Journal Day 58)
        extracted_skills_sample = [
            {"name": "VLAN 802.1Q", "score": 98},
            {"name": "L2 Switching", "score": 95},
            {"name": "STP Protocol", "score": 92},
            {"name": "Troubleshooting", "score": 96}
        ]
        detected_tools_sample = [
            "Cisco Catalyst 3850",
            "PuTTY Console",
            "Fluke Cable Tester"
        ]

        journal_58 = DailyJournal(
            student_id=student_fikri.id,
            placement_id=telkom.id,
            date=today.isoformat(),
            day_number=58,
            hours_spent=8.5,
            work_summary="Melakukan konfigurasi Trunking 802.1Q dan pemisahan broadcast domain pada Switch Cisco Catalyst 3850, dilanjutkan dengan troubleshooting routing loop spanning-tree (STP) di ruang NOC Telkom Kotabaru.",
            standard_competency="Admin Jaringan Lv. 2",
            competency_category="SKKNI Kategori J.61",
            complexity_level="INTERMEDIATE",
            complexity_tier="Tier: Teknisi Madya",
            ai_match_percentage=98.6,
            ai_extracted_skills=json.dumps(extracted_skills_sample),
            detected_tools=json.dumps(detected_tools_sample),
            workflow_stage=4, # Review stage
            status="REVISION_REQUIRED",
            revision_notes='Catatan Ir. Bambang H: "Tambahkan screenshot topologi STP dan hasil per-port spanning-tree sebelum diverifikasi final."',
            is_urgent_revision=True,
            reviewer_name="Ir. Bambang Hermanto, S.T."
        )

        journal_57 = DailyJournal(
            student_id=student_fikri.id,
            placement_id=telkom.id,
            date=(today - timedelta(days=1)).isoformat(),
            day_number=57,
            hours_spent=8.0,
            work_summary="Maintenance rak server ODC dan penarikan patch cord fiber optic single mode LC-to-SC di area distribution frame.",
            standard_competency="Instalasi Fiber Optik",
            competency_category="SKKNI Kategori J.61",
            complexity_level="INTERMEDIATE",
            complexity_tier="Tier: Teknisi Madya",
            ai_match_percentage=96.4,
            ai_extracted_skills=json.dumps([{"name": "Fiber Optic Splicing", "score": 94}, {"name": "OTDR Testing", "score": 91}]),
            detected_tools=json.dumps(["Fujikura Fusion Splicer", "Anritsu OTDR"]),
            workflow_stage=5,
            status="APPROVED",
            is_urgent_revision=False,
            reviewer_name="Ir. Bambang Hermanto, S.T.",
            reviewed_at=datetime.utcnow() - timedelta(days=1)
        )

        db.add_all([journal_58, journal_57])
        db.commit()

        # 6. Skill Competencies & Industry Gap (Exact Stitch Values)
        skills_data = [
            SkillCompetency(
                student_id=student_fikri.id,
                name="Python Scripting",
                category="Automation",
                industry_demand_pct=91.0,
                student_mastery_pct=45.0,
                gap_percentage=-46.0,
                status="GAP",
                recommendation="Perlu Pelatihan Tambahan untuk Automation",
                audit_tier="AI_DETECTED",
                skkni_code="J.611000.005.01",
                validated_units=1,
                evidence_logs_count=3
            ),
            SkillCompetency(
                student_id=student_fikri.id,
                name="Computer Networking",
                category="Infrastructure",
                industry_demand_pct=73.0,
                student_mastery_pct=91.0,
                gap_percentage=18.0,
                status="SURPLUS",
                recommendation="Melebihi Ekspektasi DUDI - Kualifikasi Siap Kerja",
                audit_tier="SUPERVISOR",
                skkni_code="J.611000.001.01",
                validated_units=8,
                evidence_logs_count=24
            ),
            SkillCompetency(
                student_id=student_fikri.id,
                name="Docker & Container",
                category="DevOps",
                industry_demand_pct=64.0,
                student_mastery_pct=31.0,
                gap_percentage=-33.0,
                status="GAP",
                recommendation="Perlu Pengenalan Dasar Container dan Microservices",
                audit_tier="AI_DETECTED",
                skkni_code="J.611000.012.01",
                validated_units=0,
                evidence_logs_count=1
            ),
            SkillCompetency(
                student_id=student_fikri.id,
                name="MikroTik Routing",
                category="Infrastructure",
                industry_demand_pct=85.0,
                student_mastery_pct=88.0,
                gap_percentage=3.0,
                status="SURPLUS",
                recommendation="Kompetensi Tingkat Lanjut MTCNA Siap Uji",
                audit_tier="SMKN 3",
                skkni_code="J.611000.003.01",
                validated_units=6,
                evidence_logs_count=18
            ),
            SkillCompetency(
                student_id=student_fikri.id,
                name="Fiber Optic Splicing",
                category="Hardware",
                industry_demand_pct=80.0,
                student_mastery_pct=85.0,
                gap_percentage=5.0,
                status="SURPLUS",
                recommendation="Standar Kualifikasi DUDI Telkom Terpenuhi",
                audit_tier="SUPERVISOR",
                skkni_code="J.611000.008.01",
                validated_units=5,
                evidence_logs_count=12
            ),
        ]
        db.add_all(skills_data)
        db.commit()

        # 7. Notifications
        notifications_data = [
            NotificationItem(
                user_id=student_fikri.id,
                title="Perlu Revisi Jurnal Hari ke-58",
                message='Ir. Bambang Hermanto: "Tambahkan screenshot topologi STP dan hasil per-port spanning-tree sebelum diverifikasi final."',
                type="revision",
                action_route=f"/journal/{journal_58.id}",
                is_read=False
            ),
            NotificationItem(
                user_id=student_fikri.id,
                title="Presensi Masuk Tervalidasi",
                message="Check-in GPS Witel Yogyakarta tervalidasi 38m dari perimeter jam 07:42 WIB.",
                type="attendance",
                action_route="/attendance",
                is_read=False
            ),
            NotificationItem(
                user_id=student_fikri.id,
                title="Sinkronisasi Telemetri PKL",
                message="Pangkalan data Dapodik SMKN 3 Yogyakarta menerima logbook terverifikasi.",
                type="info",
                action_route="/dashboard",
                is_read=True
            ),
        ]
        # 8. Ensure active PklSubmission exists for student
        students = db.query(User).filter(User.role == UserRole.SISWA).all()
        for s in students:
            existing_sub = db.query(PklSubmission).filter(PklSubmission.student_id == s.id).first()
            if not existing_sub:
                new_sub = PklSubmission(
                    student_id=s.id,
                    company_name="PT Telkom Indonesia (Witel Yogyakarta)",
                    company_address="Jl. Yos Sudarso No.9 Kotabaru Gondokusuman Yogyakarta",
                    company_phone="+62 812-3456-7890",
                    company_email="witel.jogja@telkom.co.id",
                    industry_sector="Telekomunikasi & Jaringan",
                    division="Network Operations & Maintenance",
                    start_date="2024-07-15",
                    end_date="2024-12-15",
                    latitude=-7.78542,
                    longitude=110.37219,
                    mentor_name="Ir. Bambang Hermanto, S.T.",
                    mentor_contact="+62 812-3456-7890",
                    status="APPROVED",
                )
                db.add(new_sub)
        db.commit()

        print("Database successfully seeded with realistic PKL data!")
    finally:
        db.close()

if __name__ == "__main__":
    init_db()
