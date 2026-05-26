import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/payment_method_model.dart';
import '../models/record_write_result.dart';
import '../utils/firestore_write_helper.dart';

class PaymentMethodService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream of all payment methods for a shop
  Stream<List<PaymentMethodModel>> getPaymentMethods(String shopId) {
    return _firestore
        .collection('shops')
        .doc(shopId)
        .collection('paymentMethods')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PaymentMethodModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  // Create a new payment method
  Future<RecordWriteResult> createPaymentMethod({
    required String shopId,
    required String name,
    required PaymentMethodType type,
    required double initialBalance,
  }) async {
    try {
      final methodsRef = _firestore
          .collection('shops')
          .doc(shopId)
          .collection('paymentMethods');
      final docRef = methodsRef.doc();
      final now = DateTime.now();
      final method = PaymentMethodModel(
        id: docRef.id,
        shopId: shopId,
        name: name,
        type: type,
        initialBalance: initialBalance,
        currentBalance: initialBalance,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      final batch = _firestore.batch();
      batch.set(docRef, method.toMap());
      return FirestoreWriteHelper.commitBatch(batch);
    } catch (e) {
      debugPrint('Create payment method error: $e');
      return const RecordWriteResult(success: false);
    }
  }

  // Update payment method balance (used by sales, purchases, expenses)
  Future<RecordWriteResult> updateBalance({
    required String shopId,
    required String methodId,
    required double amountChange, // positive = increase, negative = decrease
  }) async {
    try {
      final methodRef = _firestore
          .collection('shops')
          .doc(shopId)
          .collection('paymentMethods')
          .doc(methodId);

      final batch = _firestore.batch();
      batch.update(methodRef, {
        'currentBalance': FieldValue.increment(amountChange),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      return FirestoreWriteHelper.commitBatch(batch);
    } catch (e) {
      debugPrint('Update balance error: $e');
      return const RecordWriteResult(success: false);
    }
  }

  // Delete (soft delete by setting isActive = false)
  Future<RecordWriteResult> deletePaymentMethod(
    String shopId,
    String methodId,
  ) async {
    try {
      final methodRef = _firestore
          .collection('shops')
          .doc(shopId)
          .collection('paymentMethods')
          .doc(methodId);

      final batch = _firestore.batch();
      batch.update(methodRef, {
        'isActive': false,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      return FirestoreWriteHelper.commitBatch(batch);
    } catch (e) {
      debugPrint('Delete payment method error: $e');
      return const RecordWriteResult(success: false);
    }
  }

  // Update payment method name and type
  Future<RecordWriteResult> updatePaymentMethod({
    required String shopId,
    required String methodId,
    required String name,
    required PaymentMethodType type,
  }) async {
    try {
      final methodRef = _firestore
          .collection('shops')
          .doc(shopId)
          .collection('paymentMethods')
          .doc(methodId);

      final batch = _firestore.batch();
      batch.update(methodRef, {
        'name': name,
        'type': type.name,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      return FirestoreWriteHelper.commitBatch(batch);
    } catch (e) {
      debugPrint('Update payment method error: $e');
      return const RecordWriteResult(success: false);
    }
  }

  // Get sales for this payment method (paginated, 20 at a time)
  Stream<QuerySnapshot> getSalesForMethod(
    String shopId,
    String methodId, {
    int limit = 20,
  }) {
    return _firestore
        .collection('shops')
        .doc(shopId)
        .collection('sales')
        .where('paymentMethodId', isEqualTo: methodId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots();
  }

  // Get purchases for this payment method (paginated, 20 at a time)
  Stream<QuerySnapshot> getPurchasesForMethod(
    String shopId,
    String methodId, {
    int limit = 20,
  }) {
    return _firestore
        .collection('shops')
        .doc(shopId)
        .collection('purchases')
        .where('paymentMethodId', isEqualTo: methodId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots();
  }

  // Get expenses for this payment method (paginated, 20 at a time)
  Stream<QuerySnapshot> getExpensesForMethod(
    String shopId,
    String methodId, {
    int limit = 20,
  }) {
    return _firestore
        .collection('shops')
        .doc(shopId)
        .collection('expenses')
        .where('paymentMethodId', isEqualTo: methodId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots();
  }
}
