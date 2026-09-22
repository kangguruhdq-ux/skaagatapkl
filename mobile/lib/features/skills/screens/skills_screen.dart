import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/typography.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/skills_provider.dart';
import '../models/skill_model.dart';
import '../../../shared/widgets/user_avatar.dart';


class SkillsScreen extends StatefulWidget {
  const SkillsScreen({Key? key}) : super(key: key);

  @override
  State<SkillsScreen> createState() => _SkillsScreenState();
}

class _SkillsScreenState extends State<SkillsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SkillsProvider>(context, listen: false).fetchGapAnalysis();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SkillsProvider>(context);
    final summary = provider.summary;
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;
    final studentName = user?.fullName ?? summary?.studentName ?? 'Siswa PKL';
    final studentClass = user?.studentClass ?? 'TKJ';

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: RefreshIndicator(
        onRefresh: () => provider.fetchGapAnalysis(),
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Profile & Career Focus Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
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
                              radius: 24,
                              avatarUrl: user?.avatarUrl,
                              name: studentName,
                            ),
                            Positioned(
                              bottom: -2,
                              right: -2,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.success,
                                ),
                                child: const Icon(Icons.verified,
                                    color: Colors.white, size: 12),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      studentName,
                                      style: AppTypography.labelLg.copyWith(
                                          fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceHigh,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      studentClass,
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Target: ${summary?.targetRole ?? "-"}',
                                style: AppTypography.bodySm.copyWith(
                                    color: AppColors.onSurfaceVariant),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('INDEX KESIAPAN',
                                style: AppTypography.labelSm
                                    .copyWith(fontSize: 9)),
                            const SizedBox(height: 2),
                            Text(
                              '${summary?.readinessIndexPct ?? 0.0}%',
                              style: AppTypography.headlineMd.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Quick Telemetry Badges (3 columns)
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLow,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Validated DUDI',
                                    style: AppTypography.labelSm
                                        .copyWith(fontSize: 10)),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Text(
                                      '${summary?.validatedDudiUnits ?? 0}',
                                      style: AppTypography.headlineSm.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text('Unit',
                                        style: AppTypography.labelSm
                                            .copyWith(fontSize: 10)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLow,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Evidence Audit',
                                    style: AppTypography.labelSm
                                        .copyWith(fontSize: 10)),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Text(
                                      '${summary?.evidenceLogsCount ?? 0}',
                                      style: AppTypography.headlineSm.copyWith(
                                        color: AppColors.secondary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text('Log',
                                        style: AppTypography.labelSm
                                            .copyWith(fontSize: 10)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLow,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Telemetry Sync',
                                    style: AppTypography.labelSm
                                        .copyWith(fontSize: 10)),
                                const SizedBox(height: 4),
                                Row(
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
                                      'Real-time',
                                      style: AppTypography.labelSm.copyWith(
                                        color: AppColors.onSurface,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Validation Status Legend (3 Tiers)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Text('AUDIT TIER:',
                        style: AppTypography.labelSm.copyWith(
                            fontWeight: FontWeight.bold, fontSize: 10)),
                    const Spacer(),
                    _buildTierLegend('AI_DETECTED', const Color(0xFFFEF3C7),
                        const Color(0xFFD97706)),
                    const SizedBox(width: 6),
                    _buildTierLegend('SUPERVISOR', const Color(0xFFE0F2FE),
                        AppColors.secondary),
                    const SizedBox(width: 6),
                    _buildTierLegend(
                        'SMKN 3', const Color(0xFFD1FAE5), AppColors.success),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Industry Demand vs Student Supply Gap Analysis
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
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
                            const Icon(Icons.query_stats,
                                color: AppColors.primary, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              'DUDI BENCHMARK ENGINE',
                              style: AppTypography.labelSm.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceHigh,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            summary?.period ?? '-',
                            style: AppTypography.labelSm
                                .copyWith(color: AppColors.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Analisis Kebutuhan Industri Yogyakarta & Nasional',
                      style: AppTypography.headlineSm
                          .copyWith(fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 16),

                    // Skill items
                    if (summary != null && summary.skills.isNotEmpty)
                      ...summary.skills
                          .map((skill) => _buildSkillGapItem(skill, studentName))
                    else if (provider.isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(
                              color: AppColors.primary),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 32, horizontal: 16),
                        child: Column(
                          children: [
                            Icon(Icons.query_builder_outlined,
                                size: 40, color: AppColors.onSurfaceVariant),
                            const SizedBox(height: 12),
                            Text(
                              'Belum Ada Data Kompetensi Keahlian',
                              style: AppTypography.labelLg
                                  .copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Analisis kesiapan kerja dan gap industri akan ditampilkan setelah aktivitas PKL dan jurnal diverifikasi oleh pembimbing.',
                              textAlign: TextAlign.center,
                              style: AppTypography.bodySm
                                  .copyWith(color: AppColors.onSurfaceVariant),
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

  Widget _buildTierLegend(String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Text(
        label,
        style: TextStyle(color: text, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSkillGapItem(SkillCompetencyModel skill, String studentName) {
    final isSurplus = skill.status == 'SURPLUS';
    final badgeBg =
        isSurplus ? AppColors.successContainer : AppColors.errorContainer;
    final badgeFg =
        isSurplus ? AppColors.onSuccessContainer : AppColors.onErrorContainer;
    final barColor = isSurplus ? AppColors.success : AppColors.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    skill.name,
                    style: AppTypography.labelLg
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${skill.status} ${skill.gapPercentage > 0 ? "+" : ""}${skill.gapPercentage.toInt()}%',
                      style: TextStyle(
                        color: badgeFg,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    'Demand: ${skill.industryDemandPct.toInt()}%  ',
                    style: AppTypography.bodySm.copyWith(fontSize: 11),
                  ),
                  Text(
                    '${studentName.trim().isNotEmpty ? studentName.split(" ").first : "Siswa"}: ${skill.studentMasteryPct.toInt()}%',
                    style: AppTypography.labelSm.copyWith(
                      color: isSurplus ? AppColors.success : AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Two-layer Progress Bar (Demand in background vs Student mastery in front)
          Stack(
            children: [
              Container(
                height: 10,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(9999),
                ),
              ),
              // Demand bar
              FractionallySizedBox(
                widthFactor: (skill.industryDemandPct / 100.0).clamp(0.0, 1.0),
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(9999),
                  ),
                ),
              ),
              // Student mastery bar
              FractionallySizedBox(
                widthFactor: (skill.studentMasteryPct / 100.0).clamp(0.0, 1.0),
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          // Recommendation tag
          Row(
            children: [
              Icon(
                isSurplus ? Icons.check_circle : Icons.warning_amber_rounded,
                size: 14,
                color: isSurplus ? AppColors.success : AppColors.error,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  skill.recommendation,
                  style: AppTypography.bodySm.copyWith(
                    color: isSurplus ? AppColors.success : AppColors.error,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
