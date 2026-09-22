import 'dart:convert';
import 'package:http_parser/http_parser.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import '../constants/api_endpoints.dart';
import '../storage/local_storage.dart';

class ApiResponseData<T> {
  final bool success;
  final T? data;
  final String? message;
  final String? error;

  ApiResponseData({
    required this.success,
    this.data,
    this.message,
    this.error,
  });
}

class ApiClient {
  static final http.Client _client = http.Client();

  static Future<http.Response> _executeWithRefresh(
    Future<http.Response> Function(String? token) requestFunc,
  ) async {
    final token = await LocalStorage.getAccessToken();
    http.Response response = await requestFunc(token);

    if (response.statusCode == 401) {
      // Attempt token refresh
      final refreshToken = await LocalStorage.getRefreshToken();
      if (refreshToken != null) {
        final refreshRes = await _client.post(
          Uri.parse(ApiEndpoints.refresh),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'refresh_token': refreshToken}),
        );

        if (refreshRes.statusCode == 200) {
          final resJson = jsonDecode(refreshRes.body);
          if (resJson['success'] == true && resJson['data'] != null) {
            final newAccess = resJson['data']['access_token'];
            final newRefresh = resJson['data']['refresh_token'];
            await LocalStorage.saveTokens(
              accessToken: newAccess,
              refreshToken: newRefresh,
            );
            // Retry original request with new token
            response = await requestFunc(newAccess);
          }
        } else {
          await LocalStorage.clearSession();
        }
      }
    }
    return response;
  }

  static Future<ApiResponseData<dynamic>> get(String url,
      {bool requiresAuth = true}) async {
    try {
      final response = await _executeWithRefresh((token) async {
        final headers = <String, String>{'Accept': 'application/json'};
        if (requiresAuth && token != null) {
          headers['Authorization'] = 'Bearer $token';
        }
        return await _client.get(Uri.parse(url), headers: headers);
      });

      final json = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponseData(
          success: json['success'] ?? true,
          data: json['data'],
          message: json['message'],
        );
      } else {
        final errorMsg = json['detail'] ??
            (json['error'] is Map
                ? json['error']['message']
                : json['message']) ??
            'Request failed';
        return ApiResponseData(success: false, error: errorMsg.toString());
      }
    } catch (e) {
      return ApiResponseData(success: false, error: 'Koneksi gagal: $e');
    }
  }

  static Future<ApiResponseData<dynamic>> post(
    String url, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    try {
      final response = await _executeWithRefresh((token) async {
        final headers = <String, String>{
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        };
        if (requiresAuth && token != null) {
          headers['Authorization'] = 'Bearer $token';
        }
        return await _client.post(
          Uri.parse(url),
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
      });

      final json = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponseData(
          success: json['success'] ?? true,
          data: json['data'],
          message: json['message'],
        );
      } else {
        final errorMsg = json['detail'] ??
            (json['error'] is Map
                ? json['error']['message']
                : json['message']) ??
            'Request failed';
        return ApiResponseData(success: false, error: errorMsg.toString());
      }
    } catch (e) {
      return ApiResponseData(success: false, error: 'Koneksi gagal: $e');
    }
  }

  static Future<ApiResponseData<dynamic>> patch(
    String url, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    try {
      final response = await _executeWithRefresh((token) async {
        final headers = <String, String>{
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        };
        if (requiresAuth && token != null) {
          headers['Authorization'] = 'Bearer $token';
        }
        return await _client.patch(
          Uri.parse(url),
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
      });

      final json = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponseData(
          success: json['success'] ?? true,
          data: json['data'],
          message: json['message'],
        );
      } else {
        final errorMsg = json['detail'] ?? json['message'] ?? 'Request failed';
        return ApiResponseData(success: false, error: errorMsg.toString());
      }
    } catch (e) {
      return ApiResponseData(success: false, error: 'Koneksi gagal: $e');
    }
  }

  static Future<ApiResponseData<dynamic>> put(
    String url, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    try {
      final response = await _executeWithRefresh((token) async {
        final headers = <String, String>{
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        };
        if (requiresAuth && token != null) {
          headers['Authorization'] = 'Bearer $token';
        }
        return await _client.put(
          Uri.parse(url),
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
      });

      final json = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponseData(
          success: json['success'] ?? true,
          data: json['data'],
          message: json['message'],
        );
      } else {
        final errorMsg = json['detail'] ?? json['message'] ?? 'Request failed';
        return ApiResponseData(success: false, error: errorMsg.toString());
      }
    } catch (e) {
      return ApiResponseData(success: false, error: 'Koneksi gagal: $e');
    }
  }

  static Future<ApiResponseData<dynamic>> delete(
    String url, {
    bool requiresAuth = true,
  }) async {
    try {
      final response = await _executeWithRefresh((token) async {
        final headers = <String, String>{
          'Accept': 'application/json',
        };
        if (requiresAuth && token != null) {
          headers['Authorization'] = 'Bearer $token';
        }
        return await _client.delete(Uri.parse(url), headers: headers);
      });

      final json = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponseData(
          success: json['success'] ?? true,
          data: json['data'],
          message: json['message'],
        );
      } else {
        final errorMsg = json['detail'] ?? json['message'] ?? 'Request failed';
        return ApiResponseData(success: false, error: errorMsg.toString());
      }
    } catch (e) {
      return ApiResponseData(success: false, error: 'Koneksi gagal: $e');
    }
  }

  static Future<ApiResponseData<dynamic>> upload(
    String url,
    PlatformFile file, {
    String field = 'file',
    Map<String, String>? fields,
  }) async {
    try {
      final req = http.MultipartRequest('POST', Uri.parse(url));
      final token = await LocalStorage.getAccessToken();
      if (token != null) req.headers['Authorization'] = 'Bearer $token';
      if (fields != null) {
        req.fields.addAll(fields);
      }
      if (file.bytes == null) {
        return ApiResponseData(
            success: false, error: 'Berkas tidak dapat dibaca.');
      }
      req.files.add(http.MultipartFile.fromBytes(field, file.bytes!,
          filename: file.name,
          contentType: MediaType.parse(file.extension?.toLowerCase() == 'pdf'
              ? 'application/pdf'
              : file.extension?.toLowerCase() == 'png'
                  ? 'image/png'
                  : 'image/jpeg')));
      final response = await req.send().timeout(const Duration(seconds: 60));
      final body = await response.stream.bytesToString();
      final json = jsonDecode(body);
      return ApiResponseData(
          success: response.statusCode >= 200 && response.statusCode < 300,
          data: json['data'],
          message: json['message'],
          error: json['detail']);
    } catch (e) {
      return ApiResponseData(success: false, error: 'Upload gagal: $e');
    }
  }
}
