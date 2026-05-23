import 'package:cloud_firestore/cloud_firestore.dart';

class StockAdjustmentModel {
  final String id;
  final String shopId;
  final String productId;
  final String batchId;
  final String reason; // "damage", "theft", "expiry", "correction", "return"
  final double quantityChange; // positive = add stock, negative = remove stock
  final String? note;
  final DateTime createdAt;
  final String createdBy; // user ID

  StockAdjustmentModel({
    required this.id,
    required this.shopId,
    required this.productId,
    required this.batchId,
    required this.reason,
    required this.quantityChange,
    this.note,
    required this.createdAt,
    required this.createdBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'shopId': shopId,
      'productId': productId,
      'batchId': batchId,
      'reason': reason,
      'quantityChange': quantityChange,
      'note': note,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
    };
  }

  factory StockAdjustmentModel.fromMap(String id, Map<String, dynamic> map) {
    return StockAdjustmentModel(
      id: id,
      shopId: map['shopId'] as String,
      productId: map['productId'] as String,
      batchId: map['batchId'] as String,
      reason: map['reason'] as String,
      quantityChange: (map['quantityChange'] as num).toDouble(),
      note: map['note'] as String?,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      createdBy: map['createdBy'] as String,
    );
  }
}