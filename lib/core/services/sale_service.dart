import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/record_write_result.dart';
import '../models/sale_model.dart';
import '../utils/firestore_write_helper.dart';

class SaleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<RecordWriteResult> recordSale({
    required String shopId,
    required String? customerId,
    required String paymentMethodId,
    required double paidAmount,
    required List<
      ({
        String batchId,
        String productId,
        String productName, // ✅ new field
        double quantity,
        double sellingPrice,
      })
    >
    items,
  }) async {
    try {
      final batch = _firestore.batch();
      final now = DateTime.now();
      final totalAmount = items.fold(
        0.0,
        (sum, i) => sum + (i.quantity * i.sellingPrice),
      );
      final change = paidAmount - totalAmount;
      final status = paidAmount >= totalAmount ? 'completed' : 'pending';

      // Create sale document
      final saleRef = _firestore
          .collection('shops')
          .doc(shopId)
          .collection('sales')
          .doc();
      final sale = SaleModel(
        id: saleRef.id,
        shopId: shopId,
        customerId: customerId,
        paymentMethodId: paymentMethodId,
        totalAmount: totalAmount,
        paidAmount: paidAmount,
        change: change > 0 ? change : 0,
        status: status,
        createdAt: now,
      );
      batch.set(saleRef, sale.toMap());

      // Update payment method balance (INCREASE by paidAmount)
      final paymentMethodRef = _firestore
          .collection('shops')
          .doc(shopId)
          .collection('paymentMethods')
          .doc(paymentMethodId);
      batch.update(paymentMethodRef, {
        'currentBalance': FieldValue.increment(paidAmount),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // For each item, reduce batch quantity and update product stock
      for (var item in items) {
        // Reduce batch quantity
        final batchRef = _firestore
            .collection('shops')
            .doc(shopId)
            .collection('products')
            .doc(item.productId)
            .collection('batches')
            .doc(item.batchId);
        batch.update(batchRef, {
          'quantity': FieldValue.increment(-item.quantity),
        });

        // Reduce product current stock
        final productRef = _firestore
            .collection('shops')
            .doc(shopId)
            .collection('products')
            .doc(item.productId);
        batch.update(productRef, {
          'currentStock': FieldValue.increment(-item.quantity),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Add sale item document with productName
        final saleItemRef = saleRef.collection('items').doc();
        final saleItem = SaleItemModel(
          productId: item.productId,
          productName: item.productName, // ✅ denormalized
          batchId: item.batchId,
          quantity: item.quantity,
          sellingPrice: item.sellingPrice,
          subtotal: item.quantity * item.sellingPrice,
        );
        batch.set(saleItemRef, saleItem.toMap());
      }

      // If customer is selected and sale is credit (pending), increase customer balance
      if (customerId != null && status == 'pending') {
        final customerRef = _firestore
            .collection('shops')
            .doc(shopId)
            .collection('customers')
            .doc(customerId);
        batch.update(customerRef, {
          'currentBalance': FieldValue.increment(totalAmount - paidAmount),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      return FirestoreWriteHelper.commitBatch(batch);
    } catch (e) {
      debugPrint('Record sale error: $e');
      return const RecordWriteResult(success: false);
    }
  }

  Stream<List<SaleModel>> getSales(String shopId) {
    return _firestore
        .collection('shops')
        .doc(shopId)
        .collection('sales')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => SaleModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Stream<List<SaleModel>> getTodaySales(String shopId) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    return _firestore
        .collection('shops')
        .doc(shopId)
        .collection('sales')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => SaleModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Stream<List<SaleModel>> getSalesForCustomer(
    String shopId,
    String customerId,
  ) {
    return _firestore
        .collection('shops')
        .doc(shopId)
        .collection('sales')
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => SaleModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }
}
