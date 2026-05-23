import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import '../../../core/services/dashboard_service.dart';
import '../../../core/models/dashboard_data.dart';

class DashboardProvider extends ChangeNotifier {
  final DashboardService _service = DashboardService();
  DashboardData? _data;
  bool _isLoading = true;
  String? _error;

  DashboardData? get data => _data;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void loadDashboard(String shopId) {
    _isLoading = true;
    notifyListeners();
    _service.getDashboardData(shopId).listen((dashboardData) {
      _data = dashboardData;
      _isLoading = false;
      _error = null;
      notifyListeners();
    }, onError: (error) {
      _error = error.toString();
      _isLoading = false;
      notifyListeners();
    });
  }
}