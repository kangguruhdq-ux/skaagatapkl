import 'dart:convert';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/local_storage.dart';
import '../models/user_model.dart';

class AuthService {
  static Future<ApiResponseData<UserModel>> login({
    required String username,
    required String password,
    String? role,
    String? deviceId,
    String? deviceModel,
  }) async {
    final response = await ApiClient.post(
      ApiEndpoints.login,
      body: {
        'username': username,
        'password': password,
        'role': role,
        'device_id': deviceId ?? 'SKGT-DEV-8842',
        'device_model': deviceModel ?? 'Samsung Galaxy A54 5G',
      },
      requiresAuth: false,
    );

    if (response.success && response.data != null) {
      final data = response.data as Map<String, dynamic>;
      final accessToken = data['access_token'];
      final refreshToken = data['refresh_token'];
      final userData = data['user'];

      await LocalStorage.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
      await LocalStorage.saveUserData(jsonEncode(userData));

      return ApiResponseData(
        success: true,
        data: UserModel.fromJson(userData),
        message: response.message,
      );
    }
    return ApiResponseData(success: false, error: response.error);
  }

  static Future<ApiResponseData<UserModel>> register({
    required String username,
    required String fullName,
    String? email,
    required String password,
    String role = 'siswa',
    String department = 'Teknik Komputer dan Jaringan',
    String studentClass = 'XII TKJ 1',
  }) async {
    final response = await ApiClient.post(
      ApiEndpoints.register,
      body: {
        'username': username,
        'full_name': fullName,
        'email': email,
        'password': password,
        'role': role,
        'department': department,
        'student_class': studentClass,
      },
      requiresAuth: false,
    );

    if (response.success && response.data != null) {
      final data = response.data as Map<String, dynamic>;
      final accessToken = data['access_token'];
      final refreshToken = data['refresh_token'];
      final userData = data['user'];

      await LocalStorage.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
      await LocalStorage.saveUserData(jsonEncode(userData));

      return ApiResponseData(
        success: true,
        data: UserModel.fromJson(userData),
        message: response.message,
      );
    }
    return ApiResponseData(success: false, error: response.error);
  }

  static Future<ApiResponseData<Map<String, dynamic>>> verifyDapodik(
      String nisn) async {
    final response = await ApiClient.get(
      '${ApiEndpoints.verifyDapodik}?nisn=$nisn',
      requiresAuth: false,
    );
    if (response.success && response.data != null) {
      return ApiResponseData(
        success: true,
        data: response.data as Map<String, dynamic>,
        message: response.message,
      );
    }
    return ApiResponseData(success: false, error: response.error);
  }

  static Future<void> logout() async {
    await ApiClient.post(ApiEndpoints.baseUrl + '/auth/logout');
    await LocalStorage.clearSession();
  }

  static Future<ApiResponseData<UserModel>> getMe() async {
    final response = await ApiClient.get(ApiEndpoints.me);
    if (response.success && response.data != null) {
      final userData = response.data as Map<String, dynamic>;
      await LocalStorage.saveUserData(jsonEncode(userData));
      return ApiResponseData(
        success: true,
        data: UserModel.fromJson(userData),
        message: response.message,
      );
    }
    return ApiResponseData(success: false, error: response.error);
  }
}
