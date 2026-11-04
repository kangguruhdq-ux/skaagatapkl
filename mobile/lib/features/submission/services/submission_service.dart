import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../models/submission_model.dart';

class SubmissionService {
  static Future<List<PklSubmissionModel>> getSubmissions({
    int? studentId,
    String? status,
  }) async {
    try {
      String url = ApiEndpoints.submissions;
      final params = <String>[];
      if (studentId != null) params.add('student_id=$studentId');
      if (status != null && status.isNotEmpty) params.add('status=$status');
      if (params.isNotEmpty) url += '?${params.join('&')}';

      final res = await ApiClient.get(url);
      if (res.success && res.data != null) {
        List items = [];
        if (res.data is List) {
          items = res.data as List;
        } else if (res.data is Map && res.data['items'] is List) {
          items = res.data['items'] as List;
        }
        return items.map((item) => PklSubmissionModel.fromJson(item)).toList();
      }
    } catch (_) {}
    return [];
  }


  static Future<ApiResponseData<dynamic>> createSubmission({
    required int companyId,
    String? proposalLetterUrl,
  }) async {
    return await ApiClient.post(
      ApiEndpoints.submissions,
      body: {
        'company_id': companyId,
        'proposal_letter_url': proposalLetterUrl ??
            'https://storage.smkn3jogja.sch.id/proposals/surat_permohonan_pkl.pdf',
      },
    );
  }

  static Future<ApiResponseData<dynamic>> requestChange({
    int? submissionId,
    required int targetCompanyId,
    required String changeReason,
    String? newCompanyName,
    String? newAddress,
  }) async {
    final subId = (submissionId != null && submissionId > 0) ? submissionId : 0;
    return await ApiClient.post(
      '${ApiEndpoints.submissions}/$subId/request-change',
      body: {
        'target_company_id': targetCompanyId,
        'change_reason': changeReason,
        if (newCompanyName != null) 'new_company_name': newCompanyName,
        if (newAddress != null) 'new_address': newAddress,
      },
    );
  }

  static Future<ApiResponseData<dynamic>> reviewSubmission({
    required int submissionId,
    required String status,
    String? supervisorNotes,
  }) async {
    final action = (status == 'APPROVED' || status == 'APPROVE')
        ? 'APPROVE'
        : (status == 'REJECTED' || status == 'REJECT' ? 'REJECT' : 'REVISION');
    return await ApiClient.patch(
      '${ApiEndpoints.submissions}/$submissionId/review',
      body: {
        'action': action,
        'status': status,
        'notes': supervisorNotes,
        'supervisor_notes': supervisorNotes,
      },
    );
  }

  static Future<List<PklEvidenceModel>> getEvidences({
    int? studentId,
    String? category,
    String? status,
  }) async {
    try {
      String url = ApiEndpoints.evidences;
      final params = <String>[];
      if (studentId != null) params.add('student_id=$studentId');
      if (category != null && category.isNotEmpty)
        params.add('category=$category');
      if (status != null && status.isNotEmpty) params.add('status=$status');
      if (params.isNotEmpty) url += '?${params.join('&')}';

      final res = await ApiClient.get(url);
      if (res.success && res.data != null) {
        List items = [];
        if (res.data is List) {
          items = res.data as List;
        } else if (res.data is Map && res.data['items'] is List) {
          items = res.data['items'] as List;
        }
        return items.map((item) => PklEvidenceModel.fromJson(item)).toList();
      }
    } catch (_) {}
    return [];
  }


  static Future<ApiResponseData<dynamic>> uploadEvidence({
    required String title,
    required String category,
    String? description,
    required String fileUrl,
  }) async {
    return await ApiClient.post(
      ApiEndpoints.evidences,
      body: {
        'title': title,
        'category': category,
        'description': description,
        'file_url': fileUrl,
      },
    );
  }

  static Future<ApiResponseData<dynamic>> verifyEvidence({
    required int evidenceId,
    required String status,
    String? reviewNotes,
  }) async {
    final action = status == 'VERIFIED'
        ? 'VERIFY'
        : (status == 'REJECTED' ? 'REJECT' : 'REVISION');
    return await ApiClient.patch(
      '${ApiEndpoints.evidences}/$evidenceId/verify',
      body: {
        'action': action,
        'status': status,
        'notes': reviewNotes,
        'review_notes': reviewNotes,
      },
    );
  }

  static Future<List<Map<String, dynamic>>> getCompanies() async {
    final res = await ApiClient.get(ApiEndpoints.adminCompanies);
    if (res.success && res.data != null) {
      List rawList = [];
      if (res.data is List) {
        rawList = res.data as List;
      } else if (res.data is Map && res.data['items'] is List) {
        rawList = res.data['items'] as List;
      }
      return rawList.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return [];
  }

  static Future<ApiResponseData<dynamic>> deleteEvidence(int evidenceId) async {
    return await ApiClient.delete('${ApiEndpoints.evidences}/$evidenceId');
  }

  static Future<ApiResponseData<dynamic>> proposeCompany({
    required String name,
    required String address,
    String? division,
    String? mentorName,
    String? mentorPhone,
    String? notes,
  }) async {
    return await ApiClient.post(
      '${ApiEndpoints.baseUrl}/placements/propose',
      body: {
        'name': name,
        'address': address,
        'division': division ?? 'Divisi Operasional',
        'mentor_name': mentorName,
        'mentor_phone': mentorPhone,
        'notes': notes,
      },
    );
  }

  static Future<List<Map<String, dynamic>>> getCompanyProposals() async {
    final res = await ApiClient.get('${ApiEndpoints.baseUrl}/placements/proposals');
    if (res.success && res.data != null && res.data is List) {
      return (res.data as List).map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return [];
  }

  static Future<ApiResponseData<dynamic>> approveCompanyProposal(int companyId) async {
    return await ApiClient.post('${ApiEndpoints.baseUrl}/placements/$companyId/approve');
  }

  static Future<ApiResponseData<dynamic>> rejectCompanyProposal(int companyId) async {
    return await ApiClient.post('${ApiEndpoints.baseUrl}/placements/$companyId/reject');
  }

  static Future<ApiResponseData<dynamic>> deleteSubmission(int submissionId) async {
    return await ApiClient.delete('${ApiEndpoints.submissions}/$submissionId');
  }
}
