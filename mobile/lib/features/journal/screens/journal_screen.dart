import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/typography.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/journal_provider.dart';
import '../models/journal_model.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({Key? key}) : super(key: key);

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final _textEditorController = TextEditingController();
  Map<String, dynamic>? _liveAiAnalysis;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<JournalProvider>(context, listen: false).fetchJournals();
    });
  }

  @override
  void dispose() {
    _textEditorController.dispose();
    super.dispose();
  }

  Color _getStatusBadgeColor(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
      case 'VERIFIED':
        return AppColors.success;
      case 'REVIEW':
      case 'SUBMITTED':
        return const Color(0xFF0F766E);
      case 'REVISION_REQUIRED':
        return AppColors.warning;
      case 'REJECTED':
        return AppColors.error;
      default:
        return const Color(0xFF64748B);
    }
  }

  String _getStatusDisplay(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
        return 'DISETUJUI';
      case 'REVIEW':
        return 'MENUNGGU VALIDASI';
      case 'SUBMITTED':
        return 'DIAJUKAN';
      case 'REVISION_REQUIRED':
        return 'PERLU REVISI';
      case 'REJECTED':
        return 'DITOLAK';
      case 'DRAFT':
        return 'DRAFT';
      default:
        return status.toUpperCase();
    }
  }

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
                    child: Text('Gagal memuat gambar.',
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

  void _openJournalModal([JournalModel? existing]) {
    _textEditorController.text = existing != null
        ? existing.workSummary
        : 'Melakukan konfigurasi Trunking 802.1Q dan pemisahan broadcast domain pada Switch Cisco Catalyst 3850, dilanjutkan dengan troubleshooting routing loop spanning-tree (STP) di ruang NOC Telkom Kotabaru.';
    _liveAiAnalysis = null;
    PlatformFile? attachedPhoto;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceLowest,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
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
                        Text(
                          existing != null
                              ? 'Edit / Revisi Jurnal'
                              : 'Tulis Jurnal Harian PKL',
                          style: AppTypography.headlineSm
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLow,
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.auto_awesome,
                                  size: 14, color: AppColors.secondary),
                              const SizedBox(width: 4),
                              Text(
                                'AI NLP Parser',
                                style: AppTypography.labelSm
                                    .copyWith(color: AppColors.secondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (existing != null &&
                        existing.revisionNotes != null &&
                        existing.revisionNotes!.isNotEmpty) ...[
                      const SizedBox(height: 12),
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
                                  'Catatan Arahan Revisi Pembimbing:',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: Color(0xFF92400E)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              existing.revisionNotes!,
                              style: const TextStyle(
                                  fontSize: 12, color: Color(0xFF78350F)),
                            ),
                            if (existing.reviewerName != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Oleh: ${existing.reviewerName}',
                                style: const TextStyle(
                                    fontSize: 10, color: Color(0xFF92400E)),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextField(
                      controller: _textEditorController,
                      maxLines: 5,
                      style: AppTypography.bodyMd,
                      decoration: const InputDecoration(
                        hintText:
                            'Deskripsikan tugas teknis yang dikerjakan hari ini...',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (text) async {
                        if (text.length > 20) {
                          final provider = Provider.of<JournalProvider>(context,
                              listen: false);
                          final res = await provider.analyzeAiText(text);
                          if (res != null) {
                            setModalState(() {
                              _liveAiAnalysis = res;
                            });
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    Text('Foto Dokumentasi Lapangan:',
                        style: AppTypography.labelSm
                            .copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    if (attachedPhoto != null)
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLow,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Row(
                          children: [
                            if (attachedPhoto!.bytes != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(
                                  attachedPhoto!.bytes!,
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                ),
                              )
                            else
                              const Icon(Icons.image,
                                  size: 36, color: AppColors.primary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(attachedPhoto!.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                  Text(
                                      '${((attachedPhoto!.size) / 1024).toStringAsFixed(1)} KB',
                                      style: const TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF64748B))),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close,
                                  color: AppColors.error, size: 20),
                              onPressed: () {
                                setModalState(() => attachedPhoto = null);
                              },
                            ),
                          ],
                        ),
                      )
                    else if (existing != null &&
                        existing.photoUrl != null &&
                        existing.photoUrl!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLow,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                ApiEndpoints.getImageUrl(existing.photoUrl),
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.image, size: 36),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text('Foto dokumentasi tersimpan di server',
                                  style: TextStyle(fontSize: 11)),
                            ),
                            TextButton(
                              onPressed: () async {
                                final res = await FilePicker.platform.pickFiles(
                                  type: FileType.image,
                                  withData: true,
                                );
                                if (res != null && res.files.isNotEmpty) {
                                  setModalState(
                                      () => attachedPhoto = res.files.first);
                                }
                              },
                              child: const Text('Ganti',
                                  style: TextStyle(fontSize: 11)),
                            ),
                          ],
                        ),
                      )
                    else
                      OutlinedButton.icon(
                        onPressed: () async {
                          final res = await FilePicker.platform.pickFiles(
                            type: FileType.image,
                            withData: true,
                          );
                          if (res != null && res.files.isNotEmpty) {
                            setModalState(
                                () => attachedPhoto = res.files.first);
                          }
                        },
                        icon: const Icon(Icons.add_a_photo, size: 16),
                        label: const Text('Pilih Foto Dokumentasi'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primary),
                          foregroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    if (_liveAiAnalysis != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLow,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Ekstraksi Semantik AI',
                                  style: AppTypography.labelSm
                                      .copyWith(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '${_liveAiAnalysis!['match_percentage']}% MATCH',
                                  style: AppTypography.labelSm.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: (_liveAiAnalysis!['extracted_skills']
                                          as List? ??
                                      [])
                                  .map<Widget>((s) => Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AppColors.surfaceHighest,
                                          borderRadius:
                                              BorderRadius.circular(9999),
                                        ),
                                        child: Text(
                                          '${s['name']} (${s['score']}%)',
                                          style: AppTypography.labelSm.copyWith(
                                              color: AppColors.onSurface),
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        final provider = Provider.of<JournalProvider>(context,
                            listen: false);
                        final messenger = ScaffoldMessenger.of(context);
                        Navigator.pop(ctx);
                        if (existing != null) {
                          final isRevision = existing.status.toUpperCase() == 'REVISION_REQUIRED' ||
                              (existing.revisionNotes != null && existing.revisionNotes!.isNotEmpty);
                          await provider.updateJournal(
                            journalId: existing.id,
                            workSummary: _textEditorController.text.trim(),
                            workflowStage: 4,
                            status: isRevision ? 'RESUBMITTED' : null,
                            photoFile: attachedPhoto,
                          );
                        } else {
                          await provider.createJournal(
                            workSummary: _textEditorController.text.trim(),
                            hoursSpent: 8.5,
                            workflowStage: 2,
                            photoFile: attachedPhoto,
                          );
                        }
                        if (mounted) {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Jurnal harian berhasil disinkronkan & dianalisis AI.'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        existing != null
                            ? 'Simpan Revisi & Ajukan Ulang'
                            : 'Kirim Jurnal Harian',
                        style: AppTypography.labelLg.copyWith(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showJournalDetail(JournalModel j) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;
    final role = (user?.role ?? '').toLowerCase();
    final isSupervisor = role == 'guru' || role == 'admin';

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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Day ${j.dayNumber} • Jurnal PKL',
                            style: AppTypography.headlineSm
                                .copyWith(fontWeight: FontWeight.bold)),
                        Text('${j.date} • ${j.hoursSpent} Jam',
                            style: const TextStyle(
                                fontSize: 11, color: Color(0xFF64748B))),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusBadgeColor(j.status).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(9999),
                        border:
                            Border.all(color: _getStatusBadgeColor(j.status)),
                      ),
                      child: Text(
                        _getStatusDisplay(j.status),
                        style: TextStyle(
                          color: _getStatusBadgeColor(j.status),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                if (j.photoUrl != null && j.photoUrl!.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        InkWell(
                          onTap: () => _showFullImageDialog(
                              context, ApiEndpoints.getImageUrl(j.photoUrl)),
                          child: Image.network(
                            ApiEndpoints.getImageUrl(j.photoUrl),
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
                  child: Text(j.workSummary,
                      style: AppTypography.bodyMd.copyWith(height: 1.5)),
                ),
                const SizedBox(height: 16),
                Text('Kompetensi Teknis Terdeteksi (${j.extractedSkills.length})',
                    style: AppTypography.labelSm
                        .copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: j.extractedSkills
                      .map((s) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceHigh,
                              borderRadius: BorderRadius.circular(9999),
                            ),
                            child: Text('${s.name} (${s.score}%)',
                                style: const TextStyle(fontSize: 11)),
                          ))
                      .toList(),
                ),
                if (j.revisionNotes != null &&
                    j.revisionNotes!.isNotEmpty) ...[
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
                              'Catatan Koreksi & Evaluasi:',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(j.revisionNotes!,
                            style: const TextStyle(fontSize: 11)),
                        if (j.reviewerName != null) ...[
                          const SizedBox(height: 4),
                          Text('Oleh: ${j.reviewerName}',
                              style: const TextStyle(
                                  fontSize: 10, color: Color(0xFF64748B))),
                        ],
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Text('Riwayat Perubahan Status (Audit Trail)',
                    style: AppTypography.labelSm
                        .copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                FutureBuilder<List<JournalHistoryModel>>(
                  future: Provider.of<JournalProvider>(context, listen: false)
                      .fetchJournalHistory(j.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                          child: Padding(
                        padding: EdgeInsets.all(12.0),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ));
                    }
                    final history = snapshot.data ?? [];
                    if (history.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 6.0),
                        child: Text(
                          'Belum ada riwayat review status tambahan.',
                          style:
                              TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                        ),
                      );
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: history.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (context, idx) {
                        final h = history[idx];
                        return Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLow,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.history,
                                  size: 16,
                                  color: _getStatusBadgeColor(h.newStatus)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${h.previousStatus ?? "AWAL"} ➔ ${h.newStatus}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11),
                                        ),
                                        Text(
                                          '${h.timestamp.hour.toString().padLeft(2, "0")}:${h.timestamp.minute.toString().padLeft(2, "0")}',
                                          style: const TextStyle(
                                              fontSize: 10,
                                              color: Color(0xFF64748B)),
                                        ),
                                      ],
                                    ),
                                    Text('Reviewer: ${h.reviewer}',
                                        style: const TextStyle(
                                            fontSize: 10,
                                            color: Color(0xFF64748B))),
                                    if (h.comment != null &&
                                        h.comment!.isNotEmpty)
                                      Text('Catatan: ${h.comment}',
                                          style: const TextStyle(
                                              fontSize: 10,
                                              fontStyle: FontStyle.italic)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 20),
                // Actions
                if (isSupervisor) ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _showReviewNotesPrompt(j, 'REVISION_REQUIRED');
                          },
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
                          onPressed: () {
                            Navigator.pop(ctx);
                            _showReviewNotesPrompt(j, 'REJECTED');
                          },
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
                          onPressed: () async {
                            final provider = Provider.of<JournalProvider>(
                                context,
                                listen: false);
                            Navigator.pop(ctx);
                            await provider.reviewJournal(
                                journalId: j.id,
                                status: 'APPROVED',
                                notes: 'Jurnal disetujui Pembimbing.');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F766E),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Setujui',
                              style: TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  if (j.status == 'REVISION_REQUIRED' ||
                      j.status == 'DRAFT') ...[
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _openJournalModal(j);
                      },
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Perbaiki & Ajukan Ulang Jurnal'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(44),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _confirmDeleteJournal(j);
                    },
                    icon: const Icon(Icons.delete_outline,
                        size: 16, color: AppColors.error),
                    label: const Text('Hapus Jurnal Harian',
                        style: TextStyle(color: AppColors.error)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error),
                      minimumSize: const Size.fromHeight(40),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDeleteJournal(JournalModel j) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Jurnal Harian'),
        content: Text(
            'Apakah Anda yakin ingin menghapus log jurnal Day ${j.dayNumber} (${j.date})? Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success = await Provider.of<JournalProvider>(context, listen: false)
          .deleteJournal(j.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Jurnal Day ${j.dayNumber} berhasil dihapus.'
                : 'Gagal menghapus jurnal.'),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
      }
    }
  }

  void _showReviewNotesPrompt(JournalModel j, String action) {
    final notesCtrl = TextEditingController();
    String? errorText;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            action == 'REJECTED' ? 'Tolak Jurnal Siswa' : 'Minta Revisi Jurnal',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Day ${j.dayNumber} • ${j.date}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 8),
              const Text('Tuliskan catatan arahan pembimbing (Wajib):',
                  style: TextStyle(fontSize: 11)),
              const SizedBox(height: 6),
              TextField(
                controller: notesCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText:
                      'Contoh: Harap jelaskan konfigurasi IP address yang diterapkan...',
                  border: const OutlineInputBorder(),
                  errorText: errorText,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                final noteText = notesCtrl.text.trim();
                if (action == 'REVISION_REQUIRED' && noteText.isEmpty) {
                  setDialogState(() {
                    errorText = 'Catatan alasan revisi wajib diisi!';
                  });
                  return;
                }
                Navigator.pop(ctx);
                final provider =
                    Provider.of<JournalProvider>(context, listen: false);
                await provider.reviewJournal(
                  journalId: j.id,
                  status: action,
                  notes: noteText,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    action == 'REJECTED' ? AppColors.error : AppColors.warning,
                foregroundColor: Colors.white,
              ),
              child: const Text('Kirim Arahan'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<JournalProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;
    final journal = provider.activeJournal ??
        (provider.journals.isNotEmpty ? provider.journals.first : null);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: RefreshIndicator(
        onRefresh: () => provider.fetchJournals(),
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (provider.journals.isEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLowest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.menu_book_outlined, size: 48, color: AppColors.primary),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Belum Ada Jurnal Kegiatan',
                        style: AppTypography.headlineSm.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Anda belum memiliki riwayat catatan jurnal kegiatan PKL. Mulai catat aktivitas harian praktik kerja lapangan Anda sekarang.',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () => _openJournalModal(),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Buat Jurnal Harian Baru'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Top Workflow & Metadata Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLowest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
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
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(9999),
                                ),
                                child: Text(
                                  'Day ${journal?.dayNumber ?? 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceHigh,
                                  borderRadius: BorderRadius.circular(9999),
                                ),
                                child: Text(
                                  user?.studentClass ?? 'SMKN 3 YOGYAKARTA',
                                  style: AppTypography.labelSm.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLow,
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.secondary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'AUTO-SAVED',
                                style: AppTypography.labelSm.copyWith(
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Jurnal Harian Praktik',
                      style: AppTypography.headlineSm
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${journal?.date ?? "-"} • ${journal?.hoursSpent ?? 0} Jam',
                      style: AppTypography.bodySm,
                    ),

                    const SizedBox(height: 14),

                    // Linear Workflow Tracker (Draft -> Submit -> AI Sync -> Review -> Approved)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildWorkflowLabel('1. Draft', isDone: true),
                            _buildWorkflowLabel('2. Submit', isDone: true),
                            _buildWorkflowLabel('3. AI Sync', isDone: true),
                            _buildWorkflowLabel('4. Review', isActive: true),
                            _buildWorkflowLabel('5. Approved', isPending: true),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _buildProgressBarSegment(isDone: true),
                            const SizedBox(width: 4),
                            _buildProgressBarSegment(isDone: true),
                            const SizedBox(width: 4),
                            _buildProgressBarSegment(isDone: true),
                            const SizedBox(width: 4),
                            _buildProgressBarSegment(isActive: true),
                            const SizedBox(width: 4),
                            _buildProgressBarSegment(isPending: true),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.pending,
                                    size: 14, color: AppColors.primary),
                                const SizedBox(width: 4),
                                Text(
                                  'Tahap Aktif: Validasi Lapangan',
                                  style: AppTypography.labelSm.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'SKKNI Level 2',
                              style: AppTypography.labelSm
                                  .copyWith(color: AppColors.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Revision Alert Box (if urgent revision)
              if (journal?.isUrgentRevision == true)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.warning),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.assignment_late,
                              color: AppColors.warning, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Catatan Koreksi Supervisor DUDI',
                            style: AppTypography.labelMd.copyWith(
                              color: AppColors.onWarningContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        journal?.revisionNotes ?? '',
                        style: AppTypography.bodySm
                            .copyWith(color: AppColors.onWarningContainer),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: () => _openJournalModal(journal),
                          icon: const Icon(Icons.edit, size: 14),
                          label: const Text('Edit Revisi Jurnal'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.warning,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(100, 32),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              if (journal?.isUrgentRevision == true) const SizedBox(height: 16),

              // AI Real-Time Skill Extractor Panel (Telemetry Hero)
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Gradient Neural Bar
                    Container(
                      height: 5,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(16)),
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.secondary,
                            AppColors.secondaryContainer
                          ],
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header with Confidence Pill
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceHigh,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.psychology,
                                        color: AppColors.primary, size: 20),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'SKAGATA AI Engine',
                                        style: AppTypography.labelMd.copyWith(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        'Semantic Skill Parsing',
                                        style: AppTypography.labelSm.copyWith(
                                          color: AppColors.onSurfaceVariant,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceLow,
                                  borderRadius: BorderRadius.circular(9999),
                                  border: Border.all(
                                      color: const Color(0xFFE2E8F0)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.auto_awesome,
                                        size: 14, color: AppColors.secondary),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${journal?.aiMatchPercentage ?? 0}% MATCH',
                                      style: AppTypography.labelSm.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          // Real-time Work Description Box
                          Text(
                            'Uraian Log Pekerjaan Teknis',
                            style: AppTypography.labelMd
                                .copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLow,
                              borderRadius: BorderRadius.circular(10),
                              border:
                                  Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Text(
                              journal?.workSummary ?? '-',
                              style: AppTypography.bodyMd.copyWith(height: 1.5),
                            ),
                          ),
                          if (journal?.photoUrl != null &&
                              journal!.photoUrl!.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            InkWell(
                              onTap: () => _showFullImageDialog(context,
                                  ApiEndpoints.getImageUrl(journal.photoUrl)),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                height: 130,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: const Color(0xFFE2E8F0)),
                                  image: DecorationImage(
                                    image: NetworkImage(
                                        ApiEndpoints.getImageUrl(
                                            journal.photoUrl)),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                alignment: Alignment.bottomRight,
                                padding: const EdgeInsets.all(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.zoom_in,
                                          color: Colors.white, size: 12),
                                      SizedBox(width: 4),
                                      Text('Foto Dokumentasi',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 9)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 14),

                          // Telemetry Metrics (2 columns)
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceLow,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('STANDAR KOMPETENSI',
                                          style: AppTypography.labelSm),
                                      const SizedBox(height: 2),
                                      Text(
                                        journal?.standardCompetency ?? '-',
                                        style: AppTypography.labelMd.copyWith(
                                            fontWeight: FontWeight.bold),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        journal?.competencyCategory ?? '-',
                                        style: AppTypography.bodySm.copyWith(
                                            color: AppColors.secondary,
                                            fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceLow,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('TINGKAT KOMPLEKSITAS',
                                          style: AppTypography.labelSm),
                                      const SizedBox(height: 2),
                                      Text(
                                        journal?.complexityLevel ?? '-',
                                        style: AppTypography.labelMd.copyWith(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        journal?.complexityTier ?? '-',
                                        style: AppTypography.bodySm
                                            .copyWith(fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          // Extracted Skills Badges
                          Text(
                            'EKSTRAKSI KOMPETENSI TEKNIS (${journal?.extractedSkills.length ?? 0})',
                            style: AppTypography.labelSm.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children:
                                (journal?.extractedSkills ?? []).map((skill) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceHigh,
                                  borderRadius: BorderRadius.circular(9999),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      skill.name,
                                      style: AppTypography.labelSm.copyWith(
                                        color: AppColors.onSurface,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${skill.score}%',
                                      style: AppTypography.labelSm.copyWith(
                                        color: AppColors.secondary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 14),

                          // Detected Tools & Hardware
                          Text(
                            'PERANGKAT & ALAT TERDETEKSI',
                            style: AppTypography.labelSm.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children:
                                (journal?.detectedTools ?? []).map((tool) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceLow,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: const Color(0xFFE2E8F0)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.router,
                                        size: 14, color: AppColors.primary),
                                    const SizedBox(width: 6),
                                    Text(
                                      tool,
                                      style: AppTypography.bodySm.copyWith(
                                        color: AppColors.onSurface,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Button to Create or Edit Journal
              ElevatedButton.icon(
                onPressed: () => _openJournalModal(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Buat Jurnal Harian Baru'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),

              const SizedBox(height: 24),
              _buildJournalListSection(provider),
              const SizedBox(height: 32),
            ],
          ],
        ),
        ),
      ),
    );
  }

  void _confirmClearAllJournals(BuildContext context, JournalProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.delete_sweep, color: AppColors.error),
            SizedBox(width: 8),
            Text('Hapus Semua Jurnal?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus seluruh (${provider.journals.length}) riwayat log jurnal kegiatan PKL? Tindakan ini bersifat permanen dan tidak dapat dibatalkan.',
          style: const TextStyle(fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await provider.clearAllJournals();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ok
                        ? 'Seluruh riwayat jurnal berhasil dibersihkan.'
                        : (provider.errorMessage ??
                            'Gagal menghapus jurnal.')),
                    backgroundColor:
                        ok ? AppColors.success : AppColors.error,
                  ),
                );
              }
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Ya, Hapus Semua'),
          ),
        ],
      ),
    );
  }

  Widget _buildJournalListSection(JournalProvider provider) {
    final list = provider.journals;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'RIWAYAT LOG JURNAL (${list.length})',
              style: AppTypography.labelSm.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            if (list.isNotEmpty)
              InkWell(
                onTap: () => _confirmClearAllJournals(context, provider),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    children: const [
                      Icon(Icons.delete_sweep,
                          size: 14, color: AppColors.error),
                      SizedBox(width: 4),
                      Text(
                        'Hapus Semua',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.error),
                      ),
                    ],
                  ),
                ),
              )
            else
              const Text(
                'Ketuk kartu untuk detail & audit',
                style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (list.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surfaceLowest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.menu_book, size: 36, color: AppColors.outline),
                  const SizedBox(height: 8),
                  const Text('Belum ada log jurnal harian.',
                      style:
                          TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, idx) {
              final j = list[idx];
              final hasPhoto = j.photoUrl != null && j.photoUrl!.isNotEmpty;
              return InkWell(
                onTap: () => _showJournalDetail(j),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLowest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: j.isUrgentRevision
                          ? AppColors.warning
                          : const Color(0xFFE2E8F0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Photo thumbnail if exists, else Day badge
                      if (hasPhoto)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            ApiEndpoints.getImageUrl(j.photoUrl),
                            width: 54,
                            height: 54,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 54,
                              height: 54,
                              color: AppColors.surfaceHigh,
                              child: const Icon(Icons.image, size: 24),
                            ),
                          ),
                        )
                      else
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLow,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('DAY',
                                  style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary)),
                              Text('${j.dayNumber}',
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary)),
                            ],
                          ),
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  j.date,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF475569)),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _getStatusBadgeColor(j.status)
                                        .withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    _getStatusDisplay(j.status),
                                    style: TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                      color: _getStatusBadgeColor(j.status),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              j.workSummary,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 11, height: 1.3),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Text(
                                  '${j.extractedSkills.length} Skills • ${j.aiMatchPercentage}% Match',
                                  style: const TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF0F766E),
                                      fontWeight: FontWeight.w600),
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      size: 16, color: Colors.redAccent),
                                  tooltip: 'Hapus Jurnal',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () => _confirmDeleteJournal(j),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.chevron_right,
                                    size: 16, color: Color(0xFF94A3B8)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildWorkflowLabel(String text,
      {bool isDone = false, bool isActive = false, bool isPending = false}) {
    Color color = AppColors.outline;
    if (isDone) color = AppColors.secondary;
    if (isActive) color = AppColors.primary;

    return Text(
      text,
      style: AppTypography.labelSm.copyWith(
        color: color,
        fontWeight: isActive || isDone ? FontWeight.bold : FontWeight.w500,
      ),
    );
  }

  Widget _buildProgressBarSegment(
      {bool isDone = false, bool isActive = false, bool isPending = false}) {
    Color color = Colors.transparent;
    if (isDone) color = AppColors.secondary;
    if (isActive) color = AppColors.primary;

    return Expanded(
      child: Container(
        height: 6,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(9999),
          border: isPending
              ? Border.all(color: const Color(0xFFCBD5E1), width: 1)
              : null,
        ),
      ),
    );
  }
}
