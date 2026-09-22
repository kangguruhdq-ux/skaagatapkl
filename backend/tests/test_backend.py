import unittest
import json
import os
import sys

# Add backend directory to sys.path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from fastapi.testclient import TestClient
from app.main import app
from app.core.security import verify_password, get_password_hash, create_access_token
from app.services.geofence import calculate_haversine_distance, verify_geofence
from app.services.ai_extractor import analyze_journal_entry
from app.db.session import SessionLocal
from app.models.user import User, UserRole
from app.models.journal import DailyJournal
from app.models.skill import SkillCompetency

client = TestClient(app)

class BackendUnitAndIntegrationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        # Trigger startup event to seed database
        with client:
            pass

    def test_01_healthcheck(self):
        response = client.get("/health")
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertTrue(data["success"])
        self.assertEqual(data["data"]["status"], "healthy")

    def test_02_password_hashing(self):
        raw = "SkagataSecretPass123"
        hashed = get_password_hash(raw)
        self.assertTrue(verify_password(raw, hashed))
        self.assertFalse(verify_password("WrongPassword", hashed))

    def test_03_geofence_calculation(self):
        # Telkom Witel coords
        telkom_lat = -7.78542
        telkom_lon = 110.37219

        # Exact point
        is_in, dist = verify_geofence(telkom_lat, telkom_lon, telkom_lat, telkom_lon, 100.0)
        self.assertTrue(is_in)
        self.assertEqual(dist, 0.0)

        # ~43 meters away point (from Stitch design spec)
        user_lat = -7.78505
        user_lon = 110.37225
        is_in, dist = verify_geofence(user_lat, user_lon, telkom_lat, telkom_lon, 100.0)
        self.assertTrue(is_in)
        self.assertLess(dist, 100.0)

        # Far away point (e.g. 5 km away in Malioboro / Tugu)
        far_lat = -7.75000
        far_lon = 110.37000
        is_in, dist = verify_geofence(far_lat, far_lon, telkom_lat, telkom_lon, 100.0)
        self.assertFalse(is_in)
        self.assertGreater(dist, 1000.0)

    def test_04_ai_semantic_extractor(self):
        text = "Melakukan konfigurasi Trunking 802.1Q dan pemisahan broadcast domain pada Switch Cisco Catalyst 3850, dilanjutkan dengan troubleshooting routing loop spanning-tree (STP) di ruang NOC Telkom Kotabaru."
        analysis = analyze_journal_entry(text)
        
        self.assertGreaterEqual(analysis["match_percentage"], 90.0)
        self.assertEqual(analysis["standard_competency"], "Admin Jaringan Lv. 2")
        
        # Check that extracted skills contain VLAN or STP
        skill_names = [s["name"] for s in analysis["extracted_skills"]]
        self.assertTrue(any("VLAN" in s or "Switching" in s or "STP" in s for s in skill_names))

        # Check that detected tools contain Cisco Catalyst
        self.assertTrue(any("Cisco" in t for t in analysis["detected_tools"]))

    def test_05_auth_login_student(self):
        payload = {
            "username": "0068492011",
            "password": "Skagata123#",
            "role": "siswa"
        }
        response = client.post("/api/v1/auth/login", json=payload)
        self.assertEqual(response.status_code, 200)
        res_json = response.json()
        self.assertTrue(res_json["success"])
        data = res_json["data"]
        self.assertIn("access_token", data)
        self.assertIn("refresh_token", data)
        self.assertEqual(data["user"]["full_name"], "Muhammad Fikri Pratama")
        self.assertEqual(data["user"]["role"], "siswa")

    def test_06_auth_login_wrong_credentials(self):
        payload = {
            "username": "0068492011",
            "password": "WrongPassword!",
        }
        response = client.post("/api/v1/auth/login", json=payload)
        self.assertEqual(response.status_code, 401)

    def test_07_dapodik_verification(self):
        response = client.get("/api/v1/auth/verify-dapodik?nisn=0068492011")
        self.assertEqual(response.status_code, 200)
        data = response.json()["data"]
        self.assertEqual(data["full_name"], "Muhammad Fikri Pratama")
        self.assertEqual(data["department"], "Teknik Komputer dan Jaringan")

    def test_08_dashboard_summary_endpoint(self):
        # Login first to get token
        login_res = client.post("/api/v1/auth/login", json={
            "username": "0068492011",
            "password": "Skagata123#"
        })
        token = login_res.json()["data"]["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        res = client.get("/api/v1/dashboard/summary", headers=headers)
        self.assertEqual(res.status_code, 200)
        data = res.json()["data"]
        self.assertEqual(data["student_name"], "Muhammad Fikri Pratama")
        self.assertIn(data["placement"]["company_name"], ["PT Telkom Indonesia Tbk", "PT Astra Digital International"])
        self.assertIsNotNone(data["urgent_alert"])
        self.assertGreaterEqual(data["telemetry_strip"]["attendance_rate_pct"], 0.0)

    def test_09_attendance_checkin_and_status(self):
        login_res = client.post("/api/v1/auth/login", json={
            "username": "0068492011",
            "password": "Skagata123#"
        })
        token = login_res.json()["data"]["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        # Check status
        status_res = client.get("/api/v1/attendance/status", headers=headers)
        self.assertEqual(status_res.status_code, 200)
        status_data = status_res.json()["data"]
        self.assertEqual(status_data["target_latitude"], -7.78542)

        # Perform check-in within radius with mandatory selfie
        from app.core.config import settings
        os.makedirs(settings.UPLOAD_DIR, exist_ok=True)
        test_selfie = os.path.join(settings.UPLOAD_DIR, "test_selfie.jpg")
        if not os.path.exists(test_selfie):
            with open(test_selfie, "wb") as f:
                f.write(b"\xff\xd8\xff\xe0\x00\x10JFIF\x00\x01\x01\x01\x00`\x00`\x00\x00\xff\xdb\x00C\x00\x08\x06\x06\x07\x06\x05\x08\x07\x07\x07\t\t\x08\n\x0c\x14\r\x0c\x0b\x0b\x0c\x19\x12\x13\x0f\x14\x1d\x1a\x1f\x1e\x1d\x1a\x1c\x1c $.' \",#\x1c\x1c(7),01444\x1f'9=82<.342\xff\xc0\x00\x0b\x08\x00\x01\x00\x01\x01\x01\x11\x00\xff\xc4\x00\x1f\x00\x00\x01\x05\x01\x01\x01\x01\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x01\x02\x03\x04\x05\x06\x07\x08\t\n\x0b\xff\xda\x00\x08\x01\x01\x00\x00?\x00\xbf\x00\xff\xd9")

        checkin_payload = {
            "latitude": -7.78542,
            "longitude": 110.37219,
            "accuracy_meters": 4.2,
            "selfie_url": "/uploads/test_selfie.jpg",
            "notes": "Presensi mandiri biometrik terverifikasi"
        }
        checkin_res = client.post("/api/v1/attendance/check-in", json=checkin_payload, headers=headers)
        self.assertEqual(checkin_res.status_code, 200)
        checkin_data = checkin_res.json()["data"]
        self.assertTrue(checkin_data["is_in_radius"])
        self.assertEqual(checkin_data["status"], "HADIR")

    def test_10_journal_create_and_update(self):
        login_res = client.post("/api/v1/auth/login", json={
            "username": "0068492011",
            "password": "Skagata123#"
        })
        token = login_res.json()["data"]["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        # Create new journal
        create_payload = {
            "work_summary": "Konfigurasi MikroTik OSPF routing dan VLAN di switch access lantai 2.",
            "hours_spent": 8.0,
            "workflow_stage": 1
        }
        res = client.post("/api/v1/journals", json=create_payload, headers=headers)
        self.assertEqual(res.status_code, 200)
        journal = res.json()["data"]
        journal_id = journal["id"]
        self.assertGreaterEqual(journal["ai_match_percentage"], 90.0)

        # Update journal
        update_payload = {
            "work_summary": "Konfigurasi MikroTik OSPF routing dan VLAN di switch access lantai 2 serta pengujian ping konektivitas."
        }
        update_res = client.patch(f"/api/v1/journals/{journal_id}", json=update_payload, headers=headers)
        self.assertEqual(update_res.status_code, 200)
        self.assertIn("pengujian ping", update_res.json()["data"]["work_summary"])

    def test_11_skills_gap_analysis(self):
        login_res = client.post("/api/v1/auth/login", json={
            "username": "0068492011",
            "password": "Skagata123#"
        })
        token = login_res.json()["data"]["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        res = client.get("/api/v1/skills/gap-analysis", headers=headers)
        self.assertEqual(res.status_code, 200)
        data = res.json()["data"]
        self.assertGreater(data["readiness_index_pct"], 0.0)
        skills = {s["name"]: s for s in data["skills"]}
        self.assertIn("Python Scripting", skills)
        self.assertEqual(skills["Python Scripting"]["gap_percentage"], -46.0)
        self.assertEqual(skills["Python Scripting"]["status"], "GAP")
        self.assertIn("Computer Networking", skills)
        self.assertEqual(skills["Computer Networking"]["gap_percentage"], 18.0)
        self.assertEqual(skills["Computer Networking"]["status"], "SURPLUS")

    def test_12_user_crud_and_admin(self):
        login_res = client.post("/api/v1/auth/login", json={
            "username": "admin_hubin",
            "password": "Skagata123#"
        })
        self.assertEqual(login_res.status_code, 200)
        token = login_res.json()["data"]["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        # Check admin stats
        stats_res = client.get("/api/v1/admin/stats", headers=headers)
        self.assertEqual(stats_res.status_code, 200)
        stats = stats_res.json()["data"]
        self.assertGreater(stats["total_students"], 0)
        self.assertGreater(stats["total_journals"], 0)

        # List users
        users_res = client.get("/api/v1/users?role=siswa", headers=headers)
        self.assertEqual(users_res.status_code, 200)
        self.assertGreater(users_res.json()["data"]["total"], 0)

        # Create user with unique username
        import time
        unique_nisn = f"0099{int(time.time()) % 1000000:06d}"
        create_payload = {
            "username": unique_nisn,
            "password": "Password123#",
            "full_name": "Test Siswa Baru",
            "email": f"siswa.{unique_nisn}@smkn3jogja.sch.id",
            "role": "siswa",
            "department": "Teknik Komputer dan Jaringan",
            "student_class": "XII TKJ 2"
        }
        create_res = client.post("/api/v1/users", json=create_payload, headers=headers)
        self.assertEqual(create_res.status_code, 200)
        new_user_id = create_res.json()["data"]["id"]

        # Update profile of self
        profile_res = client.put("/api/v1/users/me/profile", json={"phone": "081234567890"}, headers=headers)
        self.assertEqual(profile_res.status_code, 200)
        self.assertEqual(profile_res.json()["data"]["phone"], "081234567890")

        # Review journal action approve
        journals_list = client.get("/api/v1/admin/journals", headers=headers).json()["data"]
        journal_id = journals_list[0]["id"]
        review_res = client.patch(f"/api/v1/admin/journals/{journal_id}/review?action=approve", headers=headers)
        self.assertEqual(review_res.status_code, 200)
        self.assertEqual(review_res.json()["data"]["status"], "APPROVED")

        # Delete created user
        del_res = client.delete(f"/api/v1/users/{new_user_id}", headers=headers)
        self.assertEqual(del_res.status_code, 200)
        self.assertTrue(del_res.json()["success"])

    def test_13_teacher_auth_and_role_guard(self):
        # 1. Successful teacher login
        teacher_login = client.post("/api/v1/auth/login", json={
            "username": "198402172009032004",
            "password": "password123",
            "role": "guru"
        })
        self.assertEqual(teacher_login.status_code, 200)
        self.assertEqual(teacher_login.json()["data"]["user"]["role"], "guru")

        # 2. Check /auth/me returns teacher data
        token = teacher_login.json()["data"]["access_token"]
        me_res = client.get("/api/v1/auth/me", headers={"Authorization": f"Bearer {token}"})
        self.assertEqual(me_res.status_code, 200)
        self.assertEqual(me_res.json()["data"]["role"], "guru")

        # 3. Role mismatch guard: student tries to login with guru role
        mismatch_login = client.post("/api/v1/auth/login", json={
            "username": "0068492011",
            "password": "password123",
            "role": "guru"
        })
        self.assertEqual(mismatch_login.status_code, 403)

    def test_14_pkl_submission_and_change_request(self):
        # Student login
        std_login = client.post("/api/v1/auth/login", json={
            "username": "0068492011",
            "password": "password123",
            "role": "siswa"
        })
        std_token = std_login.json()["data"]["access_token"]
        std_headers = {"Authorization": f"Bearer {std_token}"}

        # 1. Student creates submission
        create_res = client.post("/api/v1/submissions", json={
            "company_name": "PT Integrasi Sistem Solusindo",
            "company_address": "Jl. Kaliurang KM 9, Sleman",
            "start_date": "01 Okt 2024",
            "end_date": "31 Des 2024",
            "industry_sector": "Software & Networking"
        }, headers=std_headers)
        self.assertEqual(create_res.status_code, 201)
        sub_id = create_res.json()["data"]["id"]
        self.assertEqual(create_res.json()["data"]["status"], "SUBMITTED")

        # 2. Student submits change request
        change_res = client.post(f"/api/v1/submissions/{sub_id}/change-request", json={
            "new_company_name": "PT Astra Digital International",
            "new_address": "Jl. Magelang KM 5, Yogyakarta",
            "change_reason": "Diterima magang di divisi cyber security",
            "new_start_date": "10 Okt 2024"
        }, headers=std_headers)
        self.assertEqual(change_res.status_code, 200)
        self.assertEqual(change_res.json()["data"]["status"], "CHANGE_REQUESTED")

        # 3. Teacher reviews and approves
        teacher_login = client.post("/api/v1/auth/login", json={
            "username": "198402172009032004",
            "password": "password123",
            "role": "guru"
        })
        tch_token = teacher_login.json()["data"]["access_token"]
        tch_headers = {"Authorization": f"Bearer {tch_token}"}

        review_res = client.post(f"/api/v1/submissions/{sub_id}/review", json={
            "action": "APPROVE",
            "notes": "Disetujui untuk penempatan divisi Cyber Security."
        }, headers=tch_headers)
        self.assertEqual(review_res.status_code, 200)
        self.assertEqual(review_res.json()["data"]["status"], "APPROVED")

    def test_15_evidence_upload_and_verification(self):
        # Student login & upload
        std_login = client.post("/api/v1/auth/login", json={
            "username": "0068492011",
            "password": "password123",
            "role": "siswa"
        })
        std_token = std_login.json()["data"]["access_token"]
        std_headers = {"Authorization": f"Bearer {std_token}"}

        upload_res = client.post("/api/v1/evidences", json={
            "title": "Foto Pengujian Kabel UTP Cat6 Gigabit",
            "category": "FOTO_KEGIATAN",
            "file_url": "https://example.com/cable-test.jpg",
            "description": "Pengujian kontinuitas kabel menggunakan Fluke Network Tester"
        }, headers=std_headers)
        self.assertEqual(upload_res.status_code, 201)
        ev_id = upload_res.json()["data"]["id"]

        # Teacher verifies
        teacher_login = client.post("/api/v1/auth/login", json={
            "username": "198402172009032004",
            "password": "password123",
            "role": "guru"
        })
        tch_token = teacher_login.json()["data"]["access_token"]
        tch_headers = {"Authorization": f"Bearer {tch_token}"}

        verify_res = client.patch(f"/api/v1/evidences/{ev_id}/verify", json={
            "action": "VERIFY",
            "notes": "Foto jelas dan alat ukur standar terkalibrasi."
        }, headers=tch_headers)
        self.assertEqual(verify_res.status_code, 200)
        self.assertEqual(verify_res.json()["data"]["status"], "VERIFIED")

    def test_16_audit_logs_and_company_crud(self):
        # Admin login
        adm_login = client.post("/api/v1/auth/login", json={
            "username": "admin_hubin",
            "password": "password123",
            "role": "admin"
        })
        adm_token = adm_login.json()["data"]["access_token"]
        adm_headers = {"Authorization": f"Bearer {adm_token}"}

        # 1. Audit logs query
        logs_res = client.get("/api/v1/audit/logs", headers=adm_headers)
        self.assertEqual(logs_res.status_code, 200)
        self.assertGreater(logs_res.json()["data"]["total"], 0)

        # 2. Company CRUD
        comp_res = client.post("/api/v1/admin/companies", json={
            "name": "PT Solusi Cloud Nusantara",
            "division": "DevOps Operations",
            "address": "Jl. Ringroad Utara, Sleman",
            "latitude": -7.7512,
            "longitude": 110.3891
        }, headers=adm_headers)
        self.assertEqual(comp_res.status_code, 201)
        comp_id = comp_res.json()["data"]["id"]

        # List companies
        list_res = client.get("/api/v1/admin/companies", headers=adm_headers)
        self.assertEqual(list_res.status_code, 200)
        self.assertGreater(list_res.json()["data"]["total"], 0)

        # Clean up delete company
        del_comp = client.delete(f"/api/v1/admin/companies/{comp_id}", headers=adm_headers)
        self.assertEqual(del_comp.status_code, 200)

    def test_17_journal_revision_workflow_and_audit_history(self):
        # 1. Student creates journal
        std_login = client.post("/api/v1/auth/login", json={
            "username": "0068492011",
            "password": "password123",
            "role": "siswa"
        })
        std_token = std_login.json()["data"]["access_token"]
        std_headers = {"Authorization": f"Bearer {std_token}"}

        create_res = client.post("/api/v1/journals", json={
            "work_summary": "Konfigurasi OSPF Area 0 dan route redistribution di core router.",
            "hours_spent": 8.0,
            "workflow_stage": 2
        }, headers=std_headers)
        self.assertEqual(create_res.status_code, 200)
        j_id = create_res.json()["data"]["id"]

        # 2. Teacher attempts revision with EMPTY notes -> MUST RETURN 400
        tch_login = client.post("/api/v1/auth/login", json={
            "username": "198402172009032004",
            "password": "password123",
            "role": "guru"
        })
        tch_token = tch_login.json()["data"]["access_token"]
        tch_headers = {"Authorization": f"Bearer {tch_token}"}

        empty_rev = client.post(f"/api/v1/journals/{j_id}/review", json={
            "status": "REVISION_REQUIRED",
            "notes": ""
        }, headers=tch_headers)
        self.assertEqual(empty_rev.status_code, 400)
        self.assertIn("Catatan / alasan revisi wajib diisi", empty_rev.json()["detail"])

        # 3. Teacher requests revision with valid reason -> 200
        valid_rev = client.post(f"/api/v1/journals/{j_id}/review", json={
            "status": "REVISION_REQUIRED",
            "notes": "Sertakan detail diagram topologi jaringan dan tabel routing."
        }, headers=tch_headers)
        self.assertEqual(valid_rev.status_code, 200)
        self.assertEqual(valid_rev.json()["data"]["status"], "REVISION_REQUIRED")

        # 4. Student resubmits journal -> status becomes RESUBMITTED
        resubmit_res = client.patch(f"/api/v1/journals/{j_id}", json={
            "work_summary": "Konfigurasi OSPF Area 0, route redistribution, dan topologi VLSM terlampir.",
            "status": "RESUBMITTED",
            "workflow_stage": 4
        }, headers=std_headers)
        self.assertEqual(resubmit_res.status_code, 200)
        self.assertEqual(resubmit_res.json()["data"]["status"], "RESUBMITTED")

        # 5. Teacher verifies journal history audit
        hist_res = client.get(f"/api/v1/journals/{j_id}/history", headers=tch_headers)
        self.assertEqual(hist_res.status_code, 200)
        history_items = hist_res.json()["data"]
        self.assertGreater(len(history_items), 0)

        # 6. Teacher approves the revised journal -> 200
        approve_res = client.post(f"/api/v1/journals/{j_id}/review", json={
            "status": "APPROVED",
            "notes": "Topologi lengkap dan routing table valid. Disetujui."
        }, headers=tch_headers)
        self.assertEqual(approve_res.status_code, 200)
        self.assertEqual(approve_res.json()["data"]["status"], "APPROVED")

        # 7. Student deletes the journal
        del_res = client.delete(f"/api/v1/journals/{j_id}", headers=std_headers)
        self.assertEqual(del_res.status_code, 200)
        self.assertTrue(del_res.json()["success"])

    def test_18_audit_deletion_and_report_export(self):
        adm_login = client.post("/api/v1/auth/login", json={
            "username": "admin_hubin",
            "password": "password123",
            "role": "admin"
        })
        adm_token = adm_login.json()["data"]["access_token"]
        adm_headers = {"Authorization": f"Bearer {adm_token}"}

        # Check report HTML (admin requests student's logbook)
        db = SessionLocal()
        std = db.query(User).filter_by(role=UserRole.SISWA).first()
        db.close()
        report_res = client.get(f"/api/v1/reports/logbook/html?token={adm_token}&student_id={std.id}")
        self.assertEqual(report_res.status_code, 200)
        self.assertIn("SMK NEGERI 3 YOGYAKARTA", report_res.text)
        self.assertIn("BUKU JURNAL", report_res.text)

        # Get audit logs
        audit_res = client.get("/api/v1/audit/logs", headers=adm_headers)
        self.assertEqual(audit_res.status_code, 200)
        logs = audit_res.json()["data"]["items"]
        if logs:
            first_log_id = logs[0]["id"]
            # Delete single audit log
            del_single = client.delete(f"/api/v1/audit/logs/{first_log_id}", headers=adm_headers)
            self.assertEqual(del_single.status_code, 200)
            self.assertTrue(del_single.json()["success"])

if __name__ == "__main__":
    unittest.main()



