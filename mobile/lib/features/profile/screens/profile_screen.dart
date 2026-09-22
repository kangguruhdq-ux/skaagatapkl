import 'package:file_picker/file_picker.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/theme_settings.dart';
import '../../../shared/widgets/user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/storage/local_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../auth/providers/auth_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _hostController = TextEditingController();
  bool _pushNotifications = true;
  bool _gpsTracking = true;

  @override
  void initState() {
    super.initState();
    _hostController.text = ApiEndpoints.baseUrl.replaceAll('/api/v1', '');
  }

  @override
  void dispose() {
    _hostController.dispose();
    super.dispose();
  }

  void _showChangeHostDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Ubah Endpoint Backend API',
              style: AppTypography.headlineSm),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Koneksi server API PKL:',
                  style: AppTypography.bodySm),
              const SizedBox(height: 8),
              TextField(
                controller: _hostController,
                decoration: const InputDecoration(
                  hintText: 'http://127.0.0.1:8000',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final host = _hostController.text.trim();
                ApiEndpoints.setCustomHost(host);
                await LocalStorage.saveCustomHost(host);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'API URL diperbarui: ${ApiEndpoints.baseUrl}')),
                  );
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  void _showEditProfileDialog() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;

    final nameCtrl = TextEditingController(text: user?.fullName ?? '');
    final phoneCtrl = TextEditingController(text: user?.phone ?? '');
    final classCtrl = TextEditingController(text: user?.studentClass ?? '');
    final deptCtrl = TextEditingController(text: user?.department ?? '');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.edit_note, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('Ubah Data Profil', style: AppTypography.headlineSm),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Nama Lengkap', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Nomor WhatsApp / HP',
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: classCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Kelas / Rombel',
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: deptCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Program Keahlian',
                      border: OutlineInputBorder()),
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
                final success = await auth.updateProfile(
                  fullName: nameCtrl.text.trim(),
                  phone: phoneCtrl.text.trim(),
                  studentClass: classCtrl.text.trim(),
                  department: deptCtrl.text.trim(),
                );
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success
                          ? 'Profil berhasil diperbarui!'
                          : 'Gagal memperbarui profil.'),
                      backgroundColor:
                          success ? AppColors.success : AppColors.error,
                    ),
                  );
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showChangeAvatarDialog() async {
    final auth = context.read<AuthProvider>();
    try {
      final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['jpg', 'jpeg', 'png'],
          withData: true);
      if (result == null || !mounted) return;
      final file = result.files.single;
      if (file.size > 10 * 1024 * 1024 || file.bytes == null)
        throw Exception('Maksimum 10 MB.');
      bool busy = false;
      String? error;
      await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => StatefulBuilder(
              builder: (ctx, update) => AlertDialog(
                      title: const Text('Foto Profil'),
                      content:
                          Column(mainAxisSize: MainAxisSize.min, children: [
                        Image.memory(file.bytes!,
                            height: 180,
                            errorBuilder: (_, __, ___) =>
                                const Text('Gambar tidak valid')),
                        if (error != null) Text(error!),
                        if (busy) const LinearProgressIndicator(),
                      ]),
                      actions: [
                        TextButton(
                            onPressed: busy ? null : () => Navigator.pop(ctx),
                            child: const Text('Batal')),
                        FilledButton(
                            onPressed: busy
                                ? null
                                : () async {
                                    update(() {
                                      busy = true;
                                      error = null;
                                    });
                                    final response = await ApiClient.upload(
                                        '${ApiEndpoints.baseUrl}/upload/profile',
                                        file);
                                    if (response.success) {
                                      await auth.refreshProfile();
                                      if (ctx.mounted) Navigator.pop(ctx);
                                    } else if (ctx.mounted) {
                                      update(() {
                                        busy = false;
                                        error =
                                            response.error ?? 'Upload gagal.';
                                      });
                                    }
                                  },
                            child: Text(
                                busy ? 'Mengunggah...' : 'Unggah & Simpan')),
                      ])));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Foto gagal dipilih: $e')));
    }
  }

  void _showChangePasswordDialog() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final oldPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Ganti Kata Sandi Akun',
              style: AppTypography.headlineSm),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: oldPassCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                      labelText: 'Kata Sandi Saat Ini',
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: newPassCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                      labelText: 'Kata Sandi Baru (Min. 6 Karakter)',
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: confirmCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                      labelText: 'Konfirmasi Sandi Baru',
                      border: OutlineInputBorder()),
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
                if (newPassCtrl.text != confirmCtrl.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Konfirmasi kata sandi tidak cocok.'),
                        backgroundColor: AppColors.error),
                  );
                  return;
                }
                final success = await auth.changePassword(
                  oldPassword: oldPassCtrl.text,
                  newPassword: newPassCtrl.text,
                );
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success
                          ? 'Kata sandi berhasil diperbarui!'
                          : 'Gagal: Sandi lama tidak sesuai.'),
                      backgroundColor:
                          success ? AppColors.success : AppColors.error,
                    ),
                  );
                }
              },
              child: const Text('Perbarui'),
            ),
          ],
        );
      },
    );
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Konfirmasi Keluar', style: AppTypography.headlineSm),
        content: const Text(
            'Apakah Anda yakin ingin keluar dari akun SKAGATA PKL Intelligence?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await Provider.of<AuthProvider>(context, listen: false).logout();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('Anda telah berhasil keluar dari sistem PKL.'),
                    backgroundColor: AppColors.primary,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Ya, Keluar'),
          ),
        ],
      ),
    );
  }

  void _showChangeDeviceDialog() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;
    final deviceIdCtrl = TextEditingController(
        text: user?.deviceId ?? 'SKGT-DEV-${DateTime.now().millisecondsSinceEpoch % 10000}');
    final modelCtrl =
        TextEditingController(text: user?.deviceModel ?? 'Samsung Galaxy A54 5G');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.fingerprint, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Ganti Biometrik Perangkat',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                    'Perbarui identitas hardware/biometrik perangkat Anda untuk presensi kehadiran PKL.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                const SizedBox(height: 16),
                TextField(
                  controller: modelCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nama / Model Perangkat',
                    hintText: 'Contoh: Samsung Galaxy A54 5G',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: deviceIdCtrl,
                  decoration: InputDecoration(
                    labelText: 'ID Hardware / Fingerprint Biometrik',
                    hintText: 'Contoh: SKGT-DEV-8842',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.refresh, color: AppColors.primary),
                      tooltip: 'Generate ID Otomatis',
                      onPressed: () {
                        final randomCode =
                            'SKGT-DEV-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
                        deviceIdCtrl.text = randomCode;
                      },
                    ),
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
              onPressed: () async {
                final id = deviceIdCtrl.text.trim();
                final model = modelCtrl.text.trim();
                if (id.isEmpty) return;
                final success = await auth.updateDevice(
                    deviceId: id, deviceModel: model);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success
                          ? 'Biometrik perangkat berhasil diperbarui!'
                          : 'Gagal memperbarui biometrik.'),
                      backgroundColor:
                          success ? AppColors.success : AppColors.error,
                    ),
                  );
                }
              },
              child: const Text('Simpan Biometrik'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    final isStudent = (user?.role ?? '').toLowerCase() == 'siswa';
    final isTeacher = (user?.role ?? '').toLowerCase() == 'guru';

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: Navigator.canPop(context)
          ? AppBar(
              title: const Text('Profil Pengguna',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              centerTitle: false,
              elevation: 0,
              backgroundColor: AppColors.surfaceLowest,
              foregroundColor: AppColors.onSurface,
            )
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      const UserAvatar(radius: 40),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: InkWell(
                          onTap: _showChangeAvatarDialog,
                          borderRadius: BorderRadius.circular(9999),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary,
                            ),
                            child: const Icon(Icons.camera_alt,
                                size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.fullName ?? (isStudent ? 'Siswa PKL' : isTeacher ? 'Guru Pembimbing' : 'Administrator'),
                    style: AppTypography.headlineSm
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isStudent
                        ? '${user?.studentClass ?? "-"} • NISN: ${user?.username ?? "-"}'
                        : isTeacher
                            ? 'NIP: ${user?.username ?? "-"} • Guru Pembimbing'
                            : 'ID: ${user?.username ?? "-"} • Administrator Sistem PKL',
                    style: AppTypography.bodySm
                        .copyWith(color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceHigh,
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: Text(
                          user?.department ?? 'Teknik Komputer dan Jaringan',
                          style: AppTypography.labelSm.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.successContainer,
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: Text(
                          (user?.role ?? 'siswa').toUpperCase(),
                          style: AppTypography.labelSm.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _showEditProfileDialog,
                        icon: const Icon(Icons.edit, size: 14),
                        label: const Text('Ubah Profil'),
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: _showChangePasswordDialog,
                        icon: const Icon(Icons.lock_reset, size: 14),
                        label: const Text('Ganti Sandi'),
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Role Contextual / DUDI Placement Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isStudent
                            ? 'INFORMASI PENEMPATAN DUDI'
                            : isTeacher
                                ? 'INFORMASI PEMBIMBINGAN PKL'
                                : 'INFORMASI ADMINISTRASI HUBIN',
                        style: AppTypography.labelSm.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color:
                              AppColors.primaryContainer.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'AKTIF',
                          style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                            isStudent
                                ? Icons.domain
                                : isTeacher
                                    ? Icons.school
                                    : Icons.admin_panel_settings,
                            color: AppColors.primary,
                            size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isStudent
                                  ? 'PT Telkom Indonesia Tbk'
                                  : 'SMKN 3 Yogyakarta',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              isStudent
                                  ? 'Witel Yogyakarta • Kotabaru Gondokusuman'
                                  : isTeacher
                                      ? 'Unit Kerja: Jurusan Teknik Komputer & Jaringan'
                                      : 'BKK / Hubin SMKN 3 Yogyakarta',
                              style: const TextStyle(
                                  color: Color(0xFF64748B), fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isStudent
                            ? 'Mentor Lapangan:'
                            : isTeacher
                                ? 'Status Penugasan:'
                                : 'Akses Sistem:',
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF64748B)),
                      ),
                      Text(
                        isStudent
                            ? 'Pembimbing Lapangan DUDI'
                            : isTeacher
                                ? 'SK Kepala Sekolah Terverifikasi'
                                : 'Super Administrator',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isStudent
                            ? 'Guru Pembimbing:'
                            : isTeacher
                                ? 'Instansi:'
                                : 'Semester / Tahun:',
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF64748B)),
                      ),
                      Text(
                        isStudent
                            ? '-'
                            : isTeacher
                                ? 'SMKN 3 Yogyakarta'
                                : 'Gasal 2024/2025',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final token = await LocalStorage.getAccessToken();
                      if (token == null || token.isEmpty) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Sesi login tidak valid, silakan login kembali.'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                        return;
                      }
                      final studentParam =
                          isStudent && user != null ? '&student_id=${user.id}' : '';
                      final url =
                          '${ApiEndpoints.baseUrl}/reports/logbook/html?token=$token$studentParam';
                      final uri = Uri.parse(url);
                      try {
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri,
                              mode: LaunchMode.externalApplication);
                        } else {
                          await launchUrl(uri);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Gagal membuka berkas laporan: $e'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.picture_as_pdf, size: 16),
                    label: Text(isStudent
                        ? 'Unduh Logbook PKL Resmi (PDF)'
                        : 'Unduh Rekap Jurnal & Logbook (PDF)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E293B),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(38),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // System Preferences Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PREFERENSI SISTEM & NOTIFIKASI',
                    style: AppTypography.labelSm.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text('Notifikasi Presensi & Jurnal',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                    subtitle: const Text(
                        'Pengingat harian clock-in dan deadline jurnal',
                        style: TextStyle(fontSize: 11)),
                    value: _pushNotifications,
                    onChanged: (v) => setState(() => _pushNotifications = v),
                    contentPadding: EdgeInsets.zero,
                    activeColor: AppColors.primary,
                  ),
                  SwitchListTile(
                    title: const Text('Pelacakan Geofence Otomatis',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                    subtitle: const Text(
                        'Perbarui koordinat saat memasuki radius 100m kantor',
                        style: TextStyle(fontSize: 11)),
                    value: _gpsTracking,
                    onChanged: (v) => setState(() => _gpsTracking = v),
                    contentPadding: EdgeInsets.zero,
                    activeColor: AppColors.primary,
                  ),
                  SwitchListTile(
                    title: const Text('Mode Tampilan Gelap (Dark Mode)',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                    subtitle: const Text(
                        'Tema kontras tinggi untuk laboratorium NOC',
                        style: TextStyle(fontSize: 11)),
                    value: ThemeSettings.mode.value == ThemeMode.dark,
                    onChanged: (v) async {
                      await ThemeSettings.setDark(v);
                      if (mounted) setState(() {});
                    },
                    contentPadding: EdgeInsets.zero,
                    activeColor: AppColors.primary,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Device Security & Connectivity Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'KEAMANAN PERANGKAT & JARINGAN',
                    style: AppTypography.labelSm.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.shield_outlined,
                          color: AppColors.primary, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user?.deviceModel ?? 'Samsung Galaxy A54 5G',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 13)),
                            Text(
                                'Fingerprint: ${user?.deviceId ?? "SKGT-DEV-8842"}',
                                style: const TextStyle(
                                    color: Color(0xFF64748B), fontSize: 11)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('HARDWARE BOUND',
                            style: TextStyle(
                                color: AppColors.success,
                                fontSize: 9,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _showChangeDeviceDialog,
                      icon: const Icon(Icons.fingerprint, size: 16),
                      label: const Text('Ganti Biometrik Perangkat',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const Divider(height: 20),
                  Row(
                    children: [
                      const Icon(Icons.dns_outlined,
                          color: AppColors.secondary, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Endpoint Backend API',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 13)),
                            Text(ApiEndpoints.baseUrl,
                                style: const TextStyle(
                                    color: Color(0xFF64748B), fontSize: 11)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit,
                            size: 16, color: AppColors.primary),
                        onPressed: _showChangeHostDialog,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Logout Button
            ElevatedButton.icon(
              onPressed: _handleLogout,
              icon: const Icon(Icons.logout, color: AppColors.error, size: 18),
              label: const Text(
                'Keluar dari Akun',
                style: TextStyle(
                    color: AppColors.error, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    AppColors.errorContainer.withValues(alpha: 0.4),
                foregroundColor: AppColors.error,
                minimumSize: const Size.fromHeight(48),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFFFECDD3)),
                ),
              ),
            ),

            const SizedBox(height: 16),
            Center(
              child: Text(
                'SKAGATA PKL Intelligence Mobile • Build 2.4.0 (SMKN 3 Yogyakarta)',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
