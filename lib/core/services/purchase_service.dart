import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/purchase_model.dart';
import '../models/batch_model.dart';
import '../models/record_write_result.dart';
import '../utils/firestore_write_helper.dart';

class PurchaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<RecordWriteResult> recordPurchase({
    required String shopId,
    required String supplierId,
    required String supplierName, // ✅ new field
    required double totalAmount,
    required double paidAmount,
    String? paymentMethodId,
    required List<
      ({
        String productId,
        String productName, // ✅ new field
        String batchCode,
        double quantity,
        double costPrice,
        double sellingPrice,
        DateTime? expiryDate,
      })
    >
    items,
  }) async {
    try {
      final batch = _firestore.batch();
      final now = DateTime.now();
      final purchaseRef = _firestore
          .collection('shops')
          .doc(shopId)
          .collection('purchases')
          .doc();
      final purchase = PurchaseModel(
        id: purchaseRef.id,
        shopId: shopId,
        supplierId: supplierId,
        supplierName: supplierName,
        totalAmount: totalAmount,
        paidAmount: paidAmount,
        balance: totalAmount - paidAmount,
        paymentMethodId: paymentMethodId,
        status: paidAmount >= totalAmount ? 'completed' : 'pending',
        createdAt: now,
      );
      batch.set(purchaseRef, purchase.toMap());

      // Update payment method balance (DECREASE by paidAmount)
      if (paidAmount > 0 && paymentMethodId != null) {
        final paymentMethodRef = _firestore
            .collection('shops')
            .doc(shopId)
            .collection('paymentMethods')
            .doc(paymentMethodId);
        batch.update(paymentMethodRef, {
          'currentBalance': FieldValue.increment(-paidAmount),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // For each item, create a batch and update product stock
      for (var item in items) {
        final batchRef = _firestore
            .collection('shops')
            .doc(shopId)
            .collection('products')
            .doc(item.productId)
            .collection('batches')
            .doc();
        final batchModel = BatchModel(
          id: batchRef.id,
          productId: item.productId,
          batchCode: item.batchCode,
          costPrice: item.costPrice,
          sellingPrice: item.sellingPrice,
          quantity: item.quantity,
          expiryDate: item.expiryDate,
          supplierId: supplierId,
          purchaseId: purchaseRef.id,
          createdAt: now,
        );
        batch.set(batchRef, batchModel.toMap());

        // Increment product current stock
        final productRef = _firestore
            .collection('shops')
            .doc(shopId)
            .collection('products')
            .doc(item.productId);
        batch.update(productRef, {
          'currentStock': FieldValue.increment(item.quantity),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Add purchase item document with productName
        final purchaseItemRef = purchaseRef.collection('items').doc();
        final purchaseItem = PurchaseItemModel(
          productId: item.productId,
          productName: item.productName, // ✅ denormalized
          batchId: batchRef.id,
          quantity: item.quantity,
          costPrice: item.costPrice,
          subtotal: item.quantity * item.costPrice,
        );
        batch.set(purchaseItemRef, purchaseItem.toMap());
      }

      // Update supplier balance (increase amount owed to supplier if not fully paid)
      if (purchase.balance > 0) {
        final supplierRef = _firestore
            .collection('shops')
            .doc(shopId)
            .collection('suppliers')
            .doc(supplierId);
        batch.update(supplierRef, {
          'currentBalance': FieldValue.increment(purchase.balance),
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      } else if (paidAmount > totalAmount) {
        final supplierRef = _firestore
            .collection('shops')
            .doc(shopId)
            .collection('suppliers')
            .doc(supplierId);
        batch.update(supplierRef, {
          'currentBalance': FieldValue.increment(-(paidAmount - totalAmount)),
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      }

      return FirestoreWriteHelper.commitBatch(batch);
    } catch (e) {
      debugPrint('Record purchase error: $e');
      return const RecordWriteResult(success: false);
    }
  }

  Stream<List<PurchaseModel>> getPurchases(String shopId) {
    return _firestore
        .collection('shops')
        .doc(shopId)
        .collection('purchases')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PurchaseModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Stream<List<PurchaseModel>> getPurchasesForSupplier(String shopId, String supplierId) {
    return _firestore
        .collection('shops')
        .doc(shopId)
        .collection('purchases')
        .where('supplierId', isEqualTo: supplierId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PurchaseModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }
}
