import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/report_service.dart';
import '../../../core/models/report_models.dart';

class ExpenseReportProvider extends ChangeNotifier {
  final ReportService _service = ReportService();
  
  List<ExpenseCategoryItem> _categorySummary = [];
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _expensesHistory = [];
  DocumentSnapshot? _lastHistoryDoc;
  bool _hasMoreHistory = true;
  bool _isLoadingCategory = false;
  bool _isLoadingHistory = false;
  String? _error;

  List<ExpenseCategoryItem> get categorySummary => _categorySummary;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> get expensesHistory => _expensesHistory;
  bool get hasMoreHistory => _hasMoreHistory;
  bool get isLoadingCategory => _isLoadingCategory;
  bool get isLoadingHistory => _isLoadingHistory;
  String? get error => _error;

  Future<void> loadCategorySummary(String shopId, DateTime start, DateTime end) async {
    _isLoadingCategory = true;
    _error = null;
    notifyListeners();
    try {
      _categorySummary = await _service.getExpensesByCategory(shopId, start, end);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingCategory = false;
      notifyListeners();
    }
  }

  Future<void> loadExpensesHistory(String shopId, {bool refresh = false}) async {
    if (_isLoadingHistory) return;
    if (refresh) {
      _expensesHistory.clear();
      _lastHistoryDoc = null;
      _hasMoreHistory = true;
    }
    if (!_hasMoreHistory) return;
    _isLoadingHistory = true;
    notifyListeners();
    try {
      final snapshot = await _service.getExpensesHistory(shopId, limit: 20, lastDocument: _lastHistoryDoc).first;
      _hasMoreHistory = snapshot.docs.length == 20;
      if (refresh) {
        _expensesHistory = snapshot.docs;
      } else {
        _expensesHistory.addAll(snapshot.docs);
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