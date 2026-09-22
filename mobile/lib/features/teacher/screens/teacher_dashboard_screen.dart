import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../auth/providers/auth_provider.dart';
import '../../submission/models/submission_model.dart';
import '../../submission/services/submission_service.dart';
import '../../attendance/models/attendance_model.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../../shared/widgets/interactive_map_widget.dart';
import '../../../shared/widgets/animated_refresh_button.dart';
import '../../profile/screens/profile_screen.dart';
import '../../reports/screens/report_helpdesk_screen.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({Key? key}) : super(key: key);

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  List<dynamic> _students = [];
  List<PklSubmissionModel> _submissions = [];
  List<PklEvidenceModel> _evidences = [];
  List<dynamic> _journals = [];
  List<AttendanceRecordModel> _attendanceRecords = [];
  List<Map<String, dynamic>> _companyProposals = [];
  String _attendanceFilter = 'all';
  String _classFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadAllTeacherData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllTeacherData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _fetchStudents(),
        _fetchSubmissions(),
        _fetchEvidences(),
        _fetchJournals(),
        _fetchAttendanceRecords(),
        _fetchCompanyProposals(),
      ]);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchStudents() async {
    try {
      final res = await ApiClient.get('${ApiEndpoints.baseUrl}/users?role=siswa');
      if (res.success && res.data != null) {
        if (res.data is List) {
          _students = res.data as List;
        } else if (res.data is Map && res.data['items'] is List) {
          _students = res.data['items'] as List;
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchSubmissions() async {
    try {
      final subs = await SubmissionService.getSubmissions();
      _submissions = subs;
    } catch (_) {}
  }

  Future<void> _fetchEvidences() async {
    try {
      final evs = await SubmissionService.getEvidences();
      _evidences = evs;
    } catch (_) {}
  }

  Future<void> _fetchJournals() async {
    try {
      final res = await ApiClient.get('${ApiEndpoints.baseUrl}/admin/journals');
      if (res.success && res.data != null) {
        if (res.data is List) {
          _journals = res.data as List;
        } else if (res.data is Map && res.data['items'] is List) {
          _journals = res.data['items'] as List;
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchAttendanceRecords() async {
    try {
      final res = await ApiClient.get(ApiEndpoints.attendanceRecords);
      if (res.success && res.data != null && res.data is List) {
        _attendanceRecords = (res.data as List)
            .map((e) => AttendanceRecordModel.fromJson(e))
            .toList();
      }
    } catch (_) {}
  }

  Future<void> _fetchCompanyProposals() async {
    try {
      final props = await SubmissionService.getCompanyProposals();
      _companyProposals = props;
    } catch (_) {}
  }

  // --- ATTENDANCE ACTIONS ---
  Future<void> _reviewAttendance(int recordId, String action, [String? notes]) async {
    setState(() => _isLoading = true);
    final res = await ApiClient.patch(
      ApiEndpoints.reviewAttendance(recordId),
      body: {'action': action, 'notes': notes},
    );
    if (mounted) {
      if (res.success) {
        setState(() {
          final idx = _attendanceRecords.indexWhere((r) => r.id == recordId);
          if (idx != -1) {
            final old = _attendanceRecords[idx];
            _attendanceRecords[idx] = AttendanceRecordModel(
              id: old.id,
              studentId: old.studentId,
              placementId: old.placementId,
              date: old.date,
              checkInTime: old.checkInTime,
              checkOutTime: old.checkOutTime,
              latitude: old.latitude,
              longitude: old.longitude,
              distanceMeters: old.distanceMeters,
              isInRadius: old.isInRadius,
              accuracyMeters: old.accuracyMeters,
              mockLocationDetected: old.mockLocationDetected,
              deviceFingerprint: old.deviceFingerprint,
              status: old.status,
              notes: old.notes,
              shiftName: old.shiftName,
              verifiedByMentor: old.verifiedByMentor,
              selfieUrl: old.selfieUrl,
              approvalStatus: action == 'APPROVE' ? 'APPROVED' : 'REJECTED',
              studentName: old.studentName,
              studentNisn: old.studentNisn,
            );
          }
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(action == 'APPROVE'
                ? 'Presensi siswa berhasil disetujui (ACC)!'
                : 'Presensi siswa ditolak.'),
            backgroundColor: action == 'APPROVE' ? AppColors.success : AppColors.error,
          ),
        );
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.error ?? 'Gagal memproses presensi.'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _confirmDeleteAttendance(AttendanceRecordModel record) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.delete_forever, color: AppColors.error),
            SizedBox(width: 8),
            Text('Hapus Riwayat Presensi',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus catatan presensi ${record.studentName ?? "siswa"} pada tanggal ${record.date}?',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final removedIndex = _attendanceRecords.indexWhere((r) => r.id == record.id);
              if (removedIndex != -1) {
                setState(() {
                  _attendanceRecords.removeAt(removedIndex);
                });
              }
              final res = await ApiClient.delete(ApiEndpoints.attendanceDetail(record.id));
              if (mounted) {
                if (res.success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Riwayat presensi siswa berhasil dihapus.'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                } else {
                  if (removedIndex != -1) {
                    setState(() {
                      _attendanceRecords.insert(removedIndex, record);
                    });
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(res.error ?? 'Gagal menghapus riwayat presensi.'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus Sekarang'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteSubmission(PklSubmissionModel sub) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.delete_forever, color: AppColors.error),
            SizedBox(width: 8),
            Text('Hapus Pengajuan PKL',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus data pengajuan PKL siswa "${sub.studentName ?? "Siswa"}" di "${sub.companyName ?? "Mitra"}"?',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final removedIndex = _submissions.indexWhere((s) => s.id == sub.id);
              if (removedIndex != -1) {
                setState(() {
                  _submissions.removeAt(removedIndex);
                });
              }
              final res = await SubmissionService.deleteSubmission(sub.id);
              if (mounted) {
                if (res.success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Riwayat pengajuan/approval PKL berhasil dihapus.'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                } else {
                  if (removedIndex != -1) {
                    setState(() {
                      _submissions.insert(removedIndex, sub);
                    });
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(res.error ?? 'Gagal menghapus pengajuan PKL.'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus Sekarang'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteJournal(dynamic journal) {
    final journalId = journal is Map ? journal['id'] : (journal.id ?? 0);
    final studentName = journal is Map ? (journal['student_name'] ?? 'Siswa') : 'Siswa';
    final date = journal is Map ? (journal['date'] ?? '') : '';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.delete_forever, color: AppColors.error),
            SizedBox(width: 8),
            Text('Hapus Jurnal Siswa',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus catatan jurnal $studentName pada tanggal $date?',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final removedIndex = _journals.indexWhere((j) => (j is Map ? j['id'] : j.id) == journalId);
              dynamic removedItem;
              if (removedIndex != -1) {
                removedItem = _journals[removedIndex];
                setState(() {
                  _journals.removeAt(removedIndex);
                });
              }
              final res = await ApiClient.delete('${ApiEndpoints.journals}/$journalId');
              if (mounted) {
                if (res.success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Jurnal siswa berhasil dihapus.'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                } else {
                  if (removedIndex != -1 && removedItem != null) {
                    setState(() {
                      _journals.insert(removedIndex, removedItem);
                    });
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(res.error ?? 'Gagal menghapus jurnal siswa.'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus Sekarang'),
          ),
        ],
      ),
    );
  }

  // --- COMPANY PROPOSAL ACTIONS ---
  Future<void> _approveCompanyProposal(int id) async {
    setState(() => _isLoading = true);
    final res = await SubmissionService.approveCompanyProposal(id);
    if (mounted) {
      if (res.success) {
        setState(() {
          _companyProposals.removeWhere((c) => c['id'] == id);
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usulan mitra PKL berhasil disetujui (ACC) & diaktifkan ke sistem!'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.error ?? 'Gagal menyetujui usulan mitra.'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _rejectCompanyProposal(int id) async {
    setState(() => _isLoading = true);
    final res = await SubmissionService.rejectCompanyProposal(id);
    if (mounted) {
      if (res.success) {
        setState(() {
          _companyProposals.removeWhere((c) => c['id'] == id);
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usulan mitra PKL ditolak.'),
            backgroundColor: AppColors.warning,
          ),
        );
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.error ?? 'Gagal menolak usulan.'), backgroundColor: AppColors.error),
        );
      }
    }
  }


  // --- SUBMISSION ACTIONS ---
  Future<void> _reviewSubmission(PklSubmissionModel sub, String status,
      [String? notes]) async {
    setState(() => _isLoading = true);
    final res = await SubmissionService.reviewSubmission(
      submissionId: sub.id,
      status: status,
      supervisorNotes: notes,
    );
    await _fetchSubmissions();
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.success
              ? 'Status pengajuan PKL berhasil diperbarui: $status'
              : (res.error ?? 'Gagal memproses.')),
          backgroundColor: res.success ? AppColors.success : AppColors.error,
        ),
      );
    }
  }

  void _showSubmissionNotesDialog(PklSubmissionModel sub, String action) {
    final notesCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            action == 'REJECTED'
                ? 'Tolak Pengajuan PKL'
                : 'Minta Perbaikan / Revisi',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Siswa: ${sub.studentName ?? "Siswa"}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 4),
              Text('Instansi: ${sub.companyName ?? "Perusahaan"}',
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              const SizedBox(height: 12),
              const Text('Catatan & Arahan Pembimbing:',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextField(
                controller: notesCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText:
                      'Tuliskan catatan perbaikan atau alasan penolakan...',
                  hintStyle: TextStyle(fontSize: 12),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _reviewSubmission(sub, action, notesCtrl.text.trim());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    action == 'REJECTED' ? AppColors.error : AppColors.warning,
                foregroundColor: Colors.white,
              ),
              child: Text(
                  action == 'REJECTED' ? 'Tolak Pengajuan' : 'Kirim Catatan'),
            ),
          ],
        );
      },
    );
  }

  // --- EVIDENCE ACTIONS ---
  Future<void> _verifyEvidence(PklEvidenceModel ev, String status,
      [String? notes]) async {
    setState(() => _isLoading = true);
    final res = await SubmissionService.verifyEvidence(
      evidenceId: ev.id,
      status: status,
      reviewNotes: notes,
    );
    await _fetchEvidences();
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.success
              ? 'Dokumen bukti berhasil diverifikasi: $status'
              : (res.error ?? 'Gagal memverifikasi.')),
          backgroundColor: res.success ? AppColors.success : AppColors.error,
        ),
      );
    }
  }

  void _showEvidenceNotesDialog(PklEvidenceModel ev, String action) {
    final notesCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            action == 'REJECTED'
                ? 'Tolak Dokumen Bukti'
                : 'Minta Perbaikan Bukti',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Judul Bukti: ${ev.title}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 10),
              const Text('Catatan Verifikator Guru:',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextField(
                controller: notesCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText:
                      'Contoh: Foto dokumentasi kurang jelas, sertakan lampiran laporan teknis...',
                  hintStyle: TextStyle(fontSize: 12),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _verifyEvidence(ev, action, notesCtrl.text.trim());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    action == 'REJECTED' ? AppColors.error : AppColors.warning,
                foregroundColor: Colors.white,
              ),
              child: const Text('Kirim Arahan'),
            ),
          ],
        );
      },
    );
  }

  // --- JOURNAL REVIEW & INSPECTION ---
  void _showFullImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              child: Center(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Text('Gagal memuat gambar dokumentasi.',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _reviewJournal(int id, String action, [String? notes]) async {
    final notesParam =
        notes != null ? "&notes=${Uri.encodeComponent(notes)}" : "";
    final res = await ApiClient.patch(
      '${ApiEndpoints.baseUrl}/admin/journals/$id/review?action=$action$notesParam',
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.success
              ? (action == 'approve'
                  ? 'Jurnal disetujui Guru Pembimbing!'
                  : 'Jurnal dikembalikan untuk revisi.')
              : (res.error ?? 'Gagal memproses jurnal.')),
          backgroundColor: res.success
              ? (action == 'approve' ? AppColors.success : AppColors.warning)
              : AppColors.error,
        ),
      );
      if (res.success) {
        _fetchJournals();
      }
    }
  }

  void _showJournalRevisionDialog(Map<String, dynamic> j) {
    final notesCtrl = TextEditingController();
    final studentName = j['student_name'] ?? j['reviewer_name'] ?? 'Siswa';
    final workSummary =
        j['work_summary'] ?? j['activity_description'] ?? 'Log teknis';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            String? errorText;
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: const [
                  Icon(Icons.edit_note, color: AppColors.warning, size: 22),
                  SizedBox(width: 8),
                  Text('Minta Revisi Jurnal',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLow,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Siswa: $studentName',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(height: 2),
                          Text(
                              'Tanggal: ${j['date'] ?? "-"} • Day ${j['day_number'] ?? "-"}',
                              style: const TextStyle(
                                  fontSize: 11, color: Color(0xFF64748B))),
                          const SizedBox(height: 6),
                          Text(
                            workSummary,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 11, fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text('Alasan / Arahan Perbaikan (Wajib Diisi):',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: notesCtrl,
                      maxLines: 3,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText:
                            'Contoh: Rincian CLI switch Cisco belum lengkap, sertakan foto topologi...',
                        hintStyle: const TextStyle(fontSize: 12),
                        border: const OutlineInputBorder(),
                        errorText: errorText,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final text = notesCtrl.text.trim();
                    if (text.isEmpty) {
                      setDialogState(() {
                        errorText = 'Catatan revisi wajib diisi!';
                      });
                      return;
                    }
                    Navigator.pop(ctx);
                    _reviewJournal(j['id'], 'revision', text);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warning,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Kirim Arahan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showJournalDetailModal(Map<String, dynamic> j) {
    final status = (j['status'] ?? 'pending').toString().toUpperCase();
    final studentName =
        j['student_name'] ?? j['reviewer_name'] ?? 'Siswa Bimbingan';
    final workSummary =
        j['work_summary'] ?? j['activity_description'] ?? 'Log pekerjaan PKL';
    final notes = j['revision_notes'] ?? j['mentor_notes'];
    final photo = j['photo_url'];

    List<dynamic> skills = [];
    if (j['ai_extracted_skills'] != null) {
      try {
        if (j['ai_extracted_skills'] is List) {
          skills = j['ai_extracted_skills'];
        } else if (j['ai_extracted_skills'] is String) {
          skills = jsonDecode(j['ai_extracted_skills']);
        }
      } catch (_) {}
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceLowest,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Jurnal: $studentName',
                              style: AppTypography.headlineSm
                                  .copyWith(fontWeight: FontWeight.bold)),
                          Text(
                              'Tanggal: ${j['date'] ?? "-"} • Day ${j['day_number'] ?? "-"} • ${j['hours_spent'] ?? 8.0} Jam',
                              style: const TextStyle(
                                  fontSize: 11, color: Color(0xFF64748B))),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: status == 'APPROVED' || status == 'VERIFIED'
                            ? AppColors.success.withOpacity(0.12)
                            : status == 'REVISION_REQUIRED' ||
                                    status == 'REVISION'
                                ? AppColors.warning.withOpacity(0.15)
                                : AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(9999),
                        border: Border.all(
                          color: status == 'APPROVED' || status == 'VERIFIED'
                              ? AppColors.success
                              : status == 'REVISION_REQUIRED' ||
                                      status == 'REVISION'
                                  ? AppColors.warning
                                  : AppColors.primary,
                        ),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: status == 'APPROVED' || status == 'VERIFIED'
                              ? AppColors.success
                              : status == 'REVISION_REQUIRED' ||
                                      status == 'REVISION'
                                  ? AppColors.warning
                                  : AppColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                if (photo != null && photo.toString().isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        InkWell(
                          onTap: () => _showFullImageDialog(context,
                              ApiEndpoints.getImageUrl(photo.toString())),
                          child: Image.network(
                            ApiEndpoints.getImageUrl(photo.toString()),
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 100,
                              color: AppColors.surfaceHigh,
                              child: const Center(
                                  child: Icon(Icons.broken_image, size: 36)),
                            ),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.all(8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.65),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.fullscreen,
                                  color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text('Lihat Foto Penuh',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 10)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Text('Uraian Log Pekerjaan Teknis',
                    style: AppTypography.labelMd
                        .copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLow,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(workSummary,
                      style: AppTypography.bodyMd.copyWith(height: 1.5)),
                ),
                if (skills.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('Kompetensi Teknis AI Terdeteksi (${skills.length})',
                      style: AppTypography.labelSm
                          .copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: skills.map((s) {
                      final name = s is Map ? (s['name'] ?? '') : s.toString();
                      final score = s is Map ? (s['score'] ?? '') : '';
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceHigh,
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: Text(
                            score.toString().isNotEmpty
                                ? '$name ($score%)'
                                : name,
                            style: const TextStyle(fontSize: 11)),
                      );
                    }).toList(),
                  ),
                ],
                if (notes != null && notes.toString().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.warning),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.assignment_late,
                                color: AppColors.warning, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'Catatan Evaluasi / Alasan Revisi:',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(notes.toString(),
                            style: const TextStyle(fontSize: 11)),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showJournalRevisionDialog(j);
                        },
                        icon: const Icon(Icons.edit_note, size: 16),
                        label: const Text('Minta Revisi'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.warning,
                          side: const BorderSide(color: AppColors.warning),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _reviewJournal(j['id'], 'approve',
                              'Disetujui oleh Guru Pembimbing.');
                        },
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Setujui Jurnal'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F766E),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openWhatsApp(String? phone) async {
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nomor telepon siswa belum terdaftar.')),
      );
      return;
    }
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final finalPhone = cleanPhone.startsWith('0')
        ? '62${cleanPhone.substring(1)}'
        : cleanPhone;
    final url = Uri.parse(
        'https://wa.me/$finalPhone?text=Halo%20siswa%20bimbingan%20PKL%20SMKN%203%20Yogyakarta');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(url, mode: LaunchMode.platformDefault);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nomor kontak: $phone')),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
      case 'VERIFIED':
        return AppColors.success;
      case 'CHANGE_REQUESTED':
      case 'REVISION_REQUIRED':
        return AppColors.warning;
      case 'REJECTED':
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }

  void _showStudentDetailModal(Map<String, dynamic> s) {
    final studentId = s['id'] as int?;
    final studentName = s['full_name'] ?? 'Siswa';
    final nisn = s['username'] ?? '-';
    final studentClass = s['student_class'] ?? '-';
    final phone = s['phone'] as String?;
    final email = s['email'] as String?;

    // Find submission - strictly for this student
    final sub = _submissions
        .where((sub) => sub.studentId == studentId)
        .firstOrNull;

    // Filter evidences strictly for this student
    final studentEvidences = _evidences
        .where((e) => studentId != null && e.studentId == studentId)
        .toList();

    // Filter journals strictly for this student
    final studentJournals = _journals
        .where((j) =>
            (studentId != null && j['student_id'] == studentId) ||
            (j['student_name'] != null &&
                studentName.isNotEmpty &&
                j['student_name'].toString().toLowerCase() ==
                    studentName.toLowerCase()))
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceLowest,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: DefaultTabController(
            length: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Header Profile
                Row(
                  children: [
                    UserAvatar(
                      avatarUrl: s['avatar_url'],
                      name: studentName,
                      radius: 26,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(studentName,
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.bold)),
                          Text('$studentClass • NISN: $nisn',
                              style: const TextStyle(
                                  fontSize: 11, color: Color(0xFF64748B))),
                          if (email != null && email.isNotEmpty)
                            Text(email,
                                style: const TextStyle(
                                    fontSize: 10, color: Color(0xFF94A3B8))),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chat,
                          color: Color(0xFF059669), size: 24),
                      tooltip: 'WhatsApp Siswa',
                      onPressed: () => _openWhatsApp(phone),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const TabBar(
                  indicatorColor: Color(0xFF0F766E),
                  labelColor: Color(0xFF0F766E),
                  unselectedLabelColor: Color(0xFF64748B),
                  tabs: [
                    Tab(text: 'Penempatan PKL'),
                    Tab(text: 'Portofolio Bukti'),
                    Tab(text: 'Jurnal Harian'),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: TabBarView(
                    children: [
                      // Sub-Tab 1: Penempatan PKL
                      SingleChildScrollView(
                        child: sub == null
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 40, horizontal: 20),
                                alignment: Alignment.center,
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFF1F5F9),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                          Icons.domain_disabled_outlined,
                                          size: 40,
                                          color: Color(0xFF94A3B8)),
                                    ),
                                    const SizedBox(height: 14),
                                    const Text(
                                      'Belum Ada Penempatan PKL',
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 6),
                                    const Text(
                                      'Siswa ini belum mengajukan atau belum memiliki penempatan tempat PKL aktif.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF64748B)),
                                    ),
                                  ],
                                ),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceLow,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text('STATUS PENEMPATAN',
                                                style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF64748B))),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: _getStatusColor(sub.status)
                                                    .withOpacity(0.15),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                sub.status.toUpperCase(),
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                  color: _getStatusColor(
                                                      sub.status),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          sub.companyName ?? 'Mitra Industri',
                                          style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                            'Diajukan: ${sub.submittedAt.toLocal().toString().split(" ").first}',
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF475569))),
                                        const Divider(height: 20),
                                        Row(
                                          children: [
                                            const Icon(Icons.info_outline,
                                                size: 16,
                                                color: Color(0xFF0F766E)),
                                            const SizedBox(width: 8),
                                            Text(
                                                'Catatan: ${sub.notes ?? "Tidak ada catatan"}',
                                                style: const TextStyle(
                                                    fontSize: 11,
                                                    color: Color(0xFF64748B))),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  // Map Coordinates & Geofence
                                  Text('LOKASI KANTOR & GEOFENCE PKL',
                                      style: AppTypography.labelSm.copyWith(
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: SizedBox(
                                      height: 160,
                                      child: InteractiveMapWidget(
                                        targetLat: sub.companyLatitude ?? -7.782871,
                                        targetLng: sub.companyLongitude ?? 110.367093,
                                        locationName: sub.companyName ??
                                            'Mitra Industri',
                                        radiusMeters: 100,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  OutlinedButton.icon(
                                    onPressed: () async {
                                      final lat = sub.companyLatitude ?? -7.782871;
                                      final lng = sub.companyLongitude ?? 110.367093;
                                      final url = Uri.parse(
                                          'https://www.google.com/maps/search/?api=1&query=$lat,$lng');
                                      try {
                                        if (await canLaunchUrl(url)) {
                                          await launchUrl(url,
                                              mode: LaunchMode.externalApplication);
                                        }
                                      } catch (_) {}
                                    },
                                    icon: const Icon(Icons.navigation, size: 16),
                                    label: const Text(
                                        'Buka Petunjuk Arah di Google Maps'),
                                    style: OutlinedButton.styleFrom(
                                      side:
                                          const BorderSide(color: Color(0xFF0F766E)),
                                      foregroundColor: const Color(0xFF0F766E),
                                      minimumSize: const Size.fromHeight(40),
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ],
                              ),
                      ),

                      // Sub-Tab 2: Portofolio Bukti
                      studentEvidences.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.folder_open,
                                      size: 40, color: Color(0xFFCBD5E1)),
                                  SizedBox(height: 6),
                                  Text(
                                      'Siswa belum mengunggah dokumen bukti PKL.',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF64748B))),
                                ],
                              ),
                            )
                          : ListView.separated(
                              itemCount: studentEvidences.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, idx) {
                                final ev = studentEvidences[idx];
                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceLow,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            ev.category
                                                .toUpperCase()
                                                .replaceAll('_', ' '),
                                            style: const TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF0F766E)),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(ev.status)
                                                  .withOpacity(0.15),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              ev.status,
                                              style: TextStyle(
                                                fontSize: 8,
                                                fontWeight: FontWeight.bold,
                                                color:
                                                    _getStatusColor(ev.status),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(ev.title,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold)),
                                      if (ev.description != null &&
                                          ev.description!.isNotEmpty)
                                        Text(ev.description!,
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF64748B))),
                                      if (ev.fileUrl.isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: InkWell(
                                            onTap: () => _showFullImageDialog(context, ApiEndpoints.getImageUrl(ev.fileUrl)),
                                            child: Image.network(
                                              ApiEndpoints.getImageUrl(ev.fileUrl),
                                              height: 120,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => Container(
                                                height: 40,
                                                color: AppColors.surfaceHigh,
                                                padding: const EdgeInsets.all(6),
                                                child: Row(
                                                  children: [
                                                    const Icon(Icons.description, size: 16, color: Color(0xFF0F766E)),
                                                    const SizedBox(width: 6),
                                                    Expanded(
                                                      child: Text(ev.fileUrl,
                                                          style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
                                                          overflow: TextOverflow.ellipsis),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          OutlinedButton(
                                            onPressed: () {
                                              Navigator.pop(ctx);
                                              _showEvidenceNotesDialog(
                                                  ev, 'REVISION_REQUIRED');
                                            },
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor:
                                                  AppColors.warning,
                                              side: const BorderSide(
                                                  color: AppColors.warning),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                              minimumSize: Size.zero,
                                            ),
                                            child: const Text('Minta Revisi',
                                                style: TextStyle(fontSize: 10)),
                                          ),
                                          const SizedBox(width: 6),
                                          ElevatedButton(
                                            onPressed: () {
                                              Navigator.pop(ctx);
                                              _verifyEvidence(ev, 'VERIFIED',
                                                  'Dokumen sah diverifikasi.');
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  const Color(0xFF0F766E),
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 4),
                                              minimumSize: Size.zero,
                                            ),
                                            child: const Text('Verifikasi',
                                                style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),

                      // Sub-Tab 3: Jurnal Harian
                      studentJournals.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.menu_book,
                                      size: 40, color: Color(0xFFCBD5E1)),
                                  SizedBox(height: 6),
                                  Text('Belum ada log jurnal dari siswa ini.',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF64748B))),
                                ],
                              ),
                            )
                          : ListView.separated(
                              itemCount: studentJournals.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, idx) {
                                final j = studentJournals[idx];
                                final jStatus = (j['status'] ?? 'pending')
                                    .toString()
                                    .toLowerCase();
                                final workSummary = j['work_summary'] ??
                                    j['activity_description'] ??
                                    'Log tugas harian PKL';
                                final date = j['date'] ?? '';
                                final hasPhoto = j['photo_url'] != null &&
                                    j['photo_url'].toString().isNotEmpty;

                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceLow,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(date,
                                              style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF64748B))),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: jStatus == 'approved'
                                                  ? const Color(0xFFECFDF5)
                                                  : const Color(0xFFFEF3C7),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              jStatus.toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 8,
                                                fontWeight: FontWeight.bold,
                                                color: jStatus == 'approved'
                                                    ? const Color(0xFF059669)
                                                    : Colors.amber.shade800,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (hasPhoto) ...[
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              child: Image.network(
                                                ApiEndpoints.getImageUrl(
                                                    j['photo_url']),
                                                width: 44,
                                                height: 44,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) =>
                                                    const Icon(Icons.image,
                                                        size: 24),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                          ],
                                          Expanded(
                                            child: Text(
                                              workSummary,
                                              style: const TextStyle(
                                                  fontSize: 11, height: 1.3),
                                              maxLines: 3,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          OutlinedButton(
                                            onPressed: () {
                                              Navigator.pop(ctx);
                                              _reviewJournal(j['id'], 'revision',
                                                  'Perbaiki rincian log teknis.');
                                            },
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor:
                                                  AppColors.warning,
                                              side: const BorderSide(
                                                  color: AppColors.warning),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                              minimumSize: Size.zero,
                                            ),
                                            child: const Text('Minta Revisi',
                                                style: TextStyle(fontSize: 10)),
                                          ),
                                          const SizedBox(width: 6),
                                          ElevatedButton(
                                            onPressed: () {
                                              Navigator.pop(ctx);
                                              _reviewJournal(j['id'], 'approve',
                                                  'Disetujui oleh Guru Pembimbing.');
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  const Color(0xFF0F766E),
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 4),
                                              minimumSize: Size.zero,
                                            ),
                                            child: const Text('Setujui',
                                                style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F766E),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: Colors.teal.shade800,
                  borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.school, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('PORTAL GURU PEMBIMBING',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold)),
                Text(user?.fullName ?? 'Dra. Sri Wahyuningsih, M.Pd.',
                    style: const TextStyle(
                        color: Color(0xFFCCFBF1), fontSize: 10)),
              ],
            ),
          ],
        ),
        actions: [
          AnimatedRefreshButton(
            onRefresh: _loadAllTeacherData,
            color: Colors.white,
          ),
          IconButton(
            icon: const Icon(Icons.support_agent, color: Colors.white),
            tooltip: 'Lapor Kendala / Bug',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReportHelpdeskScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.white),
            tooltip: 'Profil Guru',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFFFDA4AF)),
            tooltip: 'Keluar Akun',
            onPressed: () async {
              await auth.logout();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amber,
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xFFCCFBF1),
          isScrollable: true,
          tabs: [
            Tab(
                icon: const Icon(Icons.people, size: 16),
                text: 'Siswa (${_students.length})'),
            Tab(
                icon: const Icon(Icons.approval, size: 16),
                text: 'Approval PKL (${_submissions.length + _companyProposals.length})'),
            Tab(
                icon: const Icon(Icons.verified, size: 16),
                text: 'Verifikasi Bukti (${_evidences.length})'),
            Tab(
                icon: const Icon(Icons.auto_stories, size: 16),
                text: 'Jurnal (${_journals.length})'),
            Tab(
                icon: const Icon(Icons.co_present, size: 16),
                text: 'Presensi (${_attendanceRecords.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildStudentsTab(),
                _buildSubmissionsTab(),
                _buildEvidencesTab(),
                _buildJournalsTab(),
                _buildAttendanceTab(),
              ],
            ),
    );
  }

  // TAB 1: SISWA BIMBINGAN
  Widget _buildStudentsTab() {
    // Collect distinct classes
    final Set<String> availableClasses = {};
    for (var s in _students) {
      final cls = s['student_class'];
      if (cls != null && cls.toString().trim().isNotEmpty) {
        availableClasses.add(cls.toString().trim());
      }
    }
    final sortedClasses = availableClasses.toList()..sort();

    final filteredStudents = _classFilter == 'all'
        ? _students
        : _students.where((s) => s['student_class'] == _classFilter).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner Metric
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF0F766E), Color(0xFF0D9488)]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFF0F766E).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Monitoring Siswa Bimbingan',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6)),
                      child: Text(
                          '${filteredStudents.isNotEmpty ? "${filteredStudents.length} Siswa" : "Belum Ada Siswa"} • AKTIF',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                    'Pengawasan & Evaluasi Lapangan Praktik Kerja Lapangan',
                    style: TextStyle(color: Color(0xFFCCFBF1), fontSize: 11)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCol('Total Siswa', '${filteredStudents.length} Orang'),
                    _buildStatCol('Ditempatkan',
                        '${filteredStudents.where((s) => _submissions.any((sub) => sub.studentId == s['id'] && sub.status == "APPROVED")).length} Siswa'),
                    _buildStatCol('Jurnal Masuk', '${_journals.where((j) => filteredStudents.any((s) => s['id'] == j['student_id'])).length} Log'),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Class Filter Chips
          if (sortedClasses.isNotEmpty) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  InkWell(
                    onTap: () => setState(() => _classFilter = 'all'),
                    borderRadius: BorderRadius.circular(9999),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _classFilter == 'all' ? const Color(0xFF0F766E) : AppColors.surfaceHigh,
                        borderRadius: BorderRadius.circular(9999),
                        border: Border.all(
                          color: _classFilter == 'all' ? const Color(0xFF0F766E) : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: Text(
                        'Semua Kelas (${_students.length})',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: _classFilter == 'all' ? FontWeight.bold : FontWeight.w500,
                          color: _classFilter == 'all' ? Colors.white : AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ...sortedClasses.map((cls) {
                    final isSelected = _classFilter == cls;
                    final count = _students.where((s) => s['student_class'] == cls).length;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () => setState(() => _classFilter = cls),
                        borderRadius: BorderRadius.circular(9999),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF0F766E) : AppColors.surfaceHigh,
                            borderRadius: BorderRadius.circular(9999),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF0F766E) : const Color(0xFFCBD5E1),
                            ),
                          ),
                          child: Text(
                            '$cls ($count)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          Text('DAFTAR SISWA DALAM PENGAWASAN',
              style:
                  AppTypography.labelSm.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),

          filteredStudents.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLowest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Center(
                    child: Column(
                      children: const [
                        Icon(Icons.person_off_outlined, size: 36, color: Color(0xFF94A3B8)),
                        SizedBox(height: 8),
                        Text('Tidak ada siswa pada filter kelas yang dipilih.',
                            style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredStudents.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final s = filteredStudents[index];
              final studentSub = _submissions
                  .where((sub) => sub.studentId == s['id'])
                  .firstOrNull;
              final isApproved = studentSub?.status == 'APPROVED';
              return InkWell(
                onTap: () => _showStudentDetailModal(s),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLowest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      UserAvatar(
                        avatarUrl: s['avatar_url'],
                        name: s['full_name'],
                        radius: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s['full_name'] ?? 'Siswa',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 2),
                            Text(
                                '${s['student_class'] ?? "-"} • NISN: ${s['username'] ?? "-"}',
                                style: const TextStyle(
                                    fontSize: 11, color: Color(0xFF64748B))),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                  color: isApproved
                                      ? const Color(0xFFECFDF5)
                                      : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(4)),
                              child: Text(
                                  studentSub != null
                                      ? 'Status: ${studentSub.status} (${studentSub.companyName ?? "-"})'
                                      : 'Status: Belum Penempatan PKL',
                                  style: TextStyle(
                                      color: isApproved
                                          ? const Color(0xFF059669)
                                          : const Color(0xFF64748B),
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chat,
                            color: Color(0xFF059669), size: 22),
                        tooltip: 'Hubungi via WhatsApp',
                        onPressed: () => _openWhatsApp(s['phone']),
                      ),
                      const Icon(Icons.chevron_right,
                          color: Color(0xFF94A3B8), size: 18),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // TAB 2: APPROVAL PKL & PINDAH & USULAN MITRA
  Widget _buildSubmissionsTab() {
    if (_submissions.isEmpty && _companyProposals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline,
                size: 48, color: AppColors.outline),
            const SizedBox(height: 8),
            Text('Tidak ada antrian pengajuan PKL maupun usulan mitra baru.',
                style:
                    TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12)),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section 1: Usulan Tempat Mitra PKL Baru dari Siswa
          if (_companyProposals.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0F766E).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF0F766E).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.add_business, color: Color(0xFF0F766E), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'USULAN MITRA PKL BARU DARI SISWA (${_companyProposals.length})',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F766E),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _companyProposals.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final prop = _companyProposals[index];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLowest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF0F766E).withOpacity(0.4)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'USULAN MITRA BARU',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF059669),
                              ),
                            ),
                          ),
                          Text(
                            prop['division'] ?? 'Sektor DUDI',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        prop['name'] ?? 'Nama Industri',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        prop['address'] ?? '-',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                      if (prop['mentor_name'] != null || prop['mentor_phone'] != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.person_outline, size: 13, color: AppColors.secondary),
                            const SizedBox(width: 4),
                            Text(
                              'PIC: ${prop['mentor_name'] ?? "-"} • Telp: ${prop['mentor_phone'] ?? "-"}',
                              style: const TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                      ],
                      if (prop['notes'] != null && prop['notes'].toString().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Catatan Pengajuan: "${prop['notes']}"',
                          style: const TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: Color(0xFF0F766E),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _rejectCompanyProposal(prop['id']),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.error,
                                side: const BorderSide(color: AppColors.error),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Tolak Usulan', style: TextStyle(fontSize: 11)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _approveCompanyProposal(prop['id']),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0F766E),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('ACC & Aktifkan Mitra',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],

          // Section 2: Submissions & Change Requests
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.approval, color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Text(
                  'PERMOHONAN PENEMPATAN & PINDAH PKL (${_submissions.length})',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          if (_submissions.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.center,
              child: const Text('Tidak ada permohonan penempatan PKL.',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _submissions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final sub = _submissions[index];
                final isChangeRequest = sub.status == 'CHANGE_REQUESTED';

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLowest,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: isChangeRequest
                            ? AppColors.warning
                            : const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isChangeRequest
                                  ? AppColors.warningContainer
                                  : AppColors.surfaceHigh,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isChangeRequest
                                  ? 'PERMOHONAN GANTI PKL'
                                  : 'PENGAJUAN PKL BARU',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: isChangeRequest
                                    ? AppColors.onWarningContainer
                                    : AppColors.primary,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _getStatusColor(sub.status).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              sub.status,
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: _getStatusColor(sub.status)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(sub.studentName ?? 'Siswa PKL',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('NISN: ${sub.studentNisn ?? "-"}',
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF64748B))),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            color: AppColors.surfaceLow,
                            borderRadius: BorderRadius.circular(8)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                'Perusahaan Tujuan: ${sub.companyName ?? "-"}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 12)),
                            Text(sub.address ?? '-',
                                style: const TextStyle(
                                    fontSize: 10, color: Color(0xFF64748B))),
                            if (sub.changeReason != null &&
                                sub.changeReason!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text('Alasan Pindah: "${sub.changeReason}"',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontStyle: FontStyle.italic,
                                      color: AppColors.warning)),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () =>
                                  _showSubmissionNotesDialog(sub, 'REVISION_REQUIRED'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.warning,
                                side: const BorderSide(color: AppColors.warning),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Minta Revisi',
                                  style: TextStyle(fontSize: 11)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () =>
                                  _showSubmissionNotesDialog(sub, 'REJECTED'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.error,
                                side: const BorderSide(color: AppColors.error),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Tolak',
                                  style: TextStyle(fontSize: 11)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _reviewSubmission(
                                  sub,
                                  'APPROVED',
                                  isChangeRequest
                                      ? 'Perpindahan PKL disetujui Guru Pembimbing'
                                      : 'Disetujui oleh Guru Pembimbing'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0F766E),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                              child: Text(
                                  isChangeRequest ? 'Setujui Pindah' : 'Setujui',
                                  style: const TextStyle(
                                      fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFFECACA)),
                            ),
                            child: IconButton(
                              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                              padding: const EdgeInsets.all(6),
                              icon: const Icon(Icons.delete_outline,
                                  color: AppColors.error, size: 18),
                              tooltip: 'Hapus Riwayat Pengajuan Ini',
                              onPressed: () => _confirmDeleteSubmission(sub),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // TAB 3: VERIFIKASI BUKTI
  Widget _buildEvidencesTab() {
    if (_evidences.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_shared, size: 48, color: AppColors.outline),
            const SizedBox(height: 8),
            Text('Tidak ada dokumen bukti yang memerlukan verifikasi.',
                style:
                    TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _evidences.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final ev = _evidences[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceLowest,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(6)),
                    child: Text(
                      ev.category.toUpperCase().replaceAll('_', ' '),
                      style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _getStatusColor(ev.status).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      ev.status,
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(ev.status)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLow,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 14,
                      backgroundColor: Color(0xFFCCFBF1),
                      child: Icon(Icons.person, size: 16, color: Color(0xFF0F766E)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${ev.studentName ?? "Siswa PKL"}${ev.studentClass != null ? " • ${ev.studentClass}" : ""}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                          Text(
                            ev.companyName ?? 'PT Telkom Indonesia (Witel Yogyakarta)',
                            style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Text(ev.title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13)),
              if (ev.description != null && ev.description!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(ev.description!,
                    style: TextStyle(
                        fontSize: 11, color: AppColors.onSurfaceVariant)),
              ],
              if (ev.fileUrl.isNotEmpty) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      InkWell(
                        onTap: () => _showFullImageDialog(
                            context, ApiEndpoints.getImageUrl(ev.fileUrl)),
                        child: Image.network(
                          ApiEndpoints.getImageUrl(ev.fileUrl),
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 60,
                            color: AppColors.surfaceHigh,
                            padding: const EdgeInsets.all(8),
                            child: Row(
                              children: [
                                const Icon(Icons.description, color: Color(0xFF0F766E), size: 24),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(ev.fileUrl,
                                      style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
                                      overflow: TextOverflow.ellipsis),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.65),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.fullscreen, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text('Perbesar Foto',
                                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          _showEvidenceNotesDialog(ev, 'REVISION_REQUIRED'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.warning,
                        side: const BorderSide(color: AppColors.warning),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Minta Revisi',
                          style: TextStyle(fontSize: 11)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showEvidenceNotesDialog(ev, 'REJECTED'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child:
                          const Text('Tolak', style: TextStyle(fontSize: 11)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _verifyEvidence(ev, 'VERIFIED',
                          'Dokumen sah & terverifikasi oleh Guru Pembimbing.'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F766E),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Verifikasi',
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // TAB 4: MONITORING JURNAL
  Widget _buildJournalsTab() {
    if (_journals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book, size: 48, color: AppColors.outline),
            const SizedBox(height: 8),
            Text('Belum ada log jurnal harian siswa.',
                style:
                    TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _journals.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final j = _journals[index];
        final status = (j['status'] ?? 'pending').toString().toLowerCase();
        final studentName = j['student_name'] ?? j['reviewer_name'] ?? 'Siswa Bimbingan';
        final workSummary = j['work_summary'] ?? j['activity_description'] ?? 'Log aktivitas teknis PKL';
        final notes = j['revision_notes'] ?? j['mentor_notes'];
        final photo = j['photo_url'];

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceLowest,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F766E).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          studentName,
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F766E)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(j['date'] ?? '',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF64748B))),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: status == 'approved'
                          ? const Color(0xFFECFDF5)
                          : status == 'revision' || status == 'revision_required'
                              ? const Color(0xFFFEF3C7)
                              : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: status == 'approved'
                            ? const Color(0xFF059669)
                            : status == 'revision' || status == 'revision_required'
                                ? Colors.amber.shade800
                                : AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (photo != null && photo.toString().isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        ApiEndpoints.getImageUrl(photo.toString()),
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 28),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Text(
                      workSummary,
                      style: TextStyle(
                          fontSize: 12, height: 1.4, color: AppColors.onSurface),
                    ),
                  ),
                ],
              ),
              if (notes != null && notes.toString().isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: AppColors.surfaceLow,
                      borderRadius: BorderRadius.circular(8)),
                  child: Text('Catatan Evaluasi: $notes',
                      style: const TextStyle(
                          fontSize: 10, color: Color(0xFF475569))),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _showJournalDetailModal(j),
                    icon: const Icon(Icons.visibility_outlined, size: 14),
                    label: const Text('Lihat Detail',
                        style: TextStyle(fontSize: 11)),
                  ),
                  const SizedBox(width: 6),
                  OutlinedButton(
                    onPressed: () => _showJournalRevisionDialog(j),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.warning,
                      side: const BorderSide(color: AppColors.warning),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                    ),
                    child: const Text('Minta Revisi',
                        style: TextStyle(fontSize: 11)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _reviewJournal(
                        j['id'], 'approve', 'Disetujui oleh Guru Pembimbing.'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F766E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                    ),
                    child: const Text('Setujui Jurnal',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: IconButton(
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      padding: const EdgeInsets.all(6),
                      icon: const Icon(Icons.delete_outline,
                          color: AppColors.error, size: 18),
                      tooltip: 'Hapus Jurnal Siswa',
                      onPressed: () => _confirmDeleteJournal(j),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCol(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(color: Color(0xFFCCFBF1), fontSize: 10)),
      ],
    );
  }

  // TAB 5: APPROVAL & RIWAYAT PRESENSI SISWA
  Widget _buildAttendanceTab() {
    List<AttendanceRecordModel> filtered = _attendanceRecords;
    if (_attendanceFilter == 'pending') {
      filtered = _attendanceRecords
          .where((r) => r.approvalStatus.toUpperCase() == 'PENDING')
          .toList();
    } else if (_attendanceFilter == 'approved') {
      filtered = _attendanceRecords
          .where((r) => r.approvalStatus.toUpperCase() == 'APPROVED')
          .toList();
    } else if (_attendanceFilter == 'rejected') {
      filtered = _attendanceRecords
          .where((r) => r.approvalStatus.toUpperCase() == 'REJECTED')
          .toList();
    }

    final pendingCount = _attendanceRecords
        .where((r) => r.approvalStatus.toUpperCase() == 'PENDING')
        .length;
    final approvedCount = _attendanceRecords
        .where((r) => r.approvalStatus.toUpperCase() == 'APPROVED')
        .length;
    final rejectedCount = _attendanceRecords
        .where((r) => r.approvalStatus.toUpperCase() == 'REJECTED')
        .length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner Metric
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF0F766E), Color(0xFF0D9488)]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFF0F766E).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Approval & Riwayat Presensi Siswa',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6)),
                      child: const Text('GEOFENCE + SELFIE',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCol('Total Presensi', '${_attendanceRecords.length}'),
                    _buildStatCol('Menunggu ACC', '$pendingCount'),
                    _buildStatCol('Disetujui', '$approvedCount'),
                    _buildStatCol('Ditolak', '$rejectedCount'),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildAttendanceFilterChip('all', 'Semua (${_attendanceRecords.length})'),
                const SizedBox(width: 8),
                _buildAttendanceFilterChip('pending', 'Menunggu ACC ($pendingCount)'),
                const SizedBox(width: 8),
                _buildAttendanceFilterChip('approved', 'Disetujui ($approvedCount)'),
                const SizedBox(width: 8),
                _buildAttendanceFilterChip('rejected', 'Ditolak ($rejectedCount)'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          if (filtered.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Icon(Icons.fact_check_outlined, size: 48, color: AppColors.outline),
                  const SizedBox(height: 12),
                  Text('Tidak ada riwayat presensi yang sesuai filter.',
                      style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12)),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final rec = filtered[index];
                final isPending = rec.approvalStatus.toUpperCase() == 'PENDING';
                final isApproved = rec.approvalStatus.toUpperCase() == 'APPROVED';
                final isRejected = rec.approvalStatus.toUpperCase() == 'REJECTED';
                final hasSelfie = rec.selfieUrl != null && rec.selfieUrl!.isNotEmpty;
                final fullSelfieUrl = hasSelfie ? ApiEndpoints.getImageUrl(rec.selfieUrl) : '';

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLowest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isPending
                          ? Colors.amber.shade400
                          : isApproved
                              ? const Color(0xFFE2E8F0)
                              : const Color(0xFFFECACA),
                      width: isPending ? 1.5 : 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row: Student info & status badge
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          UserAvatar(
                            name: rec.studentName ?? 'Siswa',
                            radius: 17,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  rec.studentName ?? 'Siswa Bimbingan',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'NISN: ${rec.studentNisn ?? "-"}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 10.5, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: isApproved
                                  ? const Color(0xFFECFDF5)
                                  : isRejected
                                      ? const Color(0xFFFEF2F2)
                                      : const Color(0xFFFFFBEB),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isApproved
                                    ? AppColors.success
                                    : isRejected
                                        ? AppColors.error
                                        : AppColors.warning,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isApproved
                                      ? Icons.check_circle
                                      : isRejected
                                          ? Icons.cancel
                                          : Icons.hourglass_top_rounded,
                                  size: 11,
                                  color: isApproved
                                      ? AppColors.success
                                      : isRejected
                                          ? AppColors.error
                                          : Colors.amber.shade900,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isApproved
                                      ? 'DISETUJUI'
                                      : isRejected
                                          ? 'DITOLAK'
                                          : 'MENUNGGU ACC',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.2,
                                    color: isApproved
                                        ? AppColors.success
                                        : isRejected
                                            ? AppColors.error
                                            : Colors.amber.shade900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      const SizedBox(height: 10),

                      // Content: Selfie thumbnail & Details
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Selfie thumbnail
                          if (hasSelfie && fullSelfieUrl.isNotEmpty)
                            InkWell(
                              onTap: () => _showFullImageDialog(context, fullSelfieUrl),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                width: 68,
                                height: 68,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFCBD5E1)),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(9),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.network(
                                        fullSelfieUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => const Icon(
                                            Icons.image_not_supported,
                                            size: 24,
                                            color: Colors.grey),
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        left: 0,
                                        right: 0,
                                        child: Container(
                                          color: Colors.black.withValues(alpha: 0.65),
                                          padding: const EdgeInsets.symmetric(vertical: 2),
                                          child: const Text(
                                            'SELFIE',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 8,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 0.5),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          else
                            Container(
                              width: 68,
                              height: 68,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceHigh,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.face_retouching_natural,
                                      size: 26, color: Color(0xFF94A3B8)),
                                  SizedBox(height: 2),
                                  Text('No Selfie',
                                      style: TextStyle(fontSize: 8, color: Color(0xFF94A3B8))),
                                ],
                              ),
                            ),

                          // Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Date and Time
                                Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.calendar_today,
                                            size: 12, color: AppColors.primary),
                                        const SizedBox(width: 4),
                                        Text(
                                          rec.date,
                                          style: const TextStyle(
                                              fontSize: 11, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.access_time,
                                            size: 12, color: AppColors.secondary),
                                        const SizedBox(width: 4),
                                        Text(
                                          rec.checkInTime != null
                                              ? rec.checkInTime!.contains('T')
                                                  ? '${rec.checkInTime!.split('T')[1].substring(0, 5)} WIB'
                                                  : '${rec.checkInTime!} WIB'
                                              : '07:45 WIB',
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),

                                // Radius & Geofence
                                Row(
                                  children: [
                                    Icon(
                                      rec.isInRadius ? Icons.check_circle : Icons.warning_amber_rounded,
                                      size: 12,
                                      color: rec.isInRadius
                                          ? AppColors.success
                                          : AppColors.warning,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        'Radius ${rec.distanceMeters.toStringAsFixed(1)}m • ${rec.isInRadius ? "Dalam Radius" : "Luar Radius"}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          color: rec.isInRadius
                                              ? AppColors.success
                                              : AppColors.warning,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),

                                // Shift
                                Row(
                                  children: [
                                    const Icon(Icons.business_outlined, size: 12, color: Color(0xFF64748B)),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        rec.shiftName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontSize: 10, color: Color(0xFF64748B)),
                                      ),
                                    ),
                                  ],
                                ),

                                // Notes (if present)
                                if (rec.notes != null && rec.notes!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.edit_note, size: 13, color: Color(0xFF64748B)),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          rec.notes!,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              fontSize: 10, color: Color(0xFF475569)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      const SizedBox(height: 10),

                      // Action buttons: ACC, Tolak, and Hapus (Trash)
                      Row(
                        children: [
                          if (isPending) ...[
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _reviewAttendance(rec.id, 'APPROVE'),
                                icon: const Icon(Icons.check, size: 14),
                                label: const Text('Setujui (ACC)',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0F766E),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _reviewAttendance(rec.id, 'REJECT'),
                                icon: const Icon(Icons.close, size: 14),
                                label: const Text('Tolak', style: TextStyle(fontSize: 11)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.warning,
                                  side: const BorderSide(color: AppColors.warning),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ] else ...[
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _reviewAttendance(
                                    rec.id, isApproved ? 'REJECT' : 'APPROVE'),
                                icon: Icon(isApproved ? Icons.close : Icons.check, size: 14),
                                label: Text(isApproved ? 'Ubah ke Ditolak' : 'Ubah ke ACC',
                                    style: const TextStyle(fontSize: 11)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: isApproved ? AppColors.warning : const Color(0xFF0F766E),
                                  side: BorderSide(
                                      color: isApproved ? AppColors.warning : const Color(0xFF0F766E)),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFFECACA)),
                            ),
                            child: IconButton(
                              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                              padding: const EdgeInsets.all(6),
                              icon: const Icon(Icons.delete_outline,
                                  color: AppColors.error, size: 18),
                              tooltip: 'Hapus Riwayat Presensi Ini',
                              onPressed: () => _confirmDeleteAttendance(rec),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAttendanceFilterChip(String key, String label) {
    final isSelected = _attendanceFilter == key;
    return InkWell(
      onTap: () => setState(() => _attendanceFilter = key),
      borderRadius: BorderRadius.circular(9999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F766E) : AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(
            color: isSelected ? const Color(0xFF0F766E) : const Color(0xFFCBD5E1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
