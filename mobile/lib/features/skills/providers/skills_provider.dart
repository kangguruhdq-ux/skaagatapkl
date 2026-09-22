import 'package:flutter/material.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../models/skill_model.dart';

class SkillsProvider extends ChangeNotifier {
  IndustryGapSummaryModel? _summary;
  bool _isLoading = false;
  String? _errorMessage;

  IndustryGapSummaryModel? get summary => _summary;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchGapAnalysis() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await ApiClient.get(ApiEndpoints.skillGapAnalysis);
    _isLoading = false;

    if (response.success && response.data != null) {
      _summary = IndustryGapSummaryModel.fromJson(
          response.data as Map<String, dynamic>);
    } else {
      _errorMessage = response.error;
    }
    notifyListeners();
  }
}
