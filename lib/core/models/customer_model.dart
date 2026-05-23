import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerModel {
  final String id;
  final String shopId;
  final String name;
  final String phone;
  final String? email;
  final double openingBalance;
  final double currentBalance; // positive = customer owes you
  final DateTime createdAt;
  final DateTime updatedAt;

  CustomerModel({
    required this.id,
    required this.shopId,
    required this.name,
    required this.phone,
    this.email,
    required this.openingBalance,
    required this.currentBalance,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'shopId': shopId,
      'name': name,
      'phone': phone,
      'email': email,
      'openingBalance': openingBalance,
      'currentBalance': currentBalance,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory CustomerModel.fromMap(String id, Map<String, dynamic> map) {
    return CustomerModel(
      id: id,
      shopId: map['shopId'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String,
      email: map['email'] as String?,
      openingBalance: (map['openingBalance'] as num).toDouble(),
      currentBalance: (map['currentBalance'] as num).toDouble(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }
}