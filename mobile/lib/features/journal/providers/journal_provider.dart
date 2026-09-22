import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../models/journal_model.dart';

class JournalProvider extends ChangeNotifier {
  List<JournalModel> _journals = [];
  JournalModel? _activeJournal;
  bool _isLoading = false;
  String? _errorMessage;

  List<JournalModel> get journals => _journals;
  JournalModel? get activeJournal => _activeJournal;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchJournals() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await ApiClient.get(ApiEndpoints.journals);
    _isLoading = false;

    if (response.success && response.data != null) {
      final list = response.data as List;
      _journals = list.map((item) => JournalModel.fromJson(item)).toList();
      if (_journals.isNotEmpty) {
        // Select urgent revision journal if available, else first
        _activeJournal = _journals.firstWhere(
          (j) => j.isUrgentRevision,
          orElse: () => _journals.first,
        );
      }
    } else {
      _errorMessage = response.error;
    }
    notifyListeners();
  }

  Future<Map<String, dynamic>?> analyzeAiText(String text) async {
    final response = await ApiClient.post(
      ApiEndpoints.analyzeAi,
      body: {'text': text},
    );
    if (response.success && response.data != null) {
      return response.data as Map<String, dynamic>;
    }
    return null;
  }

  Future<bool> createJournal({
    required String workSummary,
    double hoursSpent = 8.5,
    int workflowStage = 2,
    PlatformFile? photoFile,
  }) async {
    _isLoading = true;
    notifyListeners();

    final response = await ApiClient.post(
      ApiEndpoints.journals,
      body: {
        'work_summary': workSummary,
        'hours_spent': hoursSpent,
        'workflow_stage': workflowStage,
      },
    );

    if (response.success && response.data != null) {
      final createdJournalId = response.data['id'] as int?;
      if (photoFile != null && createdJournalId != null) {
        // Upload attached photo linked to this journal
        await ApiClient.upload(
          '${ApiEndpoints.baseUrl}/upload',
          photoFile,
          fields: {'journal_id': createdJournalId.toString()},
        );
      }
      await fetchJournals();
      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _isLoading = false;
      _errorMessage = response.error ?? 'Gagal menyimpan jurnal.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateJournal({
    required int journalId,
    required String workSummary,
    int? workflowStage,
    String? status,
    PlatformFile? photoFile,
  }) async {
    _isLoading = true;
    notifyListeners();

    final response = await ApiClient.patch(
      ApiEndpoints.journalDetail(journalId),
      body: {
        'work_summary': workSummary,
        if (workflowStage != null) 'workflow_stage': workflowStage,
        if (status != null) 'status': status,
      },
    );

    if (response.success) {
      if (photoFile != null) {
        await ApiClient.upload(
          '${ApiEndpoints.baseUrl}/upload',
          photoFile,
          fields: {'journal_id': journalId.toString()},
        );
      }
      await fetchJournals();
      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _isLoading = false;
      _errorMessage = response.error ?? 'Gagal memperbarui jurnal.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> reviewJournal({
    required int journalId,
    required String status,
    String? notes,
  }) async {
    _isLoading = true;
    notifyListeners();

    final response = await ApiClient.post(
      '${ApiEndpoints.journals}/$journalId/review',
      body: {
        'status': status,
        'approved': status == 'APPROVED' || status == 'REVIEWED',
        if (notes != null) 'notes': notes,
      },
    );

    _isLoading = false;
    if (response.success) {
      await fetchJournals();
      return true;
    } else {
      _errorMessage = response.error ?? 'Gagal memproses validasi jurnal.';
      notifyListeners();
      return false;
    }
  }

  Future<List<JournalHistoryModel>> fetchJournalHistory(int journalId) async {
    final response = await ApiClient.get('${ApiEndpoints.journals}/$journalId/history');
    if (response.success && response.data != null) {
      final list = response.data as List;
      return list.map((item) => JournalHistoryModel.fromJson(item)).toList();
    }
    return [];
  }

  void selectJournal(JournalModel journal) {
    _activeJournal = journal;
    notifyListeners();
  }

  Future<bool> deleteJournal(int journalId) async {
    _isLoading = true;
    notifyListeners();
    final response = await ApiClient.delete('${ApiEndpoints.journals}/$journalId');
    _isLoading = false;
    if (response.success) {
      _journals.removeWhere((j) => j.id == journalId);
      if (_activeJournal?.id == journalId) {
        _activeJournal = _journals.isNotEmpty ? _journals.first : null;
      }
      notifyListeners();
      return true;
    } else {
      _errorMessage = response.error ?? 'Gagal menghapus jurnal.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> clearAllJournals() async {
    _isLoading = true;
    notifyListeners();
    final response = await ApiClient.delete('${ApiEndpoints.journals}/clear-all');
    _isLoading = false;
    if (response.success) {
      _journals.clear();
      _activeJournal = null;
      notifyListeners();
      return true;
    } else {
      _errorMessage = response.error ?? 'Gagal menghapus seluruh jurnal.';
      notifyListeners();
      return false;
    }
  }
}
