import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment_model.dart';

class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Record a payment from a customer, reducing their currentBalance.
  Future<bool> recordPayment({
    required String shopId,
    required String customerId,
    required double amount,
    required String paymentMethodId,
    String? saleId,
    String note = '',
  }) async {
    try {
      final batch = _firestore.batch();
      final now = DateTime.now();

      // Create payment document
      final paymentRef = _firestore
          .collection('shops')
          .doc(shopId)
          .collection('customers')
          .doc(customerId)
          .collection('payments')
          .doc();
      final payment = PaymentModel(
        id: paymentRef.id,
        shopId: shopId,
        customerId: customerId,
        amount: amount,
        paymentMethodId: paymentMethodId,
        saleId: saleId,
        note: note,
        createdAt: now,
      );
      batch.set(paymentRef, payment.toMap());

      // Reduce customer's current balance (positive = customer owes you)
      final customerRef = _firestore
          .collection('shops')
          .doc(shopId)
          .collection('customers')
          .doc(customerId);
      batch.update(customerRef, {
        'currentBalance': FieldValue.increment(-amount),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      return true;
    } catch (e) {
      print('Record payment error: $e');
      return false;
    }
  }

  /// Stream of payments for a customer
  Stream<List<PaymentModel>> getCustomerPayments(String shopId, String customerId) {
    return _firestore
        .collection('shops')
        .doc(shopId)
        .collection('customers')
        .doc(customerId)
        .collection('payments')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PaymentModel.fromMap(doc.id, doc.data()))
            .toList());
  }
}