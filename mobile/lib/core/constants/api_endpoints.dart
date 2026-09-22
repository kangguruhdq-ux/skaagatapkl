import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiEndpoints {
  // Configurable base URL
  static String get defaultHost {
    if (kIsWeb) {
      final host = Uri.base.host.isEmpty ? '127.0.0.1' : Uri.base.host;
      return 'http://$host:8000';
    }
    if (Platform.isAndroid) {
      // 10.0.2.2 points to host machine from Android Emulator
      return 'http://10.0.2.2:8000';
    }
    return 'http://127.0.0.1:8000';
  }

  static String baseUrl = '$defaultHost/api/v1';

  static void setCustomHost(String host) {
    if (host.endsWith('/api/v1')) {
      baseUrl = host;
    } else {
      baseUrl = '${host.replaceAll(RegExp(r'/+$'), '')}/api/v1';
    }
  }

  // Auth
  static String get login => '$baseUrl/auth/login';
  static String get register => '$baseUrl/auth/register';
  static String get refresh => '$baseUrl/auth/refresh';
  static String get me => '$baseUrl/auth/me';
  static String get verifyDapodik => '$baseUrl/auth/verify-dapodik';

  // Dashboard
  static String get dashboardSummary => '$baseUrl/dashboard/summary';

  // Attendance
  static String get attendanceStatus => '$baseUrl/attendance/status';
  static String get checkIn => '$baseUrl/attendance/check-in';
  static String get checkOut => '$baseUrl/attendance/check-out';
  static String get attendanceHistory => '$baseUrl/attendance/history';
  static String get attendanceRecords => '$baseUrl/attendance/records';
  static String reviewAttendance(int id) => '$baseUrl/attendance/$id/review';
  static String attendanceDetail(int id) => '$baseUrl/attendance/$id';

  // Journals
  static String get journals => '$baseUrl/journals';
  static String get analyzeAi => '$baseUrl/journals/analyze-ai';
  static String journalDetail(int id) => '$baseUrl/journals/$id';
  static String submitJournal(int id) => '$baseUrl/journals/$id/submit';

  // Skills
  static String get skillGapAnalysis => '$baseUrl/skills/gap-analysis';

  // Uploads
  static String get upload => '$baseUrl/upload';

  // Notifications
  static String get notifications => '$baseUrl/notifications';

  // PKL Submissions & Change Requests
  static String get submissions => '$baseUrl/submissions';
  static String submissionDetail(int id) => '$baseUrl/submissions/$id';
  static String submissionChangeRequest(int id) =>
      '$baseUrl/submissions/$id/change-request';
  static String submissionReview(int id) => '$baseUrl/submissions/$id/review';

  // PKL Evidences
  static String get evidences => '$baseUrl/evidences';
  static String verifyEvidence(int id) => '$baseUrl/evidences/$id/verify';

  // Audit Logs
  static String get auditLogs => '$baseUrl/audit/logs';

  // Admin Portal & Companies
  static String get adminStats => '$baseUrl/admin/stats';
  static String get adminCompanies => '$baseUrl/admin/companies';
  static String adminCompanyDetail(int id) => '$baseUrl/admin/companies/$id';
  static String get adminJournals => '$baseUrl/admin/journals';
  static String reviewAdminJournal(int id) =>
      '$baseUrl/admin/journals/$id/review';
  static String get adminUsers => '$baseUrl/users';
  static String adminUserDetail(int id) => '$baseUrl/users/$id';

  // Helpdesk & Report Tickets
  static String get tickets => '$baseUrl/tickets';
  static String get ticketUploadPhoto => '$baseUrl/tickets/upload-photo';
  static String ticketDetail(int id) => '$baseUrl/tickets/$id';
  static String ticketStatus(int id) => '$baseUrl/tickets/$id/status';
  static String ticketMessages(int id) => '$baseUrl/tickets/$id/messages';

  static String getImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final clean = path.startsWith('/') ? path : '/$path';
    final hostBase = baseUrl.replaceAll('/api/v1', '');
    return '$hostBase$clean';
  }
}
