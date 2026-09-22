class SkillCompetencyModel {
  final int id;
  final String name;
  final String category;
  final double industryDemandPct;
  final double studentMasteryPct;
  final double gapPercentage;
  final String status;
  final String recommendation;
  final String auditTier;
  final int validatedUnits;
  final int evidenceLogsCount;

  SkillCompetencyModel({
    required this.id,
    required this.name,
    required this.category,
    required this.industryDemandPct,
    required this.studentMasteryPct,
    required this.gapPercentage,
    required this.status,
    required this.recommendation,
    required this.auditTier,
    required this.validatedUnits,
    required this.evidenceLogsCount,
  });

  factory SkillCompetencyModel.fromJson(Map<String, dynamic> json) {
    return SkillCompetencyModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      industryDemandPct:
          (json['industry_demand_pct'] as num?)?.toDouble() ?? 0.0,
      studentMasteryPct:
          (json['student_mastery_pct'] as num?)?.toDouble() ?? 0.0,
      gapPercentage: (json['gap_percentage'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'PENDING',
      recommendation: json['recommendation'] ?? '',
      auditTier: json['audit_tier'] ?? 'PENDING',
      validatedUnits: json['validated_units'] ?? 0,
      evidenceLogsCount: json['evidence_logs_count'] ?? 0,
    );
  }
}

class IndustryGapSummaryModel {
  final String studentName;
  final String targetRole;
  final double readinessIndexPct;
  final int validatedDudiUnits;
  final int evidenceLogsCount;
  final String telemetrySyncStatus;
  final String period;
  final List<SkillCompetencyModel> skills;

  IndustryGapSummaryModel({
    required this.studentName,
    required this.targetRole,
    required this.readinessIndexPct,
    required this.validatedDudiUnits,
    required this.evidenceLogsCount,
    required this.telemetrySyncStatus,
    required this.period,
    required this.skills,
  });

  factory IndustryGapSummaryModel.fromJson(Map<String, dynamic> json) {
    var rawSkills = json['skills'] as List? ?? [];
    return IndustryGapSummaryModel(
      studentName: json['student_name'] ?? '',
      targetRole: json['target_role'] ?? 'Belum Ditentukan',
      readinessIndexPct:
          (json['readiness_index_pct'] as num?)?.toDouble() ?? 0.0,
      validatedDudiUnits: json['validated_dudi_units'] ?? 0,
      evidenceLogsCount: json['evidence_logs_count'] ?? 0,
      telemetrySyncStatus: json['telemetry_sync_status'] ?? 'Real-time',
      period: json['period'] ?? '-',
      skills: rawSkills.map((s) => SkillCompetencyModel.fromJson(s)).toList(),
    );
  }
}
