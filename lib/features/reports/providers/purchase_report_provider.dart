import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/report_service.dart';
import '../../../core/models/report_models.dart';

class PurchaseReportProvider extends ChangeNotifier {
  final ReportService _service = ReportService();
  
  List<PurchaseReportItem> _dailyReport = [];
  List<TopProductItem> _topProducts = [];
  List<({String supplierId, String supplierName, double totalAmount})> _supplierSummary = [];
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _purchaseHistory = [];
  DocumentSnapshot? _lastHistoryDoc;
  bool _hasMoreHistory = true;
  bool _isLoadingDaily = false;
  bool _isLoadingTop = false;
  bool _isLoadingSuppliers = false;
  bool _isLoadingHistory = false;
  String? _error;

  List<PurchaseReportItem> get dailyReport => _dailyReport;
  List<TopProductItem> get topProducts => _topProducts;
  List get supplierSummary => _supplierSummary;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> get purchaseHistory => _purchaseHistory;
  bool get hasMoreHistory => _hasMoreHistory;
  bool get isLoadingDaily => _isLoadingDaily;
  bool get isLoadingTop => _isLoadingTop;
  bool get isLoadingSuppliers => _isLoadingSuppliers;
  bool get isLoadingHistory => _isLoadingHistory;
  String? get error => _error;

  Future<void> loadDailyReport(String shopId, DateTime start, DateTime end) async {
    _isLoadingDaily = true;
    _error = null;
    notifyListeners();
    try {
      _dailyReport = await _service.getDailyPurchaseReport(shopId, start, end);
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
      _topProducts = await _service.getTopPurchasedProducts(shopId, start, end);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingTop = false;
      notifyListeners();
    }
  }

  Future<void> loadSupplierSummary(String shopId, DateTime start, DateTime end) async {
    _isLoadingSuppliers = true;
    notifyListeners();
    try {
      _supplierSummary = await _service.getSupplierPurchaseSummary(shopId, start, end);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingSuppliers = false;
      notifyListeners();
    }
  }

  Future<void> loadPurchaseHistory(String shopId, {bool refresh = false}) async {
    if (_isLoadingHistory) return;
    if (refresh) {
      _purchaseHistory.clear();
      _lastHistoryDoc = null;
      _hasMoreHistory = true;
    }
    if (!_hasMoreHistory) return;
    _isLoadingHistory = true;
    notifyListeners();
    try {
      final snapshot = await _service.getPurchaseHistory(shopId, limit: 20, lastDocument: _lastHistoryDoc).first;
      _hasMoreHistory = snapshot.docs.length == 20;
      if (refresh) {
        _purchaseHistory = snapshot.docs;
      } else {
        _purchaseHistory.addAll(snapshot.docs);
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