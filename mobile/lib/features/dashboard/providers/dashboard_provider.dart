import 'package:flutter/material.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../models/dashboard_model.dart';

class DashboardProvider extends ChangeNotifier {
  DashboardModel? _dashboardData;
  bool _isLoading = false;
  String? _errorMessage;

  DashboardModel? get dashboardData => _dashboardData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchDashboardData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await ApiClient.get(ApiEndpoints.dashboardSummary);

    _isLoading = false;
    if (response.success && response.data != null) {
      _dashboardData =
          DashboardModel.fromJson(response.data as Map<String, dynamic>);
      _errorMessage = null;
    } else {
      _errorMessage = response.error ?? 'Gagal memuat data Dashboard.';
    }
    notifyListeners();
  }
}
