import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String id;
  final String shopId;
  final String name;
  final String sku; // unique identifier (can be barcode)
  final String unit; // e.g., "pcs", "kg", "liter"
  final double defaultSellingPrice;
  final double currentStock; // aggregated from batches
  final double lowStockAlert; // threshold for alerts
  final DateTime createdAt;
  final DateTime updatedAt;

  ProductModel({
    required this.id,
    required this.shopId,
    required this.name,
    required this.sku,
    required this.unit,
    required this.defaultSellingPrice,
    required this.currentStock,
    required this.lowStockAlert,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'shopId': shopId,
      'name': name,
      'sku': sku,
      'unit': unit,
      'defaultSellingPrice': defaultSellingPrice,
      'currentStock': currentStock,
      'lowStockAlert': lowStockAlert,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory ProductModel.fromMap(String id, Map<String, dynamic> map) {
    return ProductModel(
      id: id,
      shopId: map['shopId'] as String,
      name: map['name'] as String,
      sku: map['sku'] as String,
      unit: map['unit'] as String,
      defaultSellingPrice: (map['defaultSellingPrice'] as num).toDouble(),
      currentStock: (map['currentStock'] as num).toDouble(),
      lowStockAlert: (map['lowStockAlert'] as num).toDouble(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }
}