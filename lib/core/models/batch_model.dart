import 'package:cloud_firestore/cloud_firestore.dart';

class BatchModel {
  final String id;
  final String productId;
  final String batchCode; // e.g., "BATCH-001"
  final double costPrice;
  final double sellingPrice; // can override product default
  final double quantity;
  final DateTime? expiryDate;
  final String supplierId;
  final String purchaseId; // reference to purchase doc
  final DateTime createdAt;

  BatchModel({
    required this.id,
    required this.productId,
    required this.batchCode,
    required this.costPrice,
    required this.sellingPrice,
    required this.quantity,
    this.expiryDate,
    required this.supplierId,
    required this.purchaseId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'batchCode': batchCode,
      'costPrice': costPrice,
      'sellingPrice': sellingPrice,
      'quantity': quantity,
      'expiryDate': expiryDate != null ? Timestamp.fromDate(expiryDate!) : null,
      'supplierId': supplierId,
      'purchaseId': purchaseId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory BatchModel.fromMap(String id, Map<String, dynamic> map) {
    return BatchModel(
      id: id,
      productId: map['productId'] as String,
      batchCode: map['batchCode'] as String,
      costPrice: (map['costPrice'] as num).toDouble(),
      sellingPrice: (map['sellingPrice'] as num).toDouble(),
      quantity: (map['quantity'] as num).toDouble(),
      expiryDate: (map['expiryDate'] as Timestamp?)?.toDate(),
      supplierId: map['supplierId'] as String,
      purchaseId: map['purchaseId'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}