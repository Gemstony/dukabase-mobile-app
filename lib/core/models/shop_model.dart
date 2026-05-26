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
    final createdRaw = map['createdAt'];
    final createdAt = createdRaw is Timestamp
        ? createdRaw.toDate()
        : createdRaw is DateTime
            ? createdRaw
            : DateTime.now();

    final deletedRaw = map['deletedAt'];
    final deletedAt = deletedRaw is Timestamp
        ? deletedRaw.toDate()
        : deletedRaw is DateTime
            ? deletedRaw
            : null;

    return ShopModel(
      id: id,
      name: map['name'] as String,
      ownerId: map['ownerId'] as String,
      address: map['address'] as String?,
      phone: map['phone'] as String?,
      currency: map['currency'] as String? ?? 'TZS',
      createdAt: createdAt,
      isActive: map['isActive'] ?? true,
      deletedAt: deletedAt,
    );
  }
}