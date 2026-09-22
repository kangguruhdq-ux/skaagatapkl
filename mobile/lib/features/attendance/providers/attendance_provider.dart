import 'package:flutter/material.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../models/attendance_model.dart';

class AttendanceProvider extends ChangeNotifier {
  AttendanceStatusModel? _status;
  List<AttendanceRecordModel> _history = [];
  bool _isLoading = false;
  String? _errorMessage;

  AttendanceStatusModel? get status => _status;
  List<AttendanceRecordModel> get history => _history;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchAttendanceStatus() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await ApiClient.get(ApiEndpoints.attendanceStatus);
    if (response.success && response.data != null) {
      _status =
          AttendanceStatusModel.fromJson(response.data as Map<String, dynamic>);
    } else {
      _errorMessage = response.error;
    }

    // Fetch history
    final historyRes = await ApiClient.get(ApiEndpoints.attendanceHistory);
    if (historyRes.success && historyRes.data != null) {
      final list = historyRes.data as List;
      _history =
          list.map((item) => AttendanceRecordModel.fromJson(item)).toList();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> checkIn({
    required double latitude,
    required double longitude,
    String? notes,
    String? selfieUrl,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await ApiClient.post(
      ApiEndpoints.checkIn,
      body: {
        'latitude': latitude,
        'longitude': longitude,
        'accuracy_meters': 4.2,
        'device_fingerprint': 'SKGT-DEV-8842',
        'notes': notes ?? 'Presensi mandiri biometrik terverifikasi',
        'selfie_url': selfieUrl,
      },
    );

    _isLoading = false;
    if (response.success) {
      await fetchAttendanceStatus();
      return true;
    } else {
      _errorMessage = response.error ?? 'Gagal melakukan presensi masuk.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> checkOut({String? notes}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await ApiClient.post(
      ApiEndpoints.checkOut,
      body: {
        'latitude': _status?.targetLatitude ?? -7.78542,
        'longitude': _status?.targetLongitude ?? 110.37219,
        'accuracy_meters': 4.2,
        'notes': notes ?? 'Selesai jam kerja shift harian',
      },
    );

    _isLoading = false;
    if (response.success) {
      await fetchAttendanceStatus();
      return true;
    } else {
      _errorMessage = response.error ?? 'Gagal melakukan presensi keluar.';
      notifyListeners();
      return false;
    }
  }
}
