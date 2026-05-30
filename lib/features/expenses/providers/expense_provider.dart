import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../core/models/record_write_result.dart';
import '../../../core/services/expense_service.dart';
import '../../../core/models/expense_model.dart';

class ExpenseProvider extends ChangeNotifier {
  final ExpenseService _expenseService = ExpenseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<ExpenseModel> _expenses = [];
  bool _isLoading = false;
  String? _error;

  final Map<String, String> _paymentMethodNames = {};
  final Map<String, String> _creatorNames = {};

  List<ExpenseModel> get expenses => _expenses;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, String> get paymentMethodNames => _paymentMethodNames;
  Map<String, String> get creatorNames => _creatorNames;

  Future<void> _loadPaymentMethodName(
    String shopId,
    String paymentMethodId,
  ) async {
    if (_paymentMethodNames.containsKey(paymentMethodId)) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('shops')
          .doc(shopId)
          .collection('paymentMethods')
          .doc(paymentMethodId)
          .get();
      if (doc.exists) {
        _paymentMethodNames[paymentMethodId] =
            doc.data()?['name'] as String? ?? paymentMethodId;
      } else {
        _paymentMethodNames[paymentMethodId] = paymentMethodId;
      }
    } catch (_) {
      _paymentMethodNames[paymentMethodId] = paymentMethodId;
    }
  }

  Future<void> _loadCreatorName(String userId) async {
    if (_creatorNames.containsKey(userId)) return;
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        _creatorNames[userId] = doc.data()?['name'] as String? ?? userId;
      } else {
        _creatorNames[userId] = userId;
      }
    } catch (_) {
      _creatorNames[userId] = userId;
    }
  }

  void loadExpenses(String shopId) {
    _isLoading = true;
    notifyListeners();
    _expenseService
        .getExpenses(shopId)
        .listen(
          (expenses) {
            _expenses = expenses;
            // Load names in background
            for (final e in expenses) {
              _loadPaymentMethodName(shopId, e.paymentMethodId);
              _loadCreatorName(e.createdBy);
            }
            _isLoading = false;
            _error = null;
            notifyListeners();
          },
          onError: (error) {
            _error = error.toString();
            _isLoading = false;
            notifyListeners();
          },
        );
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
