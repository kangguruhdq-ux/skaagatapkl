import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/local_storage.dart';
import '../models/ticket_model.dart';

class TicketService {
  static Future<List<ReportTicketModel>> getTickets({String? status, String? query}) async {
    try {
      final queryParams = <String>[];
      if (status != null && status.isNotEmpty && status.toLowerCase() != 'all') {
        queryParams.add('status=${Uri.encodeComponent(status)}');
      }
      if (query != null && query.isNotEmpty) {
        queryParams.add('q=${Uri.encodeComponent(query)}');
      }

      String url = ApiEndpoints.tickets;
      if (queryParams.isNotEmpty) {
        url += '?${queryParams.join('&')}';
      }

      final res = await ApiClient.get(url);
      if (res.success && res.data != null && res.data is List) {
        return (res.data as List)
            .map((item) => ReportTicketModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<ReportTicketModel?> getTicketDetail(int id) async {
    try {
      final res = await ApiClient.get(ApiEndpoints.ticketDetail(id));
      if (res.success && res.data != null && res.data is Map) {
        return ReportTicketModel.fromJson(res.data as Map<String, dynamic>);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<ApiResponseData<dynamic>> createTicket({
    required String title,
    required String description,
    String category = 'BUG',
    String priority = 'NORMAL',
    String? photoUrl,
  }) async {
    return await ApiClient.post(
      ApiEndpoints.tickets,
      body: {
        'title': title,
        'description': description,
        'category': category,
        'priority': priority,
        'photo_url': photoUrl,
      },
    );
  }

  static Future<ApiResponseData<dynamic>> updateTicketStatus({
    required int ticketId,
    required String status,
    String? adminNotes,
  }) async {
    return await ApiClient.patch(
      ApiEndpoints.ticketStatus(ticketId),
      body: {
        'status': status,
        'admin_notes': adminNotes,
      },
    );
  }

  static Future<ApiResponseData<dynamic>> sendMessage({
    required int ticketId,
    required String message,
    String? photoUrl,
  }) async {
    return await ApiClient.post(
      ApiEndpoints.ticketMessages(ticketId),
      body: {
        'message': message,
        'photo_url': photoUrl,
      },
    );
  }

  static Future<ApiResponseData<dynamic>> deleteTicket(int ticketId) async {
    return await ApiClient.delete(ApiEndpoints.ticketDetail(ticketId));
  }

  static Future<String?> uploadTicketPhoto(List<int> bytes, String filename) async {
    try {
      final token = await LocalStorage.getAccessToken();
      final uri = Uri.parse(ApiEndpoints.ticketUploadPhoto);
      final request = http.MultipartRequest('POST', uri);
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      final ext = filename.split('.').last.toLowerCase();
      String mimeType = 'image/jpeg';
      if (ext == 'png') {
        mimeType = 'image/png';
      } else if (ext == 'webp') {
        mimeType = 'image/webp';
      } else if (ext == 'pdf') {
        mimeType = 'application/pdf';
      }

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: filename,
          contentType: MediaType.parse(mimeType),
        ),
      );

      final streamedRes = await request.send();
      final res = await http.Response.fromStream(streamedRes);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final decoded = jsonDecode(res.body);
        if (decoded['success'] == true && decoded['data'] != null) {
          return decoded['data']['file_path'] as String?;
        }
      } else {
        debugPrint('uploadTicketPhoto failed (${res.statusCode}): ${res.body}');
      }
      return null;
    } catch (e) {
      debugPrint('uploadTicketPhoto exception: $e');
      return null;
    }
  }
}

