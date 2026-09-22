import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../auth/providers/auth_provider.dart';
import '../../admin/screens/admin_dashboard_screen.dart';
import '../../teacher/screens/teacher_dashboard_screen.dart';
import '../../dashboard/screens/main_navigation_screen.dart';
import '../models/ticket_model.dart';
import '../services/ticket_service.dart';

class ReportHelpdeskScreen extends StatefulWidget {
  const ReportHelpdeskScreen({Key? key}) : super(key: key);

  @override
  State<ReportHelpdeskScreen> createState() => _ReportHelpdeskScreenState();
}

class _ReportHelpdeskScreenState extends State<ReportHelpdeskScreen> {
  bool _isLoading = false;
  List<ReportTicketModel> _tickets = [];
  String _selectedStatus = 'all';
  final TextEditingController _searchCtrl = TextEditingController();

  void _backToDashboard() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final role = auth.user?.role.toLowerCase() ?? 'siswa';
      Widget home;
      if (role == 'admin') {
        home = const AdminDashboardScreen();
      } else if (role == 'guru') {
        home = const TeacherDashboardScreen();
      } else {
        home = const MainNavigationScreen();
      }
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => home),
        (route) => false,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTickets() async {
    setState(() => _isLoading = true);
    try {
      final tickets = await TicketService.getTickets(
        status: _selectedStatus,
        query: _searchCtrl.text.trim(),
      );
      if (mounted) {
        setState(() {
          _tickets = tickets;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return AppColors.warning;
      case 'IN_PROGRESS':
        return AppColors.primary;
      case 'RESOLVED':
        return AppColors.success;
      case 'CLOSED':
        return const Color(0xFF64748B);
      default:
        return AppColors.primary;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'MENUNGGU';
      case 'IN_PROGRESS':
        return 'DIPROSES';
      case 'RESOLVED':
        return 'SELESAI';
      case 'CLOSED':
        return 'DITUTUP';
      default:
        return status;
    }
  }

  Color _getCategoryColor(String cat) {
    switch (cat.toUpperCase()) {
      case 'BUG':
        return AppColors.error;
      case 'PRESENSI':
        return Colors.purple;
      case 'PENEMPATAN':
        return Colors.teal;
      case 'JURNAL':
        return Colors.orange;
      default:
        return AppColors.primary;
    }
  }

  void _showImageDialog(BuildContext context, String imageUrl) {
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
                    child: Text('Gagal memuat gambar bukti.',
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

  // DIALOG BUAT TIKET BARU
  void _showCreateTicketDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String category = 'BUG';
    String priority = 'NORMAL';
    Uint8List? localImageBytes;
    String? localImageName;
    String? uploadedPhotoUrl;
    bool isUploading = false;
    String? uploadError;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: const [
                  Icon(Icons.report_problem_outlined, color: AppColors.error),
                  SizedBox(width: 8),
                  Text('Buat Laporan / Tiket Bug',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Laporkan kendala sistem, bug aplikasi, presensi GPS, atau bantuan penempatan ke Admin Hubin.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 14),

                      // Kategori & Prioritas
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: category,
                              decoration: const InputDecoration(
                                labelText: 'Kategori',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'BUG', child: Text('Bug Aplikasi')),
                                DropdownMenuItem(value: 'PRESENSI', child: Text('Presensi GPS')),
                                DropdownMenuItem(value: 'PENEMPATAN', child: Text('Penempatan PKL')),
                                DropdownMenuItem(value: 'JURNAL', child: Text('Jurnal Harian')),
                                DropdownMenuItem(value: 'LAINNYA', child: Text('Lainnya')),
                              ],
                              onChanged: (v) => setDialogState(() => category = v ?? 'BUG'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: priority,
                              decoration: const InputDecoration(
                                labelText: 'Prioritas',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'NORMAL', child: Text('Normal')),
                                DropdownMenuItem(value: 'TINGGI', child: Text('Penting')),
                                DropdownMenuItem(value: 'MENDESAK', child: Text('Mendesak')),
                              ],
                              onChanged: (v) => setDialogState(() => priority = v ?? 'NORMAL'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Judul
                      TextField(
                        controller: titleCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Judul Singkat Kendala',
                          hintText: 'Contoh: Foto jurnal tidak muncul saat upload...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Deskripsi
                      TextField(
                        controller: descCtrl,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Deskripsi Lengkap Kendala',
                          hintText: 'Jelaskan kronologi, langkah kejadian, atau pesan error yang muncul...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Lampiran Foto Bukti
                      const Text('Lampiran Foto Bukti (Opsional):',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      if (localImageBytes != null) ...[
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: uploadError != null
                                  ? AppColors.error
                                  : (isUploading ? AppColors.warning : AppColors.primary),
                              width: 1.5,
                            ),
                          ),
                          child: Stack(
                            alignment: Alignment.topRight,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(9),
                                child: Image.memory(
                                  localImageBytes!,
                                  height: 140,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              if (isUploading)
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(9),
                                    ),
                                    child: Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.5,
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            'Mengunggah foto ke server...',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              Positioned(
                                top: 6,
                                right: 6,
                                child: InkWell(
                                  onTap: () => setDialogState(() {
                                    localImageBytes = null;
                                    localImageName = null;
                                    uploadedPhotoUrl = null;
                                    uploadError = null;
                                  }),
                                  child: const CircleAvatar(
                                    radius: 13,
                                    backgroundColor: Colors.red,
                                    child: Icon(Icons.close, color: Colors.white, size: 15),
                                  ),
                                ),
                              ),
                              if (uploadedPhotoUrl != null && !isUploading)
                                Positioned(
                                  bottom: 6,
                                  left: 6,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.success,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(Icons.check, size: 12, color: Colors.white),
                                        SizedBox(width: 4),
                                        Text(
                                          'Foto Terunggah',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (uploadError != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            uploadError!,
                            style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                      ] else ...[
                        OutlinedButton.icon(
                          onPressed: isUploading
                              ? null
                              : () async {
                                  final res = await FilePicker.platform.pickFiles(
                                    type: FileType.image,
                                    withData: true,
                                  );
                                  if (res != null &&
                                      res.files.isNotEmpty &&
                                      res.files.first.bytes != null) {
                                    final file = res.files.first;
                                    setDialogState(() {
                                      localImageBytes = file.bytes;
                                      localImageName = file.name;
                                      isUploading = true;
                                      uploadError = null;
                                    });

                                    final url = await TicketService.uploadTicketPhoto(
                                        file.bytes!, file.name);
                                    setDialogState(() {
                                      isUploading = false;
                                      if (url != null) {
                                        uploadedPhotoUrl = url;
                                      } else {
                                        uploadError =
                                            'Gagal mengunggah foto ke server. Pastikan koneksi atau format file valid (JPG/PNG/WEBP).';
                                      }
                                    });
                                  }
                                },
                          icon: isUploading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.add_a_photo_outlined, size: 18),
                          label: Text(
                              isUploading ? 'Mengunggah Foto...' : 'Unggah Foto Bukti Bug / Error (JPG/PNG/WEBP)'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (isUploading) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Foto sedang diunggah ke server, mohon tunggu sebentar...')),
                      );
                      return;
                    }
                    if (localImageBytes != null && uploadedPhotoUrl == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Unggah foto belum berhasil. Hapus foto atau coba unggah ulang.'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                      return;
                    }

                    final title = titleCtrl.text.trim();
                    final desc = descCtrl.text.trim();
                    if (title.isEmpty || desc.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Judul dan deskripsi kendala wajib diisi!')),
                      );
                      return;
                    }

                    Navigator.pop(ctx);
                    final res = await TicketService.createTicket(
                      title: title,
                      description: desc,
                      category: category,
                      priority: priority,
                      photoUrl: uploadedPhotoUrl,
                    );

                    if (mounted) {
                      if (res.success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Tiket laporan berhasil dibuat! Admin akan segera menindaklanjuti.'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                        _loadTickets();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(res.error ?? 'Gagal membuat tiket laporan.'),
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
                  child: const Text('Kirim Laporan'),
                ),
              ],
            );
          },
        );
      },
    );
  }


  // DIALOG DETAIL TIKET & CHAT ROOM
  void _openTicketChat(ReportTicketModel ticket) async {
    // Fetch fresh detail with messages
    final fresh = await TicketService.getTicketDetail(ticket.id) ?? ticket;
    if (!mounted) return;

    final msgCtrl = TextEditingController();
    Uint8List? replyBytes;
    String? msgPhotoUrl;
    bool isUploadingMsgPhoto = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                top: 16,
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.9,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceLowest,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header bar
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
                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _getCategoryColor(fresh.category).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    fresh.category,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: _getCategoryColor(fresh.category),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  fresh.ticketNumber,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              fresh.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(fresh.status).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: _getStatusColor(fresh.status)),
                        ),
                        child: Text(
                          _getStatusLabel(fresh.status),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(fresh.status),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pelapor: ${fresh.userName} (${fresh.userRole})${fresh.userClass != null ? " • ${fresh.userClass}" : ""}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                  const Divider(height: 20),

                  // Original Issue Description & Photo
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLow,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Uraian Kendala Awal:',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(fresh.description, style: const TextStyle(fontSize: 12)),
                        if (fresh.photoUrl != null && fresh.photoUrl!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: InkWell(
                              onTap: () => _showImageDialog(
                                  context, ApiEndpoints.getImageUrl(fresh.photoUrl)),
                              child: Image.network(
                                ApiEndpoints.getImageUrl(fresh.photoUrl),
                                height: 110,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Text('Gagal memuat foto.'),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),
                  const Text('Percakapan / Tindak Lanjut Admin:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),

                  // Messages list
                  Expanded(
                    child: fresh.messages.isEmpty
                        ? const Center(
                            child: Text(
                              'Belum ada pesan tindak lanjut. Kirim pesan di bawah untuk berkomunikasi dengan Admin.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                            ),
                          )
                        : ListView.separated(
                            itemCount: fresh.messages.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, idx) {
                              final msg = fresh.messages[idx];
                              final isMe = msg.senderName == fresh.userName ||
                                  msg.senderRole.toUpperCase() != 'ADMIN';
                              return Align(
                                alignment:
                                    isMe ? Alignment.centerRight : Alignment.centerLeft,
                                child: Container(
                                  constraints: BoxConstraints(
                                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                                  ),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isMe
                                        ? const Color(0xFFEFF6FF)
                                        : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isMe
                                          ? const Color(0xFFBFDBFE)
                                          : const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            msg.senderName,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: isMe
                                                  ? AppColors.primary
                                                  : const Color(0xFF0F766E),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '(${msg.senderRole})',
                                            style: const TextStyle(
                                                fontSize: 9, color: Color(0xFF94A3B8)),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(msg.message, style: const TextStyle(fontSize: 12)),
                                      if (msg.photoUrl != null && msg.photoUrl!.isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(6),
                                          child: InkWell(
                                            onTap: () => _showImageDialog(context,
                                                ApiEndpoints.getImageUrl(msg.photoUrl)),
                                            child: Image.network(
                                              ApiEndpoints.getImageUrl(msg.photoUrl),
                                              height: 100,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 4),
                                      Text(
                                        '${msg.createdAt.toLocal().toString().split(".")[0].substring(0, 16)}',
                                        style: const TextStyle(
                                            fontSize: 9, color: Color(0xFF94A3B8)),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),

                  const SizedBox(height: 8),

                  // Thumbnail if attached in reply
                  if (replyBytes != null) ...[
                    Row(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.memory(
                                replyBytes!,
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                              ),
                            ),
                            if (isUploadingMsgPhoto)
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Center(
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isUploadingMsgPhoto
                                ? 'Mengunggah foto lampiran...'
                                : (msgPhotoUrl != null
                                    ? 'Foto siap dikirim'
                                    : 'Gagal mengunggah foto'),
                            style: TextStyle(
                              fontSize: 11,
                              color: isUploadingMsgPhoto
                                  ? AppColors.warning
                                  : (msgPhotoUrl != null
                                      ? AppColors.success
                                      : AppColors.error),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18, color: Colors.red),
                          onPressed: () => setSheetState(() {
                            replyBytes = null;
                            msgPhotoUrl = null;
                            isUploadingMsgPhoto = false;
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],

                  // Input box
                  Row(
                    children: [
                      IconButton(
                        icon: isUploadingMsgPhoto
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.attach_file, color: Color(0xFF64748B)),
                        tooltip: 'Lampirkan Foto',
                        onPressed: isUploadingMsgPhoto
                            ? null
                            : () async {
                                final res = await FilePicker.platform.pickFiles(
                                  type: FileType.image,
                                  withData: true,
                                );
                                if (res != null &&
                                    res.files.isNotEmpty &&
                                    res.files.first.bytes != null) {
                                  final file = res.files.first;
                                  setSheetState(() {
                                    replyBytes = file.bytes;
                                    isUploadingMsgPhoto = true;
                                    msgPhotoUrl = null;
                                  });
                                  final url = await TicketService.uploadTicketPhoto(
                                      file.bytes!, file.name);
                                  setSheetState(() {
                                    msgPhotoUrl = url;
                                    isUploadingMsgPhoto = false;
                                  });
                                  if (url == null && mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Gagal mengunggah foto lampiran. Pastikan format valid (JPG/PNG/WEBP).'),
                                        backgroundColor: AppColors.error,
                                      ),
                                    );
                                  }
                                }
                              },
                      ),
                      Expanded(
                        child: TextField(
                          controller: msgCtrl,
                          decoration: InputDecoration(
                            hintText: 'Tulis pesan atau tanggapan...',
                            hintStyle: const TextStyle(fontSize: 12),
                            isDense: true,
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.send, color: AppColors.primary),
                        onPressed: () async {
                          if (isUploadingMsgPhoto) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Foto sedang diunggah, mohon tunggu sebentar...')),
                            );
                            return;
                          }
                          final text = msgCtrl.text.trim();
                          if (text.isEmpty && msgPhotoUrl == null) return;
                          msgCtrl.clear();
                          final pUrl = msgPhotoUrl;
                          setSheetState(() {
                            replyBytes = null;
                            msgPhotoUrl = null;
                          });

                          final res = await TicketService.sendMessage(
                            ticketId: fresh.id,
                            message: text,
                            photoUrl: pUrl,
                          );

                          if (res.success) {
                            final updated = await TicketService.getTicketDetail(fresh.id);
                            if (updated != null) {
                              setSheetState(() {
                                fresh.messages.clear();
                                fresh.messages.addAll(updated.messages);
                              });
                            }
                            _loadTickets();
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDeleteTicket(ReportTicketModel ticket) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Tiket Laporan'),
        content: Text(
            'Apakah Anda yakin ingin menghapus tiket ${ticket.ticketNumber} ("${ticket.title}")?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final removedIndex = _tickets.indexWhere((t) => t.id == ticket.id);
              if (removedIndex != -1) {
                setState(() => _tickets.removeAt(removedIndex));
              }
              final res = await TicketService.deleteTicket(ticket.id);
              if (mounted) {
                if (res.success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tiket laporan berhasil dihapus.'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                } else {
                  if (removedIndex != -1) {
                    setState(() => _tickets.insert(removedIndex, ticket));
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(res.error ?? 'Gagal menghapus tiket.'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Hapus Sekarang'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          tooltip: 'Kembali ke Dashboard',
          onPressed: _backToDashboard,
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.support_agent, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              'Pusat Bantuan & Laporan',
              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Segarkan Tiket',
            onPressed: _loadTickets,
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateTicketDialog,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Laporkan Bug / Kendala',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Top Navigation Banner - Kembali ke Dashboard
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF1E293B),
              border: Border(bottom: BorderSide(color: Color(0xFF334155))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: _backToDashboard,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.35),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.dashboard_outlined, color: Colors.white, size: 15),
                        SizedBox(width: 6),
                        Text(
                          'Kembali ke Dashboard',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.help_outline, size: 13, color: Color(0xFF94A3B8)),
                      SizedBox(width: 4),
                      Text(
                        'Helpdesk Tiket',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Filter Chips & Search Bar
          Container(
            color: AppColors.surfaceLowest,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  onSubmitted: (_) => _loadTickets(),
                  decoration: InputDecoration(
                    hintText: 'Cari tiket laporan atau kata kunci...',
                    hintStyle: const TextStyle(fontSize: 12),
                    prefixIcon: const Icon(Icons.search, size: 18),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('all', 'Semua (${_tickets.length})'),
                      const SizedBox(width: 6),
                      _buildFilterChip('PENDING', 'Menunggu'),
                      const SizedBox(width: 6),
                      _buildFilterChip('IN_PROGRESS', 'Diproses'),
                      const SizedBox(width: 6),
                      _buildFilterChip('RESOLVED', 'Selesai'),
                      const SizedBox(width: 6),
                      _buildFilterChip('CLOSED', 'Ditutup'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // List of Tickets
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _tickets.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_outline,
                                size: 48, color: Color(0xFFCBD5E1)),
                            const SizedBox(height: 8),
                            const Text('Belum ada riwayat tiket laporan kendala.',
                                style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                            const SizedBox(height: 4),
                            const Text('Laporkan masalah jika menemukan bug atau kendala sistem.',
                                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _tickets.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final ticket = _tickets[index];
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLowest,
                              borderRadius: BorderRadius.circular(12),
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
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: _getCategoryColor(ticket.category)
                                                .withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            ticket.category,
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              color: _getCategoryColor(ticket.category),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          ticket.ticketNumber,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(ticket.status).withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(4),
                                        border:
                                            Border.all(color: _getStatusColor(ticket.status)),
                                      ),
                                      child: Text(
                                        _getStatusLabel(ticket.status),
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: _getStatusColor(ticket.status),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  ticket.title,
                                  style: const TextStyle(
                                      fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  ticket.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 11, color: Color(0xFF475569)),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${ticket.createdAt.toLocal().toString().split(" ")[0]} • ${ticket.messages.length} balasan',
                                      style: const TextStyle(
                                          fontSize: 10, color: Color(0xFF94A3B8)),
                                    ),
                                    Row(
                                      children: [
                                        TextButton.icon(
                                          onPressed: () => _openTicketChat(ticket),
                                          icon: const Icon(Icons.chat_outlined, size: 14),
                                          label: const Text('Buka Chat & Solusi',
                                              style: TextStyle(fontSize: 11)),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline,
                                              color: AppColors.error, size: 18),
                                          tooltip: 'Hapus Tiket',
                                          onPressed: () => _confirmDeleteTicket(ticket),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedStatus == key;
    return InkWell(
      onTap: () {
        setState(() => _selectedStatus = key);
        _loadTickets();
      },
      borderRadius: BorderRadius.circular(9999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFCBD5E1),
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
