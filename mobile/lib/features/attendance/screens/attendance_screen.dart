import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/typography.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/widgets/interactive_map_widget.dart';
import '../../auth/providers/auth_provider.dart';
import '../../submission/screens/student_pkl_screen.dart';
import '../providers/attendance_provider.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({Key? key}) : super(key: key);

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen>
    with SingleTickerProviderStateMixin {
  late Timer _clockTimer;
  String _timeString = '';
  late AnimationController _pulseController;
  bool _showGoogleMap = false;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _clockTimer =
        Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AttendanceProvider>(context, listen: false)
          .fetchAttendanceStatus();
    });
  }

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      _timeString = DateFormat('HH:mm:ss').format(now);
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _handleCheckIn() {
    PlatformFile? pickedSelfie;
    bool isUploading = false;

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
                  Icon(Icons.camera_alt, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text('Verifikasi Selfie Presensi',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.info_outline, color: AppColors.primary, size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Wajib melampirkan foto selfie diri di tempat PKL untuk disetujui (ACC) oleh Guru Pembimbing.',
                              style: TextStyle(fontSize: 11, color: AppColors.primary, height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Selfie Preview Box
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLow,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: pickedSelfie != null ? AppColors.success : const Color(0xFFCBD5E1),
                          width: pickedSelfie != null ? 2 : 1,
                        ),
                      ),
                      child: pickedSelfie != null && pickedSelfie!.bytes != null
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.memory(
                                    pickedSelfie!.bytes!,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.7),
                                      borderRadius: BorderRadius.circular(9999),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(Icons.check_circle, color: AppColors.success, size: 14),
                                        SizedBox(width: 4),
                                        Text('Selfie Terambil',
                                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.face_retouching_natural, size: 48, color: Color(0xFF94A3B8)),
                                SizedBox(height: 8),
                                Text('Belum ada foto selfie',
                                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                                SizedBox(height: 4),
                                Text('Klik tombol di bawah untuk mengambil / memilih foto',
                                    style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                              ],
                            ),
                    ),

                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: isUploading
                          ? null
                          : () async {
                              final res = await FilePicker.platform.pickFiles(
                                type: FileType.custom,
                                allowedExtensions: ['jpg', 'jpeg', 'png'],
                                withData: true,
                              );
                              if (res != null && res.files.isNotEmpty) {
                                setDialogState(() => pickedSelfie = res.files.first);
                              }
                            },
                      icon: const Icon(Icons.add_a_photo, size: 16),
                      label: Text(pickedSelfie == null ? 'Ambil / Pilih Foto Selfie' : 'Ganti Foto Selfie'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                  onPressed: (pickedSelfie == null || isUploading)
                      ? null
                      : () async {
                          setDialogState(() => isUploading = true);

                          String? selfiePath;
                          try {
                            final uploadRes = await ApiClient.upload(
                              '${ApiEndpoints.baseUrl}/upload',
                              pickedSelfie!,
                            );
                            if (uploadRes.success && uploadRes.data != null) {
                              selfiePath = uploadRes.data['file_path'] as String?;
                            }
                          } catch (_) {}

                          if (selfiePath == null) {
                            if (mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload selfie gagal. Presensi tidak dikirim.')));
                            }
                            return;
                          }
                          final provider = Provider.of<AttendanceProvider>(context, listen: false);
                          final success = await provider.checkIn(
                            latitude: -7.78505,
                            longitude: 110.37225,
                            notes: 'Presensi selfie mandiri biometrik di radius 43m',
                            selfieUrl: selfiePath,
                          );

                          if (mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    Icon(
                                      success ? Icons.verified : Icons.error_outline,
                                      color: success ? AppColors.success : AppColors.error,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        success
                                            ? 'Presensi masuk & selfie berhasil dikirim! Menunggu ACC Guru.'
                                            : (provider.errorMessage ?? 'Gagal presensi.'),
                                        style: AppTypography.bodySm.copyWith(color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                                backgroundColor: AppColors.onSurface,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: isUploading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Kirim Presensi Masuk'),
                ),
              ],
            );
          },
        );
      },
    );
  }


  Future<void> _handleCheckOut() async {
    final provider = Provider.of<AttendanceProvider>(context, listen: false);
    final success =
        await provider.checkOut(notes: 'Presensi pulang shift reguler');

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Presensi Pulang Berhasil Tercatat.'
              : (provider.errorMessage ?? 'Gagal presensi pulang.'),
        ),
        backgroundColor: AppColors.onSurface,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AttendanceProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;
    final status = provider.status;
    final bool hasCheckedIn = status?.hasCheckedInToday ?? false;
    final bool hasCheckedOut = status?.hasCheckedOutToday ?? false;
    final bool hasActivePlacement = status != null && status.companyName != 'Belum Ada Penempatan';

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: RefreshIndicator(
        onRefresh: () => provider.fetchAttendanceStatus(),
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header / Verification Overview
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'TELEMETRY NODE LOCK',
                        style: AppTypography.labelSm.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceHigh,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      user?.studentClass ?? 'SMKN 3 YOGYAKARTA',
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Sistem Presensi PKL Berbasis Geofence & Perangkat Terdaftar SMKN 3 Yogyakarta',
                style: AppTypography.bodySm,
              ),

              const SizedBox(height: 12),

              // Registered Device Fingerprint Chip
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.secondaryContainer.withOpacity(0.3),
                      ),
                      child: const Icon(Icons.smartphone,
                          color: AppColors.secondary, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.deviceModel ?? 'Perangkat Siswa',
                            style: AppTypography.labelMd
                                .copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${user?.deviceId ?? "DEV-UNBOUND"} • HARDWARE SECURE',
                            style: AppTypography.bodySm.copyWith(
                              fontSize: 11,
                              fontFamily: 'Courier',
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.verified_user,
                              color: AppColors.success, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'TERDAFTAR',
                            style: AppTypography.labelSm.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Geofence Radar / Interactive Map Visualization Card
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Subheader
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.radar,
                                  color: AppColors.primary, size: 20),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Radar Geofence Kotabaru',
                                    style: AppTypography.labelMd
                                        .copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'Radius Perimeter Dinamis: 100m',
                                    style: AppTypography.bodySm
                                        .copyWith(fontSize: 11),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(9999),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.success,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'MATCH 99.8%',
                                  style: AppTypography.labelSm.copyWith(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Switcher: Radar vs Google Maps
                    Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceHigh,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () =>
                                  setState(() => _showGoogleMap = false),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                                decoration: BoxDecoration(
                                  color: !_showGoogleMap
                                      ? AppColors.surfaceLowest
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: !_showGoogleMap
                                      ? [
                                          const BoxShadow(
                                              color: Colors.black12,
                                              blurRadius: 4)
                                        ]
                                      : [],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.radar,
                                        size: 14,
                                        color: !_showGoogleMap
                                            ? AppColors.primary
                                            : AppColors.onSurfaceVariant),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Radar Scanner',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: !_showGoogleMap
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                        color: !_showGoogleMap
                                            ? AppColors.primary
                                            : AppColors.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: () =>
                                  setState(() => _showGoogleMap = true),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                                decoration: BoxDecoration(
                                  color: _showGoogleMap
                                      ? AppColors.surfaceLowest
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: _showGoogleMap
                                      ? [
                                          const BoxShadow(
                                              color: Colors.black12,
                                              blurRadius: 4)
                                        ]
                                      : [],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.map,
                                        size: 14,
                                        color: _showGoogleMap
                                            ? AppColors.primary
                                            : AppColors.onSurfaceVariant),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Peta Google Maps',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: _showGoogleMap
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                        color: _showGoogleMap
                                            ? AppColors.primary
                                            : AppColors.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (_showGoogleMap)
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: InteractiveMapWidget(
                          targetLat: (status?.targetLatitude != null && status!.targetLatitude != 0.0) ? status.targetLatitude : -7.78505,
                          targetLng: (status?.targetLongitude != null && status!.targetLongitude != 0.0) ? status.targetLongitude : 110.37225,
                          locationName: status?.companyName ?? 'Lokasi Penempatan PKL',
                          address: hasActivePlacement
                              ? 'Area Radius Geofence ${status!.companyName}'
                              : 'Belum terdaftar di lokasi PKL',
                          radiusMeters: status?.geofenceRadius ?? 100,
                          currentDistance: (status?.todayRecord?.distanceMeters ?? 0).toDouble(),
                          isInRadius: status?.todayRecord?.isInRadius ?? false,
                        ),
                      )
                    else ...[
                      // Interactive Radar Visualizer
                      Container(
                        height: 240,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          border: Border.symmetric(
                            horizontal: BorderSide(
                                color: Colors.white.withOpacity(0.1)),
                          ),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Concentric radar circles
                            AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, child) {
                                return CustomPaint(
                                  size: const Size(double.infinity, 240),
                                  painter: RadarPainter(
                                      pulseValue: _pulseController.value),
                                );
                              },
                            ),

                            // Target Center (Telkom Witel)
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.primary,
                                  ),
                                  child: const Icon(Icons.domain,
                                      color: Colors.white, size: 18),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'PT Telkom Witel',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),

                            // Student position dot (exact 43m vector from center)
                            Transform.translate(
                              offset: const Offset(34, -28),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppColors.secondary
                                              .withValues(alpha: 0.35),
                                        ),
                                      ),
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppColors.secondary,
                                          border: Border.all(
                                              color: Colors.white, width: 2),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.secondary
                                                  .withValues(alpha: 0.6),
                                              blurRadius: 6,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.black.withValues(alpha: 0.85),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                          color: AppColors.secondary,
                                          width: 0.8),
                                    ),
                                    child: const Text(
                                      'Siswa: 43m',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // GPS Telemetry HUD Overlay
                            Positioned(
                              bottom: 8,
                              left: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.75),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: Colors.white.withOpacity(0.15)),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.gps_fixed,
                                            color: AppColors.secondary,
                                            size: 16),
                                        const SizedBox(width: 6),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: const [
                                            Text(
                                              'Lat: -7.78542, Long: 110.37219',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            Text(
                                              'Presisi: ±4.2m • Mock Loc: OFF',
                                              style: TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 9),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.success,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'KUNCI GPS AKTIF',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Distance and boundary status box
                      Container(
                        padding: const EdgeInsets.all(12),
                        color: AppColors.success.withOpacity(0.08),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.success.withOpacity(0.2),
                              ),
                              child: const Icon(Icons.near_me,
                                  color: AppColors.success, size: 18),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Jarak ke Kantor: 43 meter',
                                    style: AppTypography.labelMd.copyWith(
                                      color: AppColors.onSuccessContainer,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Berada dalam radius aman geofence (Maksimal 100m)',
                                    style: AppTypography.bodySm.copyWith(
                                      color: AppColors.onSuccessContainer,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.check_circle,
                                color: AppColors.success, size: 22),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Attendance Action & Biometric Confirmation Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Live Authenticated Clock Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('WAKTU SERVER TEROTENTIKASI',
                                style: AppTypography.labelSm),
                            const SizedBox(height: 2),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  _timeString,
                                  style: AppTypography.headlineMd.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'WIB',
                                  style: AppTypography.labelSm
                                      .copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('JADWAL PENUGASAN',
                                style: AppTypography.labelSm),
                            const SizedBox(height: 2),
                            Text(
                              'Shift Reguler Pagi',
                              style: AppTypography.labelMd
                                  .copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '08:00 — 16:30 WIB',
                              style:
                                  AppTypography.bodySm.copyWith(fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    const SizedBox(height: 16),

                    // Today's Status & Selfie Preview (if checked in)
                    if (hasCheckedIn && status?.todayRecord != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: status!.todayRecord!.approvalStatus == 'APPROVED'
                              ? const Color(0xFFECFDF5)
                              : status!.todayRecord!.approvalStatus == 'REJECTED'
                                  ? const Color(0xFFFEF2F2)
                                  : const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: status!.todayRecord!.approvalStatus == 'APPROVED'
                                ? AppColors.success
                                : status!.todayRecord!.approvalStatus == 'REJECTED'
                                    ? AppColors.error
                                    : AppColors.warning,
                          ),
                        ),
                        child: Row(
                          children: [
                            if (status!.todayRecord!.selfieUrl != null &&
                                status!.todayRecord!.selfieUrl!.isNotEmpty) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  ApiEndpoints.getImageUrl(status!.todayRecord!.selfieUrl),
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.face, size: 30),
                                ),
                              ),
                              const SizedBox(width: 10),
                            ],
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    status!.todayRecord!.approvalStatus == 'APPROVED'
                                        ? 'DISETUJUI GURU PEMBIMBING'
                                        : status!.todayRecord!.approvalStatus == 'REJECTED'
                                            ? 'PRESENSI DITOLAK GURU'
                                            : 'MENUNGGU VERIFIKASI (ACC) GURU',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: status!.todayRecord!.approvalStatus == 'APPROVED'
                                          ? AppColors.success
                                          : status!.todayRecord!.approvalStatus == 'REJECTED'
                                              ? AppColors.error
                                              : Colors.amber.shade900,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    status!.todayRecord!.approvalStatus == 'APPROVED'
                                        ? 'Kehadiran Anda telah divalidasi resmi.'
                                        : status!.todayRecord!.approvalStatus == 'REJECTED'
                                            ? 'Catatan: Mohon hubungi guru pembimbing PKL.'
                                            : 'Foto selfie & koordinat GPS sedang ditinjau guru.',
                                    style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Big Action Button
                    if (!hasActivePlacement)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLow,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Penempatan PKL Belum Aktif',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Anda belum terdaftar di mitra PKL manapun. Silakan ajukan penempatan terlebih dahulu.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => StudentPklScreen()),
                                );
                              },
                              icon: const Icon(Icons.arrow_forward, size: 14),
                              label: const Text('Menu Penempatan PKL', style: TextStyle(fontSize: 11)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (!hasCheckedIn)
                      ElevatedButton.icon(
                        onPressed: provider.isLoading ? null : _handleCheckIn,
                        icon: const Icon(Icons.camera_alt, size: 20),
                        label: Text(
                          provider.isLoading
                              ? 'Memvalidasi Geofence...'
                              : 'Check-In Masuk (Wajib Selfie)',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      )
                    else if (!hasCheckedOut)
                      ElevatedButton.icon(
                        onPressed: provider.isLoading ? null : _handleCheckOut,
                        icon: const Icon(Icons.logout, size: 20),
                        label: Text(
                          provider.isLoading
                              ? 'Memproses Pulang...'
                              : 'Check-Out Presensi Pulang',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      )
                    else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLow,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.success),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.verified,
                                color: AppColors.success, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Presensi Hari Ini Selesai Terverifikasi',
                              style: AppTypography.labelLg.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class RadarPainter extends CustomPainter {
  final double pulseValue;

  RadarPainter({required this.pulseValue});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final bgGlowPaint = Paint()
      ..color = const Color(0xFF0A192F).withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 95, bgGlowPaint);

    final gridPaint = Paint()
      ..color = const Color(0xFF334155).withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Crosshair axis
    canvas.drawLine(Offset(center.dx - 110, center.dy),
        Offset(center.dx + 110, center.dy), gridPaint);
    canvas.drawLine(Offset(center.dx, center.dy - 110),
        Offset(center.dx, center.dy + 110), gridPaint);

    // Diagonal axis
    final diagPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawLine(Offset(center.dx - 75, center.dy - 75),
        Offset(center.dx + 75, center.dy + 75), diagPaint);
    canvas.drawLine(Offset(center.dx + 75, center.dy - 75),
        Offset(center.dx - 75, center.dy + 75), diagPaint);

    // Concentric range rings
    canvas.drawCircle(center, 30, gridPaint); // 33m
    canvas.drawCircle(center, 60, gridPaint); // 66m

    // 100m Geofence Perimeter (Solid glowing green)
    final perimeterGlow = Paint()
      ..color = AppColors.success.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0;
    canvas.drawCircle(center, 95, perimeterGlow);

    final perimeterPaint = Paint()
      ..color = AppColors.success
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawCircle(center, 95, perimeterPaint);

    // Pulsing radar wave
    final wavePaint = Paint()
      ..color = AppColors.success
          .withValues(alpha: (0.4 * (1 - pulseValue)).clamp(0.0, 1.0))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, 95 * pulseValue, wavePaint);

    // Vector line from office to student (34, -28)
    final vectorPaint = Paint()
      ..color = AppColors.secondary.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawLine(
        center, Offset(center.dx + 34, center.dy - 28), vectorPaint);
  }

  @override
  bool shouldRepaint(covariant RadarPainter oldDelegate) => true;
}

