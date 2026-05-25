import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/supplier_model.dart';

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

  Future<SupplierModel?> createSupplier({
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
      await docRef.set(supplier.toMap());
      return supplier;
    } catch (e) {
      print('Create supplier error: $e');
      return null;
    }
  }

  Future<bool> updateSupplier({
    required String shopId,
    required String supplierId,
    required String name,
    required String phone,
    String? email,
    String? address,
  }) async {
    try {
      await _firestore
          .collection('shops')
          .doc(shopId)
          .collection('suppliers')
          .doc(supplierId)
          .update({
        'name': name,
        'phone': phone,
        'email': email,
        'address': address,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Update supplier error: $e');
      return false;
    }
  }

  Future<bool> deleteSupplier(String shopId, String supplierId) async {
    try {
      await _firestore
          .collection('shops')
          .doc(shopId)
          .collection('suppliers')
          .doc(supplierId)
          .delete();
      return true;
    } catch (e) {
      print('Delete supplier error: $e');
      return false;
    }
  }
}