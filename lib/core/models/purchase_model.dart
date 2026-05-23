import 'package:cloud_firestore/cloud_firestore.dart';

class PurchaseModel {
  final String id;
  final String shopId;
  final String supplierId;
  final double totalAmount;
  final double paidAmount;
  final double balance; // totalAmount - paidAmount
  final String? paymentMethodId;
  final String status; // "pending", "completed", "cancelled"
  final DateTime createdAt;

  PurchaseModel({
    required this.id,
    required this.shopId,
    required this.supplierId,
    required this.totalAmount,
    required this.paidAmount,
    required this.balance,
    this.paymentMethodId,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'shopId': shopId,
      'supplierId': supplierId,
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'balance': balance,
      'paymentMethodId': paymentMethodId,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory PurchaseModel.fromMap(String id, Map<String, dynamic> map) {
    return PurchaseModel(
      id: id,
      shopId: map['shopId'] as String,
      supplierId: map['supplierId'] as String,
      totalAmount: (map['totalAmount'] as num).toDouble(),
      paidAmount: (map['paidAmount'] as num).toDouble(),
      balance: (map['balance'] as num).toDouble(),
      paymentMethodId: map['paymentMethodId'] as String?,
      status: map['status'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}

class PurchaseItemModel {
  final String productId;
  final String batchId;
  final double quantity;
  final double costPrice;
  final double subtotal;

  PurchaseItemModel({
    required this.productId,
    required this.batchId,
    required this.quantity,
    required this.costPrice,
    required this.subtotal,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'batchId': batchId,
      'quantity': quantity,
      'costPrice': costPrice,
      'subtotal': subtotal,
    };
  }

  factory PurchaseItemModel.fromMap(Map<String, dynamic> map) {
    return PurchaseItemModel(
      productId: map['productId'] as String,
      batchId: map['batchId'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      costPrice: (map['costPrice'] as num).toDouble(),
      subtotal: (map['subtotal'] as num).toDouble(),
    );
  }
}