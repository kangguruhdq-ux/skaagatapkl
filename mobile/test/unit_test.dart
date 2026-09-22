import 'package:flutter_test/flutter_test.dart';
import 'package:skagata_pkl_mobile/features/auth/models/user_model.dart';
import 'package:skagata_pkl_mobile/features/dashboard/models/dashboard_model.dart';
import 'package:skagata_pkl_mobile/features/attendance/models/attendance_model.dart';
import 'package:skagata_pkl_mobile/features/journal/models/journal_model.dart';
import 'package:skagata_pkl_mobile/features/skills/models/skill_model.dart';
import 'package:skagata_pkl_mobile/features/submission/models/submission_model.dart';

void main() {
  group('SKAGATA PKL Model Integrity Tests', () {
    test('UserModel deserialization', () {
      final json = {
        'id': 1,
        'username': '0068492011',
        'full_name': 'Muhammad Fikri Pratama',
        'email': 'fikri.tkj@smkn3jogja.sch.id',
        'role': 'siswa',
        'department': 'Teknik Komputer dan Jaringan',
        'student_class': 'XII TKJ 1',
        'device_id': 'SKGT-DEV-8842',
        'device_model': 'Samsung Galaxy A54 5G',
      };

      final user = UserModel.fromJson(json);
      expect(user.id, 1);
      expect(user.username, '0068492011');
      expect(user.fullName, 'Muhammad Fikri Pratama');
      expect(user.role, 'siswa');
      expect(user.studentClass, 'XII TKJ 1');
      expect(user.deviceId, 'SKGT-DEV-8842');
    });

    test('DashboardModel deserialization', () {
      final json = {
        'student_id': 1,
        'student_name': 'Muhammad Fikri Pratama',
        'nisn': '0068492011',
        'student_class': 'XII TKJ 1',
        'department': 'Teknik Komputer dan Jaringan',
        'placement': {
          'id': 1,
          'company_name': 'PT Telkom Indonesia Tbk',
          'division': 'Witel Yogyakarta • Network Ops & Maintenance',
          'address': 'Kotabaru',
          'mentor_name': 'Ir. Bambang Hermanto, S.T.',
          'supervisor_name': 'Dra. Sri Wahyuningsih, M.Pd.',
          'period_string': '15 Jul – 15 Des 2024',
          'current_week': 14,
          'total_weeks': 22,
          'progress_pct': 64,
          'status': 'Active Placement',
        },
        'urgent_alert': {
          'id': 58,
          'title': 'Perlu Tindakan: Revisi Jurnal',
          'badge_label': 'Urgent',
          'notes': 'Tambahkan screenshot topologi STP',
          'action_label': 'Buka Revisi',
          'target_route': '/journal/58',
          'journal_id': 58,
        },
        'telemetry_strip': {
          'attendance_rate_pct': 98.4,
          'total_present_days': 56,
          'permitted_days': 1,
          'alpha_days': 0,
          'last_gps_distance_meters': 38.0,
          'is_in_geofence': true,
        },
        'active_tasks_count': 3,
        'draft_journals_count': 1,
      };

      final model = DashboardModel.fromJson(json);
      expect(model.studentName, 'Muhammad Fikri Pratama');
      expect(model.placement?.companyName, 'PT Telkom Indonesia Tbk');
      expect(model.placement?.progressPct, 64);
      expect(model.urgentAlert?.badgeLabel, 'Urgent');
      expect(model.telemetryStrip.attendanceRatePct, 98.4);
      expect(model.telemetryStrip.totalPresentDays, 56);
      expect(model.telemetryStrip.lastGpsDistanceMeters, 38.0);
    });

    test('AttendanceRecordModel deserialization', () {
      final json = {
        'id': 101,
        'student_id': 1,
        'placement_id': 1,
        'date': '2024-10-19',
        'latitude': -7.78542,
        'longitude': 110.37219,
        'distance_meters': 43.0,
        'is_in_radius': true,
        'accuracy_meters': 4.2,
        'device_fingerprint': 'SKGT-DEV-8842',
        'status': 'HADIR',
        'shift_name': 'Shift Reguler Pagi',
        'verified_by_mentor': true,
      };

      final att = AttendanceRecordModel.fromJson(json);
      expect(att.distanceMeters, 43.0);
      expect(att.isInRadius, true);
      expect(att.status, 'HADIR');
      expect(att.deviceFingerprint, 'SKGT-DEV-8842');
    });

    test('JournalModel deserialization and skill extraction', () {
      final json = {
        'id': 58,
        'student_id': 1,
        'placement_id': 1,
        'date': 'Sabtu, 19 Oktober 2024',
        'day_number': 58,
        'hours_spent': 8.5,
        'work_summary': 'Melakukan konfigurasi Trunking 802.1Q dan pemisahan broadcast domain pada Switch Cisco Catalyst 3850',
        'standard_competency': 'Admin Jaringan Lv. 2',
        'competency_category': 'SKKNI Kategori J.61',
        'complexity_level': 'INTERMEDIATE',
        'complexity_tier': 'Tier: Teknisi Madya',
        'ai_match_percentage': 98.6,
        'ai_extracted_skills': '[{"name": "VLAN 802.1Q", "score": 98}, {"name": "L2 Switching", "score": 95}]',
        'detected_tools': '["Cisco Catalyst 3850", "PuTTY Console"]',
        'workflow_stage': 4,
        'status': 'REVISION_REQUIRED',
        'revision_notes': 'Tambahkan screenshot topologi STP',
        'is_urgent_revision': true,
        'reviewer_name': 'Ir. Bambang Hermanto, S.T.',
      };

      final journal = JournalModel.fromJson(json);
      expect(journal.dayNumber, 58);
      expect(journal.hoursSpent, 8.5);
      expect(journal.aiMatchPercentage, 98.6);
      expect(journal.isUrgentRevision, true);
      expect(journal.extractedSkills.length, 2);
      expect(journal.extractedSkills[0].name, 'VLAN 802.1Q');
      expect(journal.detectedTools.contains('Cisco Catalyst 3850'), true);
    });

    test('SkillCompetencyModel gap analysis deserialization', () {
      final json = {
        'id': 1,
        'name': 'Python Scripting',
        'category': 'Automation',
        'industry_demand_pct': 91.0,
        'student_mastery_pct': 45.0,
        'gap_percentage': -46.0,
        'status': 'GAP',
        'recommendation': 'Perlu Pelatihan Tambahan untuk Automation',
        'audit_tier': 'AI_DETECTED',
        'validated_units': 1,
        'evidence_logs_count': 3,
      };

      final skill = SkillCompetencyModel.fromJson(json);
      expect(skill.name, 'Python Scripting');
      expect(skill.gapPercentage, -46.0);
      expect(skill.status, 'GAP');
      expect(skill.auditTier, 'AI_DETECTED');
    });

    test('PklSubmissionModel and PklEvidenceModel deserialization', () {
      final subJson = {
        'id': 1,
        'student_id': 1,
        'company_id': 1,
        'company_name': 'PT Telkom Indonesia Tbk',
        'address': 'Yogyakarta',
        'status': 'CHANGE_REQUESTED',
        'proposal_letter_url': 'https://storage/proposal.pdf',
        'change_reason': 'Penyesuaian kompetensi core fiber optic',
        'supervisor_notes': 'Harap lampirkan surat rekomendasi',
        'submitted_at': '2024-07-01T08:00:00',
        'reviewed_at': '2024-07-02T10:30:00',
        'student_name': 'Muhammad Fikri Pratama',
        'student_nisn': '0068492011',
      };

      final sub = PklSubmissionModel.fromJson(subJson);
      expect(sub.id, 1);
      expect(sub.status, 'CHANGE_REQUESTED');
      expect(sub.companyName, 'PT Telkom Indonesia Tbk');
      expect(sub.changeReason, 'Penyesuaian kompetensi core fiber optic');
      expect(sub.studentNisn, '0068492011');

      final evJson = {
        'id': 10,
        'student_id': 1,
        'title': 'Sertifikat Kompetensi Jaringan Fiber Optic',
        'category': 'certificate',
        'description': 'Uji kompetensi fiber splicing',
        'file_url': 'https://storage/cert.pdf',
        'status': 'VERIFIED',
        'review_notes': 'Terverifikasi sah',
        'submitted_at': '2024-08-01T09:00:00',
      };

      final ev = PklEvidenceModel.fromJson(evJson);
      expect(ev.id, 10);
      expect(ev.category, 'certificate');
      expect(ev.status, 'VERIFIED');
      expect(ev.reviewNotes, 'Terverifikasi sah');
    });
  });
}
