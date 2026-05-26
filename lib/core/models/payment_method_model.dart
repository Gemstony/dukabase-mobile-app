import 'package:cloud_firestore/cloud_firestore.dart';

enum PaymentMethodType { cash, bank, mobile_money, other }

class PaymentMethodModel {
  final String id;
  final String shopId;
  final String name;          // e.g., "Cash", "CRDB Bank", "M-Pesa"
  final PaymentMethodType type;
  final double initialBalance;
  final double currentBalance;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  PaymentMethodModel({
    required this.id,
    required this.shopId,
    required this.name,
    required this.type,
    required this.initialBalance,
    required this.currentBalance,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'shopId': shopId,
      'name': name,
      'type': type.name,
      'initialBalance': initialBalance,
      'currentBalance': currentBalance,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory PaymentMethodModel.fromMap(String id, Map<String, dynamic> map) {
    final createdRaw = map['createdAt'];
    final updatedRaw = map['updatedAt'];
    final createdAt = createdRaw is Timestamp
        ? createdRaw.toDate()
        : DateTime.now();
    final updatedAt = updatedRaw is Timestamp
        ? updatedRaw.toDate()
        : createdAt;

    return PaymentMethodModel(
      id: id,
      shopId: map['shopId'] as String,
      name: map['name'] as String,
      type: PaymentMethodType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => PaymentMethodType.other,
      ),
      initialBalance: ((map['initialBalance'] as num?) ?? 0).toDouble(),
      currentBalance: ((map['currentBalance'] as num?) ?? 0).toDouble(),
      isActive: map['isActive'] ?? true,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}