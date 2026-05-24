import 'package:flutter/material.dart';
import '../../../core/services/report_service.dart';
import '../../../core/models/report_models.dart';

class IncomeReportProvider extends ChangeNotifier {
  final ReportService _service = ReportService();
  IncomeSummary? _summary;
  bool _isLoading = false;
  String? _error;

  IncomeSummary? get summary => _summary;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadIncomeSummary(String shopId, DateTime start, DateTime end) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _summary = await _service.getIncomeSummary(shopId, start, end);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}