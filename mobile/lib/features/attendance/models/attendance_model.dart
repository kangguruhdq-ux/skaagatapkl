class AttendanceRecordModel {
  final int id;
  final int studentId;
  final int placementId;
  final String date;
  final String? checkInTime;
  final String? checkOutTime;
  final double latitude;
  final double longitude;
  final double distanceMeters;
  final bool isInRadius;
  final double accuracyMeters;
  final bool mockLocationDetected;
  final String deviceFingerprint;
  final String status;
  final String? notes;
  final String shiftName;
  final bool verifiedByMentor;
  final String? selfieUrl;
  final String approvalStatus;
  final String? studentName;
  final String? studentNisn;

  AttendanceRecordModel({
    required this.id,
    required this.studentId,
    required this.placementId,
    required this.date,
    this.checkInTime,
    this.checkOutTime,
    required this.latitude,
    required this.longitude,
    required this.distanceMeters,
    required this.isInRadius,
    required this.accuracyMeters,
    required this.mockLocationDetected,
    required this.deviceFingerprint,
    required this.status,
    this.notes,
    required this.shiftName,
    required this.verifiedByMentor,
    this.selfieUrl,
    this.approvalStatus = 'PENDING',
    this.studentName,
    this.studentNisn,
  });

  factory AttendanceRecordModel.fromJson(Map<String, dynamic> json) {
    return AttendanceRecordModel(
      id: json['id'] ?? 0,
      studentId: json['student_id'] ?? 0,
      placementId: json['placement_id'] ?? 0,
      date: json['date'] ?? '',
      checkInTime: json['check_in_time'],
      checkOutTime: json['check_out_time'],
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      distanceMeters: (json['distance_meters'] as num?)?.toDouble() ?? 0.0,
      isInRadius: json['is_in_radius'] ?? false,
      accuracyMeters: (json['accuracy_meters'] as num?)?.toDouble() ?? 0.0,
      mockLocationDetected: json['mock_location_detected'] ?? false,
      deviceFingerprint: json['device_fingerprint'] ?? '-',
      status: json['status'] ?? 'HADIR',
      notes: json['notes'],
      shiftName: json['shift_name'] ?? '-',
      verifiedByMentor: json['verified_by_mentor'] ?? false,
      selfieUrl: json['selfie_url'],
      approvalStatus: json['approval_status'] ?? 'PENDING',
      studentName: json['student_name'],
      studentNisn: json['student_nisn'],
    );
  }
}

class AttendanceStatusModel {
  final bool hasCheckedInToday;
  final bool hasCheckedOutToday;
  final AttendanceRecordModel? todayRecord;
  final double targetLatitude;
  final double targetLongitude;
  final double geofenceRadius;
  final String companyName;
  final String shiftName;
  final int totalDaysAttended;
  final int totalDaysPermitted;
  final int totalDaysAlpha;
  final double attendanceRatePct;

  AttendanceStatusModel({
    required this.hasCheckedInToday,
    required this.hasCheckedOutToday,
    this.todayRecord,
    required this.targetLatitude,
    required this.targetLongitude,
    required this.geofenceRadius,
    required this.companyName,
    required this.shiftName,
    required this.totalDaysAttended,
    required this.totalDaysPermitted,
    required this.totalDaysAlpha,
    required this.attendanceRatePct,
  });

  factory AttendanceStatusModel.fromJson(Map<String, dynamic> json) {
    return AttendanceStatusModel(
      hasCheckedInToday: json['has_checked_in_today'] ?? false,
      hasCheckedOutToday: json['has_checked_out_today'] ?? false,
      todayRecord: json['today_record'] != null
          ? AttendanceRecordModel.fromJson(json['today_record'])
          : null,
      targetLatitude: (json['target_latitude'] as num?)?.toDouble() ?? 0.0,
      targetLongitude:
          (json['target_longitude'] as num?)?.toDouble() ?? 0.0,
      geofenceRadius: (json['geofence_radius'] as num?)?.toDouble() ?? 0.0,
      companyName: json['company_name'] ?? 'Belum Ada Penempatan',
      shiftName: json['shift_name'] ?? '-',
      totalDaysAttended: json['total_days_attended'] ?? 0,
      totalDaysPermitted: json['total_days_permitted'] ?? 0,
      totalDaysAlpha: json['total_days_alpha'] ?? 0,
      attendanceRatePct:
          (json['attendance_rate_pct'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
