import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/record_write_result.dart';
import '../models/supplier_model.dart';
import '../utils/firestore_write_helper.dart';

class SupplierService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<SupplierModel>> getSuppliers(String shopId) {
    return _firestore
        .collection('shops')
        .doc(shopId)
        .collection('suppliers')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SupplierModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<RecordWriteResult> createSupplier({
    required String shopId,
    required String name,
    required String phone,
    String? email,
    String? address,
    double openingBalance = 0,
  }) async {
    try {
      final suppliersRef = _firestore
          .collection('shops')
          .doc(shopId)
          .collection('suppliers');
      final docRef = suppliersRef.doc();
      final now = DateTime.now();
      final supplier = SupplierModel(
        id: docRef.id,
        shopId: shopId,
        name: name,
        phone: phone,
        email: email,
        address: address,
        openingBalance: openingBalance,
        currentBalance: openingBalance,
        createdAt: now,
        updatedAt: now,
      );
      final batch = _firestore.batch();
      batch.set(docRef, supplier.toMap());
      return FirestoreWriteHelper.commitBatch(batch);
    } catch (e) {
      debugPrint('Create supplier error: $e');
      return const RecordWriteResult(success: false);
    }
  }

  Future<RecordWriteResult> updateSupplier({
    required String shopId,
    required String supplierId,
    required String name,
    required String phone,
    String? email,
    String? address,
  }) async {
    try {
      final supplierRef = _firestore
          .collection('shops')
          .doc(shopId)
          .collection('suppliers')
          .doc(supplierId);
      final batch = _firestore.batch();
      batch.update(supplierRef, {
        'name': name,
        'phone': phone,
        'email': email,
        'address': address,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      return FirestoreWriteHelper.commitBatch(batch);
    } catch (e) {
      debugPrint('Update supplier error: $e');
      return const RecordWriteResult(success: false);
    }
  }

  Future<RecordWriteResult> deleteSupplier(
    String shopId,
    String supplierId,
  ) async {
    try {
      final supplierRef = _firestore
          .collection('shops')
          .doc(shopId)
          .collection('suppliers')
          .doc(supplierId);
      final batch = _firestore.batch();
      batch.delete(supplierRef);
      return FirestoreWriteHelper.commitBatch(batch);
    } catch (e) {
      debugPrint('Delete supplier error: $e');
      return const RecordWriteResult(success: false);
    }
  }
}