import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/product_model.dart';
import '../models/batch_model.dart';
import '../models/record_write_result.dart';
import '../utils/firestore_read_helper.dart';
import '../utils/firestore_write_helper.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream of all products in a shop (with real‑time updates)
  Stream<List<ProductModel>> getProducts(String shopId) {
    return _firestore
        .collection('shops')
        .doc(shopId)
        .collection('products')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ProductModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  // Create a new product
  Future<RecordWriteResult> createProduct({
    required String shopId,
    required String name,
    required String sku,
    required String unit,
    required double defaultSellingPrice,
    required double lowStockAlert,
  }) async {
    try {
      final productsRef = _firestore
          .collection('shops')
          .doc(shopId)
          .collection('products');
      final docRef = productsRef.doc();
      final now = DateTime.now();
      final product = ProductModel(
        id: docRef.id,
        shopId: shopId,
        name: name,
        sku: sku,
        unit: unit,
        defaultSellingPrice: defaultSellingPrice,
        currentStock: 0,
        lowStockAlert: lowStockAlert,
        createdAt: now,
        updatedAt: now,
      );

      final batch = _firestore.batch();
      batch.set(docRef, product.toMap());
      return FirestoreWriteHelper.commitBatch(batch);
    } catch (e) {
      debugPrint('Create product error: $e');
      return const RecordWriteResult(success: false);
    }
  }

  // Add a batch to a product (used when purchasing)
  Future<RecordWriteResult> addBatch({
    required String shopId,
    required String productId,
    required String batchCode,
    required double costPrice,
    required double sellingPrice,
    required double quantity,
    DateTime? expiryDate,
    required String supplierId,
    required String purchaseId,
  }) async {
    try {
      final batchRef = _firestore
          .collection('shops')
          .doc(shopId)
          .collection('products')
          .doc(productId)
          .collection('batches')
          .doc();
      final batchModel = BatchModel(
        id: batchRef.id,
        productId: productId,
        batchCode: batchCode,
        costPrice: costPrice,
        sellingPrice: sellingPrice,
        quantity: quantity,
        expiryDate: expiryDate,
        supplierId: supplierId,
        purchaseId: purchaseId,
        createdAt: DateTime.now(),
      );

      final productRef = _firestore
          .collection('shops')
          .doc(shopId)
          .collection('products')
          .doc(productId);

      final batch = _firestore.batch();
      batch.set(batchRef, batchModel.toMap());
      batch.update(productRef, {
        'currentStock': FieldValue.increment(quantity),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      return FirestoreWriteHelper.commitBatch(batch);
    } catch (e) {
      debugPrint('Add batch error: $e');
      return const RecordWriteResult(success: false);
    }
  }

  // Update product details
  Future<RecordWriteResult> updateProduct({
    required String shopId,
    required String productId,
    required String name,
    required String unit,
    required double defaultSellingPrice,
    required double lowStockAlert,
  }) async {
    try {
      final productRef = _firestore
          .collection('shops')
          .doc(shopId)
          .collection('products')
          .doc(productId);

      final batch = _firestore.batch();
      batch.update(productRef, {
        'name': name,
        'unit': unit,
        'defaultSellingPrice': defaultSellingPrice,
        'lowStockAlert': lowStockAlert,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      return FirestoreWriteHelper.commitBatch(batch);
    } catch (e) {
      debugPrint('Update product error: $e');
      return const RecordWriteResult(success: false);
    }
  }

  /// Deletes a product and its batch subcollection.
  Future<RecordWriteResult> deleteProduct(
    String shopId,
    String productId,
  ) async {
    try {
      final productRef = _firestore
          .collection('shops')
          .doc(shopId)
          .collection('products')
          .doc(productId);

      final batchesSnapshot =
          await FirestoreReadHelper.getQuery(productRef.collection('batches'));

      final batch = _firestore.batch();
      for (final doc in batchesSnapshot.docs) {
        batch.delete(doc.reference);
      }
      batch.delete(productRef);
      return FirestoreWriteHelper.commitBatch(batch);
    } catch (e) {
      debugPrint('Delete product error: $e');
      return const RecordWriteResult(success: false);
    }
  }

  // Get batches for a product (for offline use)
  Stream<List<BatchModel>> getBatches(String shopId, String productId) {
    return _firestore
        .collection('shops')
        .doc(shopId)
        .collection('products')
        .doc(productId)
        .collection('batches')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => BatchModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  /// Batches with stock available — reads from cache when offline.
  Future<List<BatchModel>> getActiveBatches(
    String shopId,
    String productId,
  ) async {
    try {
      final batchRef = _firestore
          .collection('shops')
          .doc(shopId)
          .collection('products')
          .doc(productId)
          .collection('batches');

      final snapshot = await FirestoreReadHelper.getQuery(batchRef);
      return snapshot.docs
          .map((doc) => BatchModel.fromMap(doc.id, doc.data()))
          .where((batch) => batch.quantity > 0)
          .toList();
    } catch (e, st) {
      debugPrint('getActiveBatches error: $e\n$st');
      return [];
    }
  }
}
