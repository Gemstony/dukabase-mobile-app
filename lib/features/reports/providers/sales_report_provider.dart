import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/report_service.dart';
import '../../../core/models/report_models.dart';

class SalesReportProvider extends ChangeNotifier {
  final ReportService _service = ReportService();
  
  List<SalesReportItem> _dailyReport = [];
  List<TopProductItem> _topProducts = [];
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _salesHistory = [];
  DocumentSnapshot? _lastHistoryDoc;
  bool _hasMoreHistory = true;
  bool _isLoadingDaily = false;
  bool _isLoadingTop = false;
  bool _isLoadingHistory = false;
  String? _error;

  List<SalesReportItem> get dailyReport => _dailyReport;
  List<TopProductItem> get topProducts => _topProducts;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> get salesHistory => _salesHistory;
  bool get hasMoreHistory => _hasMoreHistory;
  bool get isLoadingDaily => _isLoadingDaily;
  bool get isLoadingTop => _isLoadingTop;
  bool get isLoadingHistory => _isLoadingHistory;
  String? get error => _error;

  Future<void> loadDailyReport(String shopId, DateTime start, DateTime end) async {
    _isLoadingDaily = true;
    _error = null;
    notifyListeners();
    try {
      _dailyReport = await _service.getDailySalesReport(shopId, start, end);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingDaily = false;
      notifyListeners();
    }
  }

  Future<void> loadTopProducts(String shopId, DateTime start, DateTime end) async {
    _isLoadingTop = true;
    notifyListeners();
    try {
      _topProducts = await _service.getTopSellingProducts(shopId, start, end);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingTop = false;
      notifyListeners();
    }
  }

  Future<void> loadSalesHistory(String shopId, {bool refresh = false}) async {
    if (_isLoadingHistory) return;
    if (refresh) {
      _salesHistory.clear();
      _lastHistoryDoc = null;
      _hasMoreHistory = true;
    }
    if (!_hasMoreHistory) return;
    _isLoadingHistory = true;
    notifyListeners();
    try {
      final snapshot = await _service.getSalesHistory(shopId, limit: 20, lastDocument: _lastHistoryDoc).first;
      _hasMoreHistory = snapshot.docs.length == 20;
      if (refresh) {
        _salesHistory = snapshot.docs;
      } else {
        _salesHistory.addAll(snapshot.docs);
      }
      _lastHistoryDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}