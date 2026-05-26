import 'package:cloud_firestore/cloud_firestore.dart';

class SupplierModel {
  final String id;
  final String shopId;
  final String name;
  final String phone;
  final String? email;
  final String? address;
  final double openingBalance; // supplier owes you (positive) or you owe supplier (negative)
  final double currentBalance;
  final DateTime createdAt;
  final DateTime updatedAt;

  SupplierModel({
    required this.id,
    required this.shopId,
    required this.name,
    required this.phone,
    this.email,
    this.address,
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
      'address': address,
      'openingBalance': openingBalance,
      'currentBalance': currentBalance,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory SupplierModel.fromMap(String id, Map<String, dynamic> map) {
    final createdRaw = map['createdAt'];
    final updatedRaw = map['updatedAt'];
    final createdAt = createdRaw is Timestamp
        ? createdRaw.toDate()
        : DateTime.now();
    final updatedAt = updatedRaw is Timestamp
        ? updatedRaw.toDate()
        : createdAt;

    return SupplierModel(
      id: id,
      shopId: map['shopId'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String,
      email: map['email'] as String?,
      address: map['address'] as String?,
      openingBalance: ((map['openingBalance'] as num?) ?? 0).toDouble(),
      currentBalance: ((map['currentBalance'] as num?) ?? 0).toDouble(),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}