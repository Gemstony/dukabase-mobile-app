
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/customer_model.dart';

class CustomerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<CustomerModel>> getCustomers(String shopId) {
    return _firestore
        .collection('shops')
        .doc(shopId)
        .collection('customers')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CustomerModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<CustomerModel?> createCustomer({
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
      await docRef.set(customer.toMap());
      return customer;
    } catch (e) {
      print('Create customer error: $e');
      return null;
    }
  }
}