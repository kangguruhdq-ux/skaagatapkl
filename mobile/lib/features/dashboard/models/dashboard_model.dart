class DashboardModel {
  final int studentId;
  final String studentName;
  final String nisn;
  final String studentClass;
  final String department;
  final String? avatarUrl;
  final bool isTelemetryOnline;
  final PlacementInfoModel? placement;
  final UrgentAlertModel? urgentAlert;
  final QuickTelemetryModel telemetryStrip;
  final int activeTasksCount;
  final int draftJournalsCount;

  DashboardModel({
    required this.studentId,
    required this.studentName,
    required this.nisn,
    required this.studentClass,
    required this.department,
    this.avatarUrl,
    required this.isTelemetryOnline,
    this.placement,
    this.urgentAlert,
    required this.telemetryStrip,
    required this.activeTasksCount,
    required this.draftJournalsCount,
  });

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    return DashboardModel(
      studentId: json['student_id'] ?? 0,
      studentName: json['student_name'] ?? '',
      nisn: json['nisn'] ?? '',
      studentClass: json['student_class'] ?? '-',
      department: json['department'] ?? '-',
      avatarUrl: json['avatar_url'],
      isTelemetryOnline: json['is_telemetry_online'] ?? true,
      placement: json['placement'] != null
          ? PlacementInfoModel.fromJson(json['placement'])
          : null,
      urgentAlert: json['urgent_alert'] != null
          ? UrgentAlertModel.fromJson(json['urgent_alert'])
          : null,
      telemetryStrip:
          QuickTelemetryModel.fromJson(json['telemetry_strip'] ?? {}),
      activeTasksCount: json['active_tasks_count'] ?? 0,
      draftJournalsCount: json['draft_journals_count'] ?? 0,
    );
  }
}

class PlacementInfoModel {
  final int id;
  final String companyName;
  final String division;
  final String address;
  final String mentorName;
  final String supervisorName;
  final String periodString;
  final int currentWeek;
  final int totalWeeks;
  final int progressPct;
  final String status;

  PlacementInfoModel({
    required this.id,
    required this.companyName,
    required this.division,
    required this.address,
    required this.mentorName,
    required this.supervisorName,
    required this.periodString,
    required this.currentWeek,
    required this.totalWeeks,
    required this.progressPct,
    required this.status,
  });

  factory PlacementInfoModel.fromJson(Map<String, dynamic> json) {
    return PlacementInfoModel(
      id: json['id'] ?? 0,
      companyName: json['company_name'] ?? '',
      division: json['division'] ?? '',
      address: json['address'] ?? '',
      mentorName: json['mentor_name'] ?? '-',
      supervisorName: json['supervisor_name'] ?? '-',
      periodString: json['period_string'] ?? '-',
      currentWeek: json['current_week'] ?? 0,
      totalWeeks: json['total_weeks'] ?? 0,
      progressPct: json['progress_pct'] ?? 0,
      status: json['status'] ?? 'Active Placement',
    );
  }
}

class UrgentAlertModel {
  final int id;
  final String title;
  final String badgeLabel;
  final String notes;
  final String actionLabel;
  final String targetRoute;
  final int? journalId;

  UrgentAlertModel({
    required this.id,
    required this.title,
    required this.badgeLabel,
    required this.notes,
    required this.actionLabel,
    required this.targetRoute,
    this.journalId,
  });

  factory UrgentAlertModel.fromJson(Map<String, dynamic> json) {
    return UrgentAlertModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? 'Perlu Tindakan: Revisi Jurnal',
      badgeLabel: json['badge_label'] ?? 'Urgent',
      notes: json['notes'] ?? '',
      actionLabel: json['action_label'] ?? 'Buka Revisi',
      targetRoute: json['target_route'] ?? '/journal',
      journalId: json['journal_id'],
    );
  }
}

class QuickTelemetryModel {
  final double attendanceRatePct;
  final int totalPresentDays;
  final int permittedDays;
  final int alphaDays;
  final double lastGpsDistanceMeters;
  final bool isInGeofence;

  QuickTelemetryModel({
    required this.attendanceRatePct,
    required this.totalPresentDays,
    required this.permittedDays,
    required this.alphaDays,
    required this.lastGpsDistanceMeters,
    required this.isInGeofence,
  });

  factory QuickTelemetryModel.fromJson(Map<String, dynamic> json) {
    return QuickTelemetryModel(
      attendanceRatePct:
          (json['attendance_rate_pct'] as num?)?.toDouble() ?? 0.0,
      totalPresentDays: json['total_present_days'] ?? 0,
      permittedDays: json['permitted_days'] ?? 0,
      alphaDays: json['alpha_days'] ?? 0,
      lastGpsDistanceMeters:
          (json['last_gps_distance_meters'] as num?)?.toDouble() ?? 0.0,
      isInGeofence: json['is_in_geofence'] ?? false,
    );
  }
}
