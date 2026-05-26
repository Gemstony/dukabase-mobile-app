import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/customer_model.dart';
import '../models/record_write_result.dart';
import '../utils/firestore_read_helper.dart';
import '../utils/firestore_write_helper.dart';

class CustomerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<CustomerModel>> getCustomers(String shopId) {
    return _firestore
        .collection('shops')
        .doc(shopId)
        .collection('customers')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CustomerModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<CustomerModel?> getCustomer(String shopId, String customerId) async {
    try {
      final customerRef = _firestore
          .collection('shops')
          .doc(shopId)
          .collection('customers')
          .doc(customerId);
      final doc = await FirestoreReadHelper.getDocument(customerRef);
      if (doc.exists) {
        return CustomerModel.fromMap(doc.id, doc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint('Get customer error: $e');
      return null;
    }
  }

  Future<RecordWriteResult> createCustomer({
    required String shopId,
    required String name,
    required String phone,
    String? email,
    double openingBalance = 0,
  }) async {
    try {
      final customersRef = _firestore
          .collection('shops')
          .doc(shopId)
          .collection('customers');
      final docRef = customersRef.doc();
      final now = DateTime.now();
      final customer = CustomerModel(
        id: docRef.id,
        shopId: shopId,
        name: name,
        phone: phone,
        email: email,
        openingBalance: openingBalance,
        currentBalance: openingBalance,
        createdAt: now,
        updatedAt: now,
      );

      final batch = _firestore.batch();
      batch.set(docRef, customer.toMap());
      return FirestoreWriteHelper.commitBatch(batch);
    } catch (e) {
      debugPrint('Create customer error: $e');
      return const RecordWriteResult(success: false);
    }
  }

  Future<RecordWriteResult> updateCustomer({
    required String shopId,
    required String customerId,
    required String name,
    required String phone,
    String? email,
  }) async {
    try {
      final customerRef = _firestore
          .collection('shops')
          .doc(shopId)
          .collection('customers')
          .doc(customerId);

      final batch = _firestore.batch();
      batch.update(customerRef, {
        'name': name,
        'phone': phone,
        'email': email,
        // Use client time so reads work instantly offline.
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      return FirestoreWriteHelper.commitBatch(batch);
    } catch (e) {
      debugPrint('Update customer error: $e');
      return const RecordWriteResult(success: false);
    }
  }

  Future<RecordWriteResult> deleteCustomer(
    String shopId,
    String customerId,
  ) async {
    try {
      final customerRef = _firestore
          .collection('shops')
          .doc(shopId)
          .collection('customers')
          .doc(customerId);

      final batch = _firestore.batch();
      batch.delete(customerRef);
      return FirestoreWriteHelper.commitBatch(batch);
    } catch (e) {
      debugPrint('Delete customer error: $e');
      return const RecordWriteResult(success: false);
    }
  }
}
