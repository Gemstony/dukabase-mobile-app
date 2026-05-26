import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/expense_model.dart';
import '../models/record_write_result.dart';
import '../utils/firestore_write_helper.dart';
import 'payment_method_service.dart';

class ExpenseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PaymentMethodService _paymentMethodService = PaymentMethodService();

  /// Record an expense, automatically deduct from payment method balance.
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
    try {
      // Use a batch to ensure atomicity
      final batch = _firestore.batch();

      // 1. Create expense document
      final expenseRef = _firestore
          .collection('shops')
          .doc(shopId)
          .collection('expenses')
          .doc();
      final expense = ExpenseModel(
        id: expenseRef.id,
        shopId: shopId,
        description: description,
        amount: amount,
        category: category,
        paymentMethodId: paymentMethodId,
        referenceNumber: referenceNumber,
        note: note,
        expenseDate: expenseDate,
        createdAt: DateTime.now(),
        createdBy: createdBy,
      );
      batch.set(expenseRef, expense.toMap());

      // 2. Deduct amount from payment method balance
      final paymentMethodRef = _firestore
          .collection('shops')
          .doc(shopId)
          .collection('paymentMethods')
          .doc(paymentMethodId);
      batch.update(paymentMethodRef, {
        'currentBalance': FieldValue.increment(-amount),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      return FirestoreWriteHelper.commitBatch(batch);
    } catch (e) {
      debugPrint('Record expense error: $e');
      return const RecordWriteResult(success: false);
    }
  }

  /// Stream of all expenses for a shop (ordered by date descending)
  Stream<List<ExpenseModel>> getExpenses(String shopId) {
    return _firestore
        .collection('shops')
        .doc(shopId)
        .collection('expenses')
        .orderBy('expenseDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ExpenseModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// Stream of expenses filtered by category
  Stream<List<ExpenseModel>> getExpensesByCategory(String shopId, String category) {
    return _firestore
        .collection('shops')
        .doc(shopId)
        .collection('expenses')
        .where('category', isEqualTo: category)
        .orderBy('expenseDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ExpenseModel.fromMap(doc.id, doc.data()))
            .toList());
  }
}