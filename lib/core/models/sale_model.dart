import 'package:cloud_firestore/cloud_firestore.dart';

class SaleModel {
  final String id;
  final String shopId;
  final String? customerId; // null = walk‑in
  final String paymentMethodId;
  final double totalAmount;
  final double paidAmount;
  final double change; // paidAmount - totalAmount
  final String status; // "completed", "pending" (for credit)
  final DateTime createdAt;

  SaleModel({
    required this.id,
    required this.shopId,
    this.customerId,
    required this.paymentMethodId,
    required this.totalAmount,
    required this.paidAmount,
    required this.change,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'shopId': shopId,
      'customerId': customerId,
      'paymentMethodId': paymentMethodId,
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'change': change,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory SaleModel.fromMap(String id, Map<String, dynamic> map) {
    return SaleModel(
      id: id,
      shopId: map['shopId'] as String,
      customerId: map['customerId'] as String?,
      paymentMethodId: map['paymentMethodId'] as String,
      totalAmount: (map['totalAmount'] as num).toDouble(),
      paidAmount: (map['paidAmount'] as num).toDouble(),
      change: (map['change'] as num).toDouble(),
      status: map['status'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}

class SaleItemModel {
  final String productId;
  final String productName; // ✅ new field
  final String batchId;
  final double quantity;
  final double sellingPrice;
  final double subtotal;

  SaleItemModel({
    required this.productId,
    required this.productName, // ✅ new field
    required this.batchId,
    required this.quantity,
    required this.sellingPrice,
    required this.subtotal,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName, // ✅ new field
      'batchId': batchId,
      'quantity': quantity,
      'sellingPrice': sellingPrice,
      'subtotal': subtotal,
    };
  }

  factory SaleItemModel.fromMap(Map<String, dynamic> map) {
    return SaleItemModel(
      productId: map['productId'] as String,
      productName: map['productName'] as String, // ✅ new field
      batchId: map['batchId'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      sellingPrice: (map['sellingPrice'] as num).toDouble(),
      subtotal: (map['subtotal'] as num).toDouble(),
    );
  }
}