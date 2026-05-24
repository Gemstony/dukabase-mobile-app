import 'package:cloud_firestore/cloud_firestore.dart';
class ShopModel {
  final String id;
  final String name;
  final String ownerId;
  final String? address;
  final String? phone;
  final String currency;
  final DateTime createdAt;
  final bool isActive;
  final DateTime? deletedAt; // for soft delete

  ShopModel({
    required this.id,
    required this.name,
    required this.ownerId,
    this.address,
    this.phone,
    this.currency = 'TZS',
    required this.createdAt,
    this.isActive = true,
    this.deletedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'ownerId': ownerId,
      'address': address,
      'phone': phone,
      'currency': currency,
      'createdAt': createdAt,
      'isActive': isActive,
      'deletedAt': deletedAt,
    };
  }

  factory ShopModel.fromMap(String id, Map<String, dynamic> map) {
    return ShopModel(
      id: id,
      name: map['name'] as String,
      ownerId: map['ownerId'] as String,
      address: map['address'] as String?,
      phone: map['phone'] as String?,
      currency: map['currency'] as String? ?? 'TZS',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      isActive: map['isActive'] ?? true,
      deletedAt: (map['deletedAt'] as Timestamp?)?.toDate(),
    );
  }
}