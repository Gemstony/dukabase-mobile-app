import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/record_write_result.dart';
import '../models/stock_adjustment_model.dart';
import '../utils/firestore_write_helper.dart';

class StockAdjustmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Record a stock adjustment (atomic batch write)
  Future<RecordWriteResult> recordAdjustment({
    required String shopId,
    required String productId,
    required String batchId,
    required String reason,
    required double quantityChange,
    String? note,
    required String createdBy,
  }) async {
    try {
      final batch = _firestore.batch();

      // 1. Create adjustment document
      final adjustmentRef = _firestore
          .collection('shops')
          .doc(shopId)
          .collection('stockAdjustments')
          .doc();
      final adjustment = StockAdjustmentModel(
        id: adjustmentRef.id,
        shopId: shopId,
        productId: productId,
        batchId: batchId,
        reason: reason,
        quantityChange: quantityChange,
        note: note,
        createdAt: DateTime.now(),
        createdBy: createdBy,
      );
      batch.set(adjustmentRef, adjustment.toMap());

      // 2. Update batch quantity
      final batchRef = _firestore
          .collection('shops')
          .doc(shopId)
          .collection('products')
          .doc(productId)
          .collection('batches')
          .doc(batchId);
      batch.update(batchRef, {
        'quantity': FieldValue.increment(quantityChange),
      });

      // 3. Update product current stock
      final productRef = _firestore
          .collection('shops')
          .doc(shopId)
          .collection('products')
          .doc(productId);
      batch.update(productRef, {
        'currentStock': FieldValue.increment(quantityChange),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      return FirestoreWriteHelper.commitBatch(batch);
    } catch (e) {
      debugPrint('Record stock adjustment error: $e');
      return const RecordWriteResult(success: false);
    }
  }

  /// Stream of all stock adjustments for a shop (ordered newest first)
  Stream<List<StockAdjustmentModel>> getAdjustments(String shopId) {
    return _firestore
        .collection('shops')
        .doc(shopId)
        .collection('stockAdjustments')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => StockAdjustmentModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }
}
