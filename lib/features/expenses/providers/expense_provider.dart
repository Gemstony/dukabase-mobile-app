import 'package:flutter/material.dart';
import '../../../core/models/record_write_result.dart';
import '../../../core/services/expense_service.dart';
import '../../../core/models/expense_model.dart';

class ExpenseProvider extends ChangeNotifier {
  final ExpenseService _expenseService = ExpenseService();
  List<ExpenseModel> _expenses = [];
  bool _isLoading = false;
  String? _error;

  List<ExpenseModel> get expenses => _expenses;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void loadExpenses(String shopId) {
    _isLoading = true;
    notifyListeners();
    _expenseService.getExpenses(shopId).listen((expenses) {
      _expenses = expenses;
      _isLoading = false;
      _error = null;
      notifyListeners();
    }, onError: (error) {
      _error = error.toString();
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<RecordWriteResult> recordExpense({
    required String shopId,
    required String description,
    required double amount,
    required String category,
    required String paymentMethodId,
    String? referenceNumber,
    String? note,
    required DateTime expenseDate,
    required String createdBy,
  }) async {
    _isLoading = true;
    notifyListeners();
    final result = await _expenseService.recordExpense(
      shopId: shopId,
      description: description,
      amount: amount,
      category: category,
      paymentMethodId: paymentMethodId,
      referenceNumber: referenceNumber,
      note: note,
      expenseDate: expenseDate,
      createdBy: createdBy,
    );
    _isLoading = false;
    if (!result.success) {
      _error = 'Failed to record expense';
      notifyListeners();
    }
    return result;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}