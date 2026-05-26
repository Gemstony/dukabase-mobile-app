import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/product_model.dart';
import '../models/batch_model.dart';
import '../utils/firestore_read_helper.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream of all products in a shop (with real‑time updates)
  Stream<List<ProductModel>> getProducts(String shopId) {
    return _firestore
        .collection('shops')
        .doc(shopId)
        .collection('products')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  // Create a new product
  Future<ProductModel?> createProduct({
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
      await docRef.set(product.toMap());
      return product;
    } catch (e) {
      print('Create product error: $e');
      return null;
    }
  }

  // Add a batch to a product (used when purchasing)
  Future<BatchModel?> addBatch({
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
      final batchesRef = _firestore
          .collection('shops')
          .doc(shopId)
          .collection('products')
          .doc(productId)
          .collection('batches');
      final batchRef = batchesRef.doc();
      final batch = BatchModel(
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
      await batchRef.set(batch.toMap());

      // Update product current stock
      final productRef = _firestore
          .collection('shops')
          .doc(shopId)
          .collection('products')
          .doc(productId);
      await productRef.update({
        'currentStock': FieldValue.increment(quantity),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return batch;
    } catch (e) {
      print('Add batch error: $e');
      return null;
    }
  }

  // Update product details
  Future<bool> updateProduct({
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
          
      await productRef.update({
        'name': name,
        'unit': unit,
        'defaultSellingPrice': defaultSellingPrice,
        'lowStockAlert': lowStockAlert,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Update product error: $e');
      return false;
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
        .map((snapshot) => snapshot.docs
            .map((doc) => BatchModel.fromMap(doc.id, doc.data()))
            .toList());
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