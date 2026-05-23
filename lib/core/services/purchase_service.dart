import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/purchase_model.dart';
import '../models/batch_model.dart';
import 'product_service.dart';

class PurchaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ProductService _productService = ProductService();

  // Record a purchase with multiple batches
  Future<bool> recordPurchase({
    required String shopId,
    required String supplierId,
    required double totalAmount,
    required double paidAmount,
    String? paymentMethodId,
    required List<({
      String productId,
      String batchCode,
      double quantity,
      double costPrice,
      double sellingPrice,
      DateTime? expiryDate,
    })> items,
  }) async {
    try {
      // Use a batch write to ensure atomicity
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
        totalAmount: totalAmount,
        paidAmount: paidAmount,
        balance: totalAmount - paidAmount,
        paymentMethodId: paymentMethodId,
        status: paidAmount >= totalAmount ? 'completed' : 'pending',
        createdAt: now,
      );
      batch.set(purchaseRef, purchase.toMap());

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

        // Add purchase item document
        final purchaseItemRef = purchaseRef
            .collection('items')
            .doc();
        final purchaseItem = PurchaseItemModel(
          productId: item.productId,
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
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else if (paidAmount > totalAmount) {
        // Overpayment decreases balance
        final supplierRef = _firestore
            .collection('shops')
            .doc(shopId)
            .collection('suppliers')
            .doc(supplierId);
        batch.update(supplierRef, {
          'currentBalance': FieldValue.increment(-(paidAmount - totalAmount)),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      return true;
    } catch (e) {
      print('Record purchase error: $e');
      return false;
    }
  }

  Stream<List<PurchaseModel>> getPurchases(String shopId) {
    return _firestore
        .collection('shops')
        .doc(shopId)
        .collection('purchases')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PurchaseModel.fromMap(doc.id, doc.data()))
            .toList());
  }
}