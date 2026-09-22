import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/widgets/interactive_map_widget.dart';
import '../models/submission_model.dart';
import '../services/submission_service.dart';

class StudentPklScreen extends StatefulWidget {
  const StudentPklScreen({Key? key}) : super(key: key);

  @override
  State<StudentPklScreen> createState() => _StudentPklScreenState();
}

class _StudentPklScreenState extends State<StudentPklScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  List<PklSubmissionModel> _submissions = [];
  List<PklEvidenceModel> _evidences = [];
  List<Map<String, dynamic>> _companies = [];
  String _selectedEvidenceCategory = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadData();
  }


  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final subs = await SubmissionService.getSubmissions();
      final evs = await SubmissionService.getEvidences();
      final comps = await SubmissionService.getCompanies();
      if (mounted) {
        setState(() {
          _submissions = subs;
          _evidences = evs;
          _companies = comps;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  PklSubmissionModel? get _activeSubmission {
    if (_submissions.isEmpty) return null;
    return _submissions.first;
  }

  void _showUploadEvidenceDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String selectedCategory = 'daily_photo';
    PlatformFile? pickedFile;
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: const [
                  Icon(Icons.cloud_upload, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text('Unggah Dokumen Bukti PKL',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Judul Dokumen / Kegiatan:',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(
                        hintText:
                            'Contoh: Dokumentasi Splicing Kabel Fiber Optik',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('Kategori Dokumen:',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'daily_photo',
                            child: Text('Foto Harian Kegiatan')),
                        DropdownMenuItem(
                            value: 'certificate',
                            child: Text('Sertifikat / Piagam')),
                        DropdownMenuItem(
                            value: 'project_document',
                            child: Text('Dokumen Proyek / Laporan')),
                        DropdownMenuItem(
                            value: 'presentation',
                            child: Text('Materi Presentasi / PPT')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedCategory = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    const Text('Deskripsi Pelaksanaan (Opsional):',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: descCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        hintText:
                            'Jelaskan ringkasan isi bukti atau kendala teknis...',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text('Pilih Berkas (JPG, PNG, atau PDF):',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    if (pickedFile != null)
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLow,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Row(
                          children: [
                            if (pickedFile!.bytes != null &&
                                pickedFile!.extension?.toLowerCase() != 'pdf')
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.memory(pickedFile!.bytes!,
                                    width: 44, height: 44, fit: BoxFit.cover),
                              )
                            else
                              const Icon(Icons.picture_as_pdf,
                                  color: AppColors.error, size: 36),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(pickedFile!.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                  Text(
                                    '${(pickedFile!.size / 1024).toStringAsFixed(1)} KB',
                                    style: const TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close,
                                  color: AppColors.error, size: 18),
                              onPressed: () =>
                                  setDialogState(() => pickedFile = null),
                            ),
                          ],
                        ),
                      )
                    else
                      OutlinedButton.icon(
                        onPressed: () async {
                          final res = await FilePicker.platform.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
                            withData: true,
                          );
                          if (res != null && res.files.isNotEmpty) {
                            setDialogState(() => pickedFile = res.files.first);
                          }
                        },
                        icon: const Icon(Icons.attach_file, size: 16),
                        label: const Text('Pilih Berkas dari Perangkat'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primary),
                          foregroundColor: AppColors.primary,
                          minimumSize: const Size.fromHeight(40),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isUploading ? null : () => Navigator.pop(ctx),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: isUploading
                      ? null
                      : () async {
                          final title = titleCtrl.text.trim();
                          if (title.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Harap masukkan judul dokumen bukti.')),
                            );
                            return;
                          }
                          if (pickedFile == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Harap pilih berkas foto atau dokumen.')),
                            );
                            return;
                          }

                          setDialogState(() => isUploading = true);

                          // 1. Upload file to backend
                          final uploadRes = await ApiClient.upload(
                            '${ApiEndpoints.baseUrl}/upload',
                            pickedFile!,
                          );

                          if (!uploadRes.success || uploadRes.data == null) {
                            setDialogState(() => isUploading = false);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(uploadRes.error ??
                                      'Gagal mengunggah berkas.'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                            return;
                          }

                          final filePath =
                              uploadRes.data['file_path'] as String;

                          // 2. Create evidence record
                          final createRes =
                              await SubmissionService.uploadEvidence(
                            title: title,
                            category: selectedCategory,
                            description: descCtrl.text.trim(),
                            fileUrl: filePath,
                          );

                          if (mounted) {
                            Navigator.pop(ctx);
                            if (createRes.success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Dokumen bukti PKL berhasil diunggah & tersimpan.'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                              await _loadData();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(createRes.error ??
                                      'Gagal menyimpan bukti PKL.'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: isUploading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Unggah Sekarang'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showChangePklDialog() {
    final sub = _activeSubmission;
    int? targetCompId = _companies.isNotEmpty ? _companies.first['id'] : null;
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: const [
                  Icon(Icons.swap_horiz, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text('Permohonan Ganti PKL',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pilih industri tujuan dan jelaskan alasan kepindahan Anda kepada Guru Pembimbing:',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 14),
                    const Text('Tempat PKL Saat Ini:',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(top: 4, bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLow,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        sub?.companyName ??
                            'PT Telkom Indonesia (Witel Yogyakarta)',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const Text('Perusahaan Tujuan Baru:',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<int>(
                      value: targetCompId,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      items: _companies.map((c) {
                        return DropdownMenuItem<int>(
                          value: c['id'] as int,
                          child: Text(c['name'] ?? '',
                              style: const TextStyle(fontSize: 12)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setDialogState(() => targetCompId = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    const Text('Alasan Pengajuan Pindah:',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: reasonController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText:
                            'Contoh: Penyesuaian kompetensi jaringan core optical / domisili tempat tinggal...',
                        hintStyle: TextStyle(fontSize: 11),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Batal')),
                ElevatedButton(
                  onPressed: () async {
                    if (reasonController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Alasan kepindahan harus diisi.'),
                            backgroundColor: AppColors.error),
                      );
                      return;
                    }
                    if (targetCompId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Pilih perusahaan tujuan.'),
                            backgroundColor: AppColors.error),
                      );
                      return;
                    }

                    Navigator.pop(ctx);
                    setState(() => _isLoading = true);
                    final res = await SubmissionService.requestChange(
                      submissionId: sub?.id,
                      targetCompanyId: targetCompId!,
                      changeReason: reasonController.text.trim(),
                    );
                    await _loadData();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(res.success
                              ? 'Permohonan ganti tempat PKL berhasil diajukan!'
                              : (res.error ?? 'Gagal mengajukan.')),
                          backgroundColor:
                              res.success ? AppColors.success : AppColors.error,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white),
                  child: const Text('Kirim Pengajuan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showProposeCompanyDialog() {
    final nameCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final divisionCtrl = TextEditingController();
    final mentorCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: const [
                  Icon(Icons.add_business, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text('Usulkan Tempat PKL Baru',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ajukan tempat industri/perusahaan baru untuk diverifikasi dan disetujui Guru Pembimbing / Admin Hubin:',
                      style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 12),
                    const Text('Nama Perusahaan / Instansi *',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Contoh: PT Gama Techno Indonesia',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text('Alamat Lengkap Perusahaan *',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: addressCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        hintText: 'Jl. Kaliurang No. 5, Sleman, D.I. Yogyakarta',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text('Bidang Industri / Divisi Penempatan',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: divisionCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Contoh: Divisi Software & Networking',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text('Nama Pembimbing / PIC Lapangan',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: mentorCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Contoh: Bpk. Budi Santoso',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text('No. WhatsApp / Telepon PIC',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: phoneCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Contoh: 081234567890',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text('Catatan / Alasan Pengajuan',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: notesCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        hintText: 'Contoh: Sudah konfirmasi kesiapan magang dengan HRD...',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final name = nameCtrl.text.trim();
                          final addr = addressCtrl.text.trim();
                          if (name.isEmpty || addr.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Nama dan alamat perusahaan wajib diisi.'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                            return;
                          }
                          setDialogState(() => isSubmitting = true);
                          final res = await SubmissionService.proposeCompany(
                            name: name,
                            address: addr,
                            division: divisionCtrl.text.trim().isNotEmpty
                                ? divisionCtrl.text.trim()
                                : null,
                            mentorName: mentorCtrl.text.trim().isNotEmpty
                                ? mentorCtrl.text.trim()
                                : null,
                            mentorPhone: phoneCtrl.text.trim().isNotEmpty
                                ? phoneCtrl.text.trim()
                                : null,
                            notes: notesCtrl.text.trim().isNotEmpty
                                ? notesCtrl.text.trim()
                                : null,
                          );
                          if (mounted) {
                            Navigator.pop(ctx);
                            if (res.success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Usulan tempat PKL berhasil dikirim ke Guru & Admin Hubin! Menunggu ACC.'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                              _loadData();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(res.error ?? 'Gagal mengirim usulan.'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Kirim Usulan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteEvidence(PklEvidenceModel item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.delete_forever, color: AppColors.error),
            SizedBox(width: 8),
            Text('Hapus Bukti Portofolio',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus berkas bukti portofolio "${item.title}"?',
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
              final res = await SubmissionService.deleteEvidence(item.id);
              if (mounted) {
                if (res.success) {
                  setState(() {
                    _evidences.removeWhere((e) => e.id == item.id);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Berkas bukti portofolio berhasil dihapus.'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(res.error ?? 'Gagal menghapus bukti.'),
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

  void _showEvidencePreviewDialog(PklEvidenceModel item) {
    final hasImage = item.fileUrl.toLowerCase().endsWith('.jpg') ||
        item.fileUrl.toLowerCase().endsWith('.jpeg') ||
        item.fileUrl.toLowerCase().endsWith('.png');
    final fullUrl = ApiEndpoints.getImageUrl(item.fileUrl);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              hasImage ? Icons.image : Icons.description,
              color: AppColors.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                item.title,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(item.status).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Status: ${_getStatusLabel(item.status)}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(item.status),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (item.description != null && item.description!.isNotEmpty) ...[
                const Text('Keterangan:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 2),
                Text(item.description!, style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 12),
              ],
              if (item.reviewNotes != null && item.reviewNotes!.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.warningContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Catatan Verifikator Guru/Mentor:',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.onWarningContainer),
                      ),
                      const SizedBox(height: 4),
                      Text(item.reviewNotes!,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.onWarningContainer)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (hasImage && fullUrl.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    fullUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Container(
                      padding: const EdgeInsets.all(16),
                      color: AppColors.surfaceLow,
                      child: const Center(
                        child: Text('Foto tidak dapat dimuat dari server.',
                            style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ),
                    ),
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLow,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.attachment, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.fileUrl,
                          style: const TextStyle(fontSize: 11),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _confirmDeleteEvidence(item);
            },
            icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.error),
            label: const Text('Hapus Bukti', style: TextStyle(color: AppColors.error)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.error),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
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

  String _getStatusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
        return 'DISETUJUI RESMI';
      case 'CHANGE_REQUESTED':
        return 'PERMOHONAN PINDAH DIAJUKAN';
      case 'REVISION_REQUIRED':
        return 'PERLU REVISI';
      case 'REJECTED':
        return 'DITOLAK';
      case 'VERIFIED':
        return 'TERVERIFIKASI';
      default:
        return 'MENUNGGU VERIFIKASI';
    }
  }

  @override
  Widget build(BuildContext context) {
    final sub = _activeSubmission;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('STATUS & DOKUMEN PKL',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.onSurface,
        elevation: 0.5,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.onSurfaceVariant,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(
                icon: Icon(Icons.corporate_fare, size: 18),
                text: 'Penempatan PKL'),
            Tab(
                icon: Icon(Icons.folder_shared, size: 18),
                text: 'Bukti & Portofolio'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPlacementTab(sub),
                _buildEvidencesTab(),
              ],
            ),
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton.extended(
              onPressed: _showUploadEvidenceDialog,
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.upload_file, color: Colors.white),
              label: const Text('Unggah Bukti',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }

  Widget _buildPlacementTab(PklSubmissionModel? sub) {
    if (sub == null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
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
                      color: AppColors.primaryContainer.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.business_outlined, size: 48, color: AppColors.primary),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Belum Memiliki Tempat PKL Aktif',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Anda belum terdaftar di tempat PKL manapun. Silakan pilih dari daftar mitra industri yang tersedia atau usulkan tempat mitra baru.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showChangePklDialog,
                    icon: const Icon(Icons.apartment, size: 16),
                    label: const Text('Ajukan Penempatan',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showProposeCompanyDialog,
                    icon: const Icon(Icons.add_business, size: 16),
                    label: const Text('+ Usulkan Mitra Baru',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    final bool isApproved = sub.status == 'APPROVED';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Current Status Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getStatusColor(sub.status),
                  _getStatusColor(sub.status).withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _getStatusColor(sub.status).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Text(
                        _getStatusLabel(sub.status),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5),
                      ),
                    ),
                    const Icon(Icons.verified_user,
                        color: Colors.white, size: 20),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  sub.companyName ?? 'Mitra Industri PKL',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  sub.address ?? 'Alamat penempatan PKL',
                  style: const TextStyle(color: Color(0xFFF1F5F9), fontSize: 11),
                ),
                if (sub.supervisorNotes != null &&
                    sub.supervisorNotes!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline,
                            color: Colors.white, size: 14),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Catatan Guru: ${sub.supervisorNotes}',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Change PKL Request & Propose Company Trigger Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showChangePklDialog,
                  icon: const Icon(Icons.swap_horiz, size: 16),
                  label: const Text('Ajukan Pindah PKL',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showProposeCompanyDialog,
                  icon: const Icon(Icons.add_business, size: 16),
                  label: const Text('+ Usulkan Mitra Baru',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),

          if (isApproved) ...[
            const SizedBox(height: 20),

            // Google Maps & Interactive GPS Map
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('LOKASI PENEMPATAN & RADAR GPS',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurfaceVariant)),
                const Text('GEOFENCE 100M',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary)),
              ],
            ),
            const SizedBox(height: 10),
            InteractiveMapWidget(
              targetLat: -7.78505,
              targetLng: 110.37225,
              locationName: sub.companyName ?? 'Lokasi Mitra PKL',
              address: sub.address ?? 'Yogyakarta',
              radiusMeters: 100,
              currentDistance: 43,
              isInRadius: true,
            ),
          ],

          const SizedBox(height: 20),

          // Mentor & Supervisor Detail Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceLowest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PEMBIMBING & NARAHUBUNG',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurfaceVariant)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const CircleAvatar(
                        backgroundColor: Color(0xFFEFF6FF),
                        child: Icon(Icons.school,
                            color: AppColors.primary, size: 18)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Guru Pembimbing SMKN 3',
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold)),
                          const Text(
                              'SMKN 3 Yogyakarta',
                              style: TextStyle(
                                  fontSize: 10, color: Color(0xFF64748B))),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  children: [
                    const CircleAvatar(
                        backgroundColor: Color(0xFFFEF3C7),
                        child: Icon(Icons.engineering,
                            color: Colors.amber, size: 18)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Pembimbing Lapangan DUDI',
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold)),
                          Text('Mitra: ${sub.companyName ?? "-"}',
                              style: const TextStyle(
                                  fontSize: 10, color: Color(0xFF64748B))),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvidencesTab() {
    final filtered = _selectedEvidenceCategory == 'all'
        ? _evidences
        : _evidences
            .where((e) => e.category == _selectedEvidenceCategory)
            .toList();

    return Column(
      children: [
        // Action Bar
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  'Berkas Bukti Portofolio (${filtered.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _showUploadEvidenceDialog,
                icon: const Icon(Icons.cloud_upload_outlined, size: 16),
                label: const Text('Unggah Bukti'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle:
                      const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),

        // Category Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _buildCategoryChip('all', 'Semua Bukti (${_evidences.length})'),
              const SizedBox(width: 6),
              _buildCategoryChip('daily_photo', 'Foto Harian'),
              const SizedBox(width: 6),
              _buildCategoryChip('certificate', 'Sertifikat'),
              const SizedBox(width: 6),
              _buildCategoryChip('project_document', 'Dokumen Proyek'),
              const SizedBox(width: 6),
              _buildCategoryChip('presentation', 'Presentasi'),
            ],
          ),
        ),

        // Evidence List
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_open,
                          size: 48, color: AppColors.outline),
                      const SizedBox(height: 8),
                      Text('Belum ada dokumen bukti untuk kategori ini',
                          style: TextStyle(
                              color: AppColors.onSurfaceVariant, fontSize: 12)),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _showUploadEvidenceDialog,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Mulai Unggah Bukti Sekarang'),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    final hasImage = item.fileUrl.toLowerCase().endsWith('.jpg') ||
                        item.fileUrl.toLowerCase().endsWith('.jpeg') ||
                        item.fileUrl.toLowerCase().endsWith('.png');
                    final fullImgUrl = ApiEndpoints.getImageUrl(item.fileUrl);

                    return InkWell(
                      onTap: () => _showEvidencePreviewDialog(item),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLowest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 6,
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
                                    color: AppColors.surfaceHigh,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    item.category
                                        .toUpperCase()
                                        .replaceAll('_', ' '),
                                    style: const TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary),
                                  ),
                                ),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(item.status)
                                            .withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        _getStatusLabel(item.status),
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: _getStatusColor(item.status),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    InkWell(
                                      onTap: () => _confirmDeleteEvidence(item),
                                      borderRadius: BorderRadius.circular(4),
                                      child: const Padding(
                                        padding: EdgeInsets.all(2),
                                        child: Icon(Icons.delete_outline,
                                            size: 16, color: AppColors.error),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (hasImage && fullImgUrl.isNotEmpty) ...[
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      fullImgUrl,
                                      width: 52,
                                      height: 52,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 52,
                                        height: 52,
                                        color: AppColors.surfaceHigh,
                                        child: const Icon(Icons.image_not_supported,
                                            size: 20, color: Colors.grey),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                ] else ...[
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.description,
                                        color: AppColors.primary, size: 24),
                                  ),
                                  const SizedBox(width: 10),
                                ],
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      if (item.description != null &&
                                          item.description!.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          item.description!,
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: AppColors.onSurfaceVariant),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (item.reviewNotes != null &&
                                item.reviewNotes!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.warningContainer.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                    'Catatan Verifikator: ${item.reviewNotes}',
                                    style: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.onWarningContainer)),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Diupload: ${item.submittedAt.day}/${item.submittedAt.month}/${item.submittedAt.year}',
                                  style: const TextStyle(
                                      fontSize: 10, color: Color(0xFF94A3B8)),
                                ),
                                Row(
                                  children: const [
                                    Icon(Icons.touch_app,
                                        size: 13, color: AppColors.primary),
                                    SizedBox(width: 3),
                                    Text('Klik untuk detail',
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(String cat, String label) {
    final isSelected = _selectedEvidenceCategory == cat;
    return InkWell(
      onTap: () => setState(() => _selectedEvidenceCategory = cat),
      borderRadius: BorderRadius.circular(9999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(
              color: isSelected ? AppColors.primary : const Color(0xFFCBD5E1)),
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
