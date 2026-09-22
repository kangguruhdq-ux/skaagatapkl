import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/navigation/navigation_service.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/local_storage.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isAuthenticated = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _isAuthenticated;

  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    final token = await LocalStorage.getAccessToken();
    if (token != null) {
      // Fetch fresh authoritative profile from backend
      final meRes = await AuthService.getMe();
      if (meRes.success && meRes.data != null) {
        _user = meRes.data;
        _isAuthenticated = true;
      } else {
        // Token invalid or expired, clear session
        await LocalStorage.clearSession();
        _user = null;
        _isAuthenticated = false;
      }
    } else {
      _user = null;
      _isAuthenticated = false;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login({
    required String username,
    required String password,
    String? role,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await AuthService.login(
      username: username,
      password: password,
      role: role,
    );

    if (response.success && response.data != null) {
      // Fetch authoritative user record from backend /auth/me
      final meRes = await AuthService.getMe();
      _user = meRes.success && meRes.data != null ? meRes.data : response.data;
      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _errorMessage = response.error ??
          'Gagal masuk. Periksa pengenal dan kata sandi Anda.';
      _isAuthenticated = false;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String username,
    required String fullName,
    String? email,
    required String password,
    String role = 'siswa',
    String department = 'Teknik Komputer dan Jaringan',
    String studentClass = '-',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await AuthService.register(
      username: username,
      fullName: fullName,
      email: email,
      password: password,
      role: role,
      department: department,
      studentClass: studentClass,
    );

    _isLoading = false;
    if (response.success && response.data != null) {
      _user = response.data;
      _isAuthenticated = true;
      notifyListeners();
      return true;
    } else {
      _errorMessage = response.error ?? 'Gagal mendaftar. Silakan coba lagi.';
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await AuthService.logout();
    _user = null;
    _isAuthenticated = false;
    _isLoading = false;
    notifyListeners();

    try {
      NavigationService.navigatorKey.currentState
          ?.popUntil((route) => route.isFirst);
    } catch (_) {}
  }

  Future<bool> updateProfile({
    String? fullName,
    String? email,
    String? phone,
    String? studentClass,
    String? department,
    String? avatarUrl,
  }) async {
    _isLoading = true;
    notifyListeners();

    final res = await ApiClient.put(
      '${ApiEndpoints.baseUrl}/users/me/profile',
      body: {
        if (fullName != null) 'full_name': fullName,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        if (studentClass != null) 'student_class': studentClass,
        if (department != null) 'department': department,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
      },
    );

    _isLoading = false;
    if (res.success && res.data != null) {
      _user = UserModel.fromJson(res.data);
      await LocalStorage.saveUserData(jsonEncode(_user!.toJson()));
      notifyListeners();
      return true;
    } else {
      _errorMessage = res.error ?? 'Gagal memperbarui profil.';
      notifyListeners();
      return false;
    }
  }

  Future<void> refreshProfile() async {
    final result = await AuthService.getMe();
    if (result.success && result.data != null) {
      _user = result.data;
      await LocalStorage.saveUserData(jsonEncode(_user!.toJson()));
      notifyListeners();
    }
  }

  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    _isLoading = true;
    notifyListeners();

    final res = await ApiClient.put(
      '${ApiEndpoints.baseUrl}/users/me/password',
      body: {
        'old_password': oldPassword,
        'new_password': newPassword,
      },
    );

    _isLoading = false;
    notifyListeners();
    return res.success;
  }

  Future<bool> updateDevice({
    required String deviceId,
    String? deviceModel,
  }) async {
    _isLoading = true;
    notifyListeners();

    final res = await ApiClient.put(
      '${ApiEndpoints.baseUrl}/users/me/device',
      body: {
        'device_id': deviceId,
        if (deviceModel != null) 'device_model': deviceModel,
      },
    );

    if (res.success && res.data != null) {
      _user = UserModel.fromJson(res.data as Map<String, dynamic>);
      await LocalStorage.saveUser(_user!);
    }

    _isLoading = false;
    notifyListeners();
    return res.success;
  }
}
