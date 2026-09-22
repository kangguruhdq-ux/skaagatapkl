import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/typography.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../../submission/screens/student_pkl_screen.dart';
import '../../reports/screens/report_helpdesk_screen.dart';
import '../../../shared/widgets/user_avatar.dart';


class DashboardScreen extends StatefulWidget {
  final Function(int)? onNavigateTab;

  const DashboardScreen({Key? key, this.onNavigateTab}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DashboardProvider>(context, listen: false)
          .fetchDashboardData();
    });
  }

  void _showFeedback(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.verified,
                color: AppColors.secondaryContainer, size: 20),
            const SizedBox(width: 8),
            Expanded(
                child: Text(msg,
                    style: AppTypography.bodySm.copyWith(color: Colors.white))),
          ],
        ),
        backgroundColor: AppColors.onSurface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DashboardProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    if (provider.isLoading && provider.dashboardData == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    final data = provider.dashboardData;
    final displayName = user?.fullName ?? data?.studentName ?? 'Siswa PKL';
    final displayClass = user?.studentClass ?? data?.studentClass ?? '-';
    final displayNisn = user?.username ?? data?.nisn ?? '-';

    return RefreshIndicator(
      onRefresh: () => provider.fetchDashboardData(),
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Student Identity Card (Institutional Telemetry)
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
                children: [
                  Row(
                    children: [
                      Stack(
                        children: [
                          UserAvatar(
                            radius: 25,
                            avatarUrl: user?.avatarUrl,
                            name: displayName,
                          ),

                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.success,
                                border:
                                    Border.all(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: AppTypography.headlineSm
                                  .copyWith(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '$displayClass • NISN: $displayNisn',
                              style: AppTypography.bodySm
                                  .copyWith(color: AppColors.onSurfaceVariant),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceHigh,
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.sensors,
                                size: 14, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text(
                              'ONLINE',
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

                  const SizedBox(height: 16),

                  // Live Placement Details Panel
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (_, animation, __) =>
                              const StudentPklScreen(),
                          transitionsBuilder: (_, animation, __, child) =>
                              FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                      begin: const Offset(0.05, 0),
                                      end: Offset.zero)
                                  .animate(
                                CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeOutCubic),
                              ),
                              child: child,
                            ),
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: data?.placement == null
                        ? Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLow,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryContainer.withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.domain_disabled, color: AppColors.primary, size: 20),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Belum Ada Penempatan PKL',
                                            style: AppTypography.labelLg.copyWith(fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                            'Anda belum memiliki penempatan aktif',
                                            style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant, fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => const StudentPklScreen()),
                                      );
                                    },
                                    icon: const Icon(Icons.arrow_forward, size: 14),
                                    label: const Text('Buka Menu Penempatan PKL', style: TextStyle(fontSize: 12)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLow,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.domain,
                                            size: 18, color: AppColors.primary),
                                        const SizedBox(width: 6),
                                        Text(
                                          data!.placement!.companyName,
                                          style: AppTypography.labelLg
                                              .copyWith(fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.successContainer,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'ACTIVE PLACEMENT',
                                        style: AppTypography.labelSm.copyWith(
                                          color: AppColors.onSuccessContainer,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 9,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  data.placement!.division.isNotEmpty
                                      ? data.placement!.division
                                      : data.placement!.address,
                                  style: AppTypography.bodySm
                                      .copyWith(color: AppColors.onSurfaceVariant),
                                ),
                                const SizedBox(height: 10),
                                // Mentor and supervisor mini indicators
                                Row(
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Icon(Icons.engineering_outlined,
                                              size: 16, color: AppColors.outline),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              'Ind: ${data.placement!.mentorName}',
                                              style: AppTypography.bodySm,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Icon(Icons.school_outlined,
                                              size: 16, color: AppColors.outline),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              'Sek: ${data.placement!.supervisorName}',
                                              style: AppTypography.bodySm,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // Progress Tracker Rail
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Periode: ${data.placement!.periodString}',
                                      style:
                                          AppTypography.bodySm.copyWith(fontSize: 11),
                                    ),
                                    Text(
                                      'Minggu ke-${data.placement!.currentWeek} / ${data.placement!.totalWeeks} (${data.placement!.progressPct}%)',
                                      style: AppTypography.labelSm.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(9999),
                                  child: LinearProgressIndicator(
                                    value: data.placement!.totalWeeks > 0
                                        ? (data.placement!.progressPct) / 100.0
                                        : 0.0,
                                    backgroundColor: const Color(0xFFDCE9FF),
                                    valueColor: const AlwaysStoppedAnimation<Color>(
                                        AppColors.primary),
                                    minHeight: 8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Critical Revision Alert Banner (Ir. Bambang notes)
            if (data?.urgentAlert != null)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.warningContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.warning.withOpacity(0.4)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.warningContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.assignment_late,
                          color: AppColors.onWarningContainer, size: 22),
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
                                data!.urgentAlert!.title,
                                style: AppTypography.labelLg.copyWith(
                                  color: AppColors.onWarningContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.warning,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  data.urgentAlert!.badgeLabel,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            data.urgentAlert!.notes,
                            style: AppTypography.bodySm
                                .copyWith(color: AppColors.onWarningContainer),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () {
                              if (widget.onNavigateTab != null) {
                                widget
                                    .onNavigateTab!(2); // Switch to Journal tab
                              }
                            },
                            icon: const Icon(Icons.arrow_forward, size: 14),
                            label: Text(data.urgentAlert!.actionLabel),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.warning,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(110, 34),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Quick Telemetry Strip (3 cards)
            Row(
              children: [
                Expanded(
                  child: _buildTelemetryCard(
                    title: 'Presensi Total',
                    metric:
                        '${data?.telemetryStrip.attendanceRatePct ?? 0.0}%',
                    metricColor: AppColors.primary,
                    subtitle:
                        '${data?.telemetryStrip.totalPresentDays ?? 0} Hari Hadir',
                    subColor: AppColors.success,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTelemetryCard(
                    title: 'Log Presensi',
                    metric: '${data?.telemetryStrip.permittedDays ?? 0}',
                    metricColor: AppColors.onSurface,
                    subtitle: 'Hari Izin (${data?.telemetryStrip.alphaDays ?? 0} Alpa)',
                    subColor: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTelemetryCard(
                    title: 'Geofence GPS',
                    metric:
                        '${data?.telemetryStrip.lastGpsDistanceMeters.toInt() ?? 0}m',
                    metricColor: (data?.telemetryStrip.isInGeofence ?? false) ? AppColors.success : AppColors.outline,
                    subtitle: (data?.telemetryStrip.isInGeofence ?? false) ? 'In-Radius Aman' : 'Di Luar Radius',
                    subColor: (data?.telemetryStrip.isInGeofence ?? false) ? AppColors.success : AppColors.outline,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Field Action Modules (Modul Lapangan)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Modul Lapangan',
                  style: AppTypography.headlineSm
                      .copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  'AKSI CEPAT',
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.15,
              children: [
                // 1. Check-In GPS
                _buildActionModule(
                  icon: Icons.where_to_vote,
                  iconBg: const Color(0xFFECFDF5),
                  iconColor: AppColors.success,
                  title: 'Check-In GPS',
                  subtitle: 'Hadir 07:42 WIB',
                  meta: 'Radius presisi: 38m',
                  onTap: () {
                    if (widget.onNavigateTab != null) widget.onNavigateTab!(1);
                  },
                ),

                // 2. Buat Jurnal Baru
                _buildActionModule(
                  icon: Icons.post_add,
                  iconBg: const Color(0xFFEFF4FF),
                  iconColor: AppColors.primary,
                  title: 'Jurnal Harian',
                  subtitle: 'Dokumentasi Log',
                  meta: 'Lanjutkan draf switch',
                  badge: '1 Draft',
                  onTap: () {
                    if (widget.onNavigateTab != null) widget.onNavigateTab!(2);
                  },
                ),

                // 3. Status & Berkas PKL
                _buildActionModule(
                  icon: Icons.assignment_outlined,
                  iconBg: AppColors.surfaceLow,
                  iconColor: AppColors.primary,
                  title: 'Status PKL',
                  subtitle: 'Penempatan & Pindah',
                  meta: 'DUDI Terverifikasi',
                  badge: 'Aktif',
                  onTap: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (_, animation, __) =>
                            const StudentPklScreen(),
                        transitionsBuilder: (_, animation, __, child) =>
                            FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                                    begin: const Offset(0.05, 0),
                                    end: Offset.zero)
                                .animate(
                              CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeOutCubic),
                            ),
                            child: child,
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // 4. Unggah Bukti
                _buildActionModule(
                  icon: Icons.cloud_upload_outlined,
                  iconBg: AppColors.surfaceLow,
                  iconColor: AppColors.onSurface,
                  title: 'Unggah Bukti',
                  subtitle: 'Kamera / PDF / Sertifikat',
                  meta: 'Format terenkripsi',
                  onTap: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (_, animation, __) =>
                            const StudentPklScreen(),
                        transitionsBuilder: (_, animation, __, child) =>
                            FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                                    begin: const Offset(0.05, 0),
                                    end: Offset.zero)
                                .animate(
                              CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeOutCubic),
                            ),
                            child: child,
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // 5. Laporan & Helpdesk Bug
                _buildActionModule(
                  icon: Icons.support_agent_outlined,
                  iconBg: const Color(0xFFFEF2F2),
                  iconColor: AppColors.error,
                  title: 'Lapor Kendala',
                  subtitle: 'Tiket Bantuan & Chat',
                  meta: 'Kirim bukti foto bug',
                  badge: 'Helpdesk',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ReportHelpdeskScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTelemetryCard({
    required String title,
    required String metric,
    required Color metricColor,
    required String subtitle,
    required Color subColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.bodySm.copyWith(fontSize: 11)),
          const SizedBox(height: 4),
          Text(
            metric,
            style: AppTypography.headlineMd.copyWith(
              color: metricColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: AppTypography.labelSm.copyWith(
              color: subColor,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildActionModule({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String meta,
    String? badge,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.surfaceLowest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
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
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: iconColor, size: 20),
                  ),
                  if (badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          color: AppColors.onSecondaryContainer,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const Spacer(),
              Text(
                title,
                style:
                    AppTypography.labelLg.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                subtitle,
                style: AppTypography.bodySm.copyWith(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                meta,
                style: AppTypography.labelSm.copyWith(
                  color: AppColors.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
