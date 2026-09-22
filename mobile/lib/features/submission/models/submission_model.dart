class PklSubmissionModel {
  final int id;
  final int studentId;
  final int companyId;
  final String? companyName;
  final String? address;
  final String status;
  final String? proposalLetterUrl;
  final String? changeReason;
  final int? targetCompanyId;
  final String? supervisorNotes;
  final String? notes;
  final double? companyLatitude;
  final double? companyLongitude;
  final DateTime submittedAt;
  final DateTime? reviewedAt;
  final String? studentName;
  final String? studentNisn;
  final String? studentClass;

  PklSubmissionModel({
    required this.id,
    required this.studentId,
    required this.companyId,
    this.companyName,
    this.address,
    required this.status,
    this.proposalLetterUrl,
    this.changeReason,
    this.targetCompanyId,
    this.supervisorNotes,
    this.notes,
    this.companyLatitude,
    this.companyLongitude,
    required this.submittedAt,
    this.reviewedAt,
    this.studentName,
    this.studentNisn,
    this.studentClass,
  });

  factory PklSubmissionModel.fromJson(Map<String, dynamic> json) {
    return PklSubmissionModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      studentId: json['student_id'] is int
          ? json['student_id']
          : int.parse(json['student_id'].toString()),
      companyId: json['company_id'] is int
          ? json['company_id']
          : (json['company_id'] != null ? int.parse(json['company_id'].toString()) : 0),
      companyName: json['company_name'],
      address: json['address'] ?? json['company_address'],
      status: json['status'] ?? 'PENDING',
      proposalLetterUrl: json['proposal_letter_url'] ?? json['document_url'],
      changeReason: json['change_reason'],
      targetCompanyId: json['target_company_id'],
      supervisorNotes: json['supervisor_notes'] ?? json['teacher_notes'] ?? json['notes'],
      notes: json['notes'] ?? json['teacher_notes'] ?? json['supervisor_notes'],
      companyLatitude: json['company_latitude'] != null
          ? (json['company_latitude'] as num).toDouble()
          : (json['latitude'] != null ? (json['latitude'] as num).toDouble() : null),
      companyLongitude: json['company_longitude'] != null
          ? (json['company_longitude'] as num).toDouble()
          : (json['longitude'] != null ? (json['longitude'] as num).toDouble() : null),
      submittedAt: json['submitted_at'] != null
          ? DateTime.parse(json['submitted_at'])
          : (json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now()),
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.parse(json['reviewed_at'])
          : null,
      studentName: json['student_name'],
      studentNisn: json['student_nisn'],
      studentClass: json['student_class'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'company_id': companyId,
      'company_name': companyName,
      'address': address,
      'status': status,
      'proposal_letter_url': proposalLetterUrl,
      'change_reason': changeReason,
      'target_company_id': targetCompanyId,
      'supervisor_notes': supervisorNotes,
      'notes': notes,
      'company_latitude': companyLatitude,
      'company_longitude': companyLongitude,
      'submitted_at': submittedAt.toIso8601String(),
      'reviewed_at': reviewedAt?.toIso8601String(),
    };
  }
}

class PklEvidenceModel {
  final int id;
  final int studentId;
  final String title;
  final String category;
  final String? description;
  final String fileUrl;
  final String status;
  final String? reviewNotes;
  final DateTime submittedAt;
  final DateTime? verifiedAt;
  final String? studentName;
  final String? studentClass;
  final String? companyName;

  PklEvidenceModel({
    required this.id,
    required this.studentId,
    required this.title,
    required this.category,
    this.description,
    required this.fileUrl,
    required this.status,
    this.reviewNotes,
    required this.submittedAt,
    this.verifiedAt,
    this.studentName,
    this.studentClass,
    this.companyName,
  });

  factory PklEvidenceModel.fromJson(Map<String, dynamic> json) {
    return PklEvidenceModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      studentId: json['student_id'] is int
          ? json['student_id']
          : int.parse(json['student_id'].toString()),
      title: json['title'] ?? '',
      category: json['category'] ?? 'daily_photo',
      description: json['description'],
      fileUrl: json['file_url'] ?? '',
      status: json['status'] ?? 'UPLOADED',
      reviewNotes: json['review_notes'],
      submittedAt: json['submitted_at'] != null
          ? DateTime.parse(json['submitted_at'])
          : DateTime.now(),
      verifiedAt: json['verified_at'] != null
          ? DateTime.parse(json['verified_at'])
          : null,
      studentName: json['student_name'],
      studentClass: json['student_class'],
      companyName: json['company_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'title': title,
      'category': category,
      'description': description,
      'file_url': fileUrl,
      'status': status,
      'review_notes': reviewNotes,
      'submitted_at': submittedAt.toIso8601String(),
      'verified_at': verifiedAt?.toIso8601String(),
    };
  }
}
