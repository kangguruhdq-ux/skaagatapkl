import 'dart:convert';

class SkillTagModel {
  final String name;
  final int score;

  SkillTagModel({required this.name, required this.score});

  factory SkillTagModel.fromJson(Map<String, dynamic> json) {
    return SkillTagModel(
      name: json['name'] ?? '',
      score: json['score'] ?? 90,
    );
  }
}

class JournalModel {
  final int id;
  final int studentId;
  final int placementId;
  final String date;
  final int dayNumber;
  final double hoursSpent;
  final String workSummary;
  final String standardCompetency;
  final String competencyCategory;
  final String complexityLevel;
  final String complexityTier;
  final double aiMatchPercentage;
  final List<SkillTagModel> extractedSkills;
  final List<String> detectedTools;
  final int workflowStage;
  final String status;
  final String? revisionNotes;
  final bool isUrgentRevision;
  final String? reviewerName;
  final String? studentName;
  final String? photoUrl;

  JournalModel({
    required this.id,
    required this.studentId,
    required this.placementId,
    required this.date,
    required this.dayNumber,
    required this.hoursSpent,
    required this.workSummary,
    required this.standardCompetency,
    required this.competencyCategory,
    required this.complexityLevel,
    required this.complexityTier,
    required this.aiMatchPercentage,
    required this.extractedSkills,
    required this.detectedTools,
    required this.workflowStage,
    required this.status,
    this.revisionNotes,
    required this.isUrgentRevision,
    this.reviewerName,
    this.studentName,
    this.photoUrl,
  });

  factory JournalModel.fromJson(Map<String, dynamic> json) {
    List<SkillTagModel> skills = [];
    if (json['ai_extracted_skills'] != null) {
      try {
        final decoded = jsonDecode(json['ai_extracted_skills']);
        if (decoded is List) {
          skills = decoded.map((e) => SkillTagModel.fromJson(e)).toList();
        }
      } catch (_) {}
    }
    List<String> tools = [];
    if (json['detected_tools'] != null) {
      try {
        final decoded = jsonDecode(json['detected_tools']);
        if (decoded is List) {
          tools = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
    }

    String? photo = json['photo_url'];
    if (photo == null && json['attachments'] != null && (json['attachments'] as List).isNotEmpty) {
      final first = (json['attachments'] as List).first;
      if (first is Map && first['file_path'] != null) {
        photo = first['file_path'].toString();
      }
    }

    return JournalModel(
      id: json['id'] ?? 0,
      studentId: json['student_id'] ?? 0,
      placementId: json['placement_id'] ?? 0,
      date: json['date'] ?? '-',
      dayNumber: json['day_number'] ?? 1,
      hoursSpent: (json['hours_spent'] as num?)?.toDouble() ?? 8.0,
      workSummary: json['work_summary'] ?? '',
      standardCompetency: json['standard_competency'] ?? 'Kompetensi Siswa',
      competencyCategory: json['competency_category'] ?? 'Kejuruan SMK',
      complexityLevel: json['complexity_level'] ?? 'REGULER',
      complexityTier: json['complexity_tier'] ?? 'Siswa Praktik',
      aiMatchPercentage:
          (json['ai_match_percentage'] as num?)?.toDouble() ?? 0.0,
      extractedSkills: skills,
      detectedTools: tools,
      workflowStage: json['workflow_stage'] ?? 1,
      status: json['status'] ?? 'DRAFT',
      revisionNotes: json['revision_notes'],
      isUrgentRevision: json['is_urgent_revision'] ?? false,
      reviewerName: json['reviewer_name'],
      studentName: json['student_name'],
      photoUrl: photo,
    );
  }
}

class JournalHistoryModel {
  final int id;
  final int journalId;
  final String? previousStatus;
  final String newStatus;
  final int actorId;
  final String reviewer;
  final String? comment;
  final DateTime timestamp;

  JournalHistoryModel({
    required this.id,
    required this.journalId,
    this.previousStatus,
    required this.newStatus,
    required this.actorId,
    required this.reviewer,
    this.comment,
    required this.timestamp,
  });

  factory JournalHistoryModel.fromJson(Map<String, dynamic> json) {
    return JournalHistoryModel(
      id: json['id'] ?? 0,
      journalId: json['journal_id'] ?? 0,
      previousStatus: json['previous_status'],
      newStatus: json['new_status'] ?? '',
      actorId: json['actor_id'] ?? 0,
      reviewer: json['reviewer'] ?? 'Pembimbing',
      comment: json['comment'],
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
