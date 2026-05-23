import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment_method_model.dart';

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
        .map((snapshot) => snapshot.docs
            .map((doc) => PaymentMethodModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  // Create a new payment method
  Future<PaymentMethodModel?> createPaymentMethod({
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
      await docRef.set(method.toMap());
      return method;
    } catch (e) {
      print('Create payment method error: $e');
      return null;
    }
  }

  // Update payment method balance (used by sales, purchases, expenses)
  Future<bool> updateBalance({
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
      await methodRef.update({
        'currentBalance': FieldValue.increment(amountChange),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Update balance error: $e');
      return false;
    }
  }

  // Delete (soft delete by setting isActive = false)
  Future<bool> deletePaymentMethod(String shopId, String methodId) async {
    try {
      final methodRef = _firestore
          .collection('shops')
          .doc(shopId)
          .collection('paymentMethods')
          .doc(methodId);
      await methodRef.update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Delete payment method error: $e');
      return false;
    }
  }
}