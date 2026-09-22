import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/screens/profile_screen.dart';
import '../../../shared/widgets/animated_refresh_button.dart';

class MentorDashboardScreen extends StatefulWidget {
  const MentorDashboardScreen({Key? key}) : super(key: key);

  @override
  State<MentorDashboardScreen> createState() => _MentorDashboardScreenState();
}

class _MentorDashboardScreenState extends State<MentorDashboardScreen> {
  bool _isLoading = false;
  List<dynamic> _journals = [];

  @override
  void initState() {
    super.initState();
    _fetchJournals();
  }

  Future<void> _fetchJournals() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiClient.get('${ApiEndpoints.baseUrl}/admin/journals');
      if (res.success && res.data != null) {
        if (res.data is List) {
          _journals = res.data as List;
        } else if (res.data is Map && res.data['items'] is List) {
          _journals = res.data['items'] as List;
        }
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  Future<void> _reviewAction(int id, String action) async {
    final res = await ApiClient.patch(
      '${ApiEndpoints.baseUrl}/admin/journals/$id/review?action=$action',
    );
    if (mounted) {
      if (res.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(action == 'approve'
                ? 'Jurnal disetujui oleh Mentor Lapangan.'
                : 'Jurnal diminta revisi.'),
            backgroundColor:
                action == 'approve' ? AppColors.success : AppColors.warning,
          ),
        );
        _fetchJournals();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: Colors.amber.shade700,
                  borderRadius: BorderRadius.circular(8)),
              child:
                  const Icon(Icons.engineering, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('PORTAL MITRA INDUSTRI',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold)),
                Text(
                    '${user?.fullName ?? "Ir. Bambang Hermanto"} • PT Telkom Witel',
                    style: const TextStyle(
                        color: Color(0xFF94A3B8), fontSize: 10)),
              ],
            ),
          ],
        ),
        actions: [
          AnimatedRefreshButton(
            onRefresh: _fetchJournals,
            color: Colors.white,
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.white),
            tooltip: 'Profil Mentor',
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
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // DUDI Banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFFB45309), Color(0xFFD97706)]),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Antrean Verifikasi Jurnal PKL',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14)),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6)),
                              child: const Text('NOC TELKOM',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                            'Validasi kompetensi teknis & capaian harian siswa PKL',
                            style: TextStyle(
                                color: Color(0xFFFEF3C7), fontSize: 11)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  Text('JURNAL HARIAN MENUNGGU REVIEW',
                      style: AppTypography.labelSm
                          .copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),

                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _journals.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final j = _journals[index];
                      final studentName = j['student_name'] ?? j['reviewer_name'] ?? 'Siswa Bimbingan';
                      final photo = j['photo_url'];

                      return Container(
                        padding: const EdgeInsets.all(14),
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
                                        color: Colors.amber.shade700.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        studentName,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.amber.shade900,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                        'Hari ${j['day_number'] ?? '-'} • ${j['date'] ?? ''}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                            color: Color(0xFF64748B))),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: j['status'] == 'APPROVED'
                                        ? AppColors.successContainer
                                        : AppColors.warningContainer,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    j['status'] ?? 'SUBMITTED',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: j['status'] == 'APPROVED'
                                          ? AppColors.success
                                          : AppColors.onWarningContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (photo != null && photo.toString().isNotEmpty) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  ApiEndpoints.getImageUrl(photo.toString()),
                                  height: 120,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                            Text(j['work_summary'] ?? '',
                                style: const TextStyle(fontSize: 12)),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton(
                                  onPressed: () =>
                                      _reviewAction(j['id'], 'revise'),
                                  style: OutlinedButton.styleFrom(
                                      visualDensity: VisualDensity.compact),
                                  child: const Text('Minta Revisi',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.warning)),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () =>
                                      _reviewAction(j['id'], 'approve'),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.success,
                                      visualDensity: VisualDensity.compact),
                                  child: const Text('Setujui (Valid)',
                                      style: TextStyle(
                                          fontSize: 11, color: Colors.white)),
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
    );
  }
}
