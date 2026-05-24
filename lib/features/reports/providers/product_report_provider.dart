// lib/features/reports/providers/product_report_provider.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/report_service.dart';
import '../../../core/models/product_model.dart';

class ProductReportProvider extends ChangeNotifier {
  final ReportService _service = ReportService();
  List<ProductModel> _products = [];
  List<ProductModel> _lowStockProducts = [];
  DocumentSnapshot? _lastProductDoc;
  bool _hasMoreProducts = true;
  bool _isLoadingProducts = false;
  bool _isLoadingLowStock = false;
  String? _error;

  List<ProductModel> get products => _products;
  List<ProductModel> get lowStockProducts => _lowStockProducts;
  bool get hasMoreProducts => _hasMoreProducts;
  bool get isLoadingProducts => _isLoadingProducts;
  bool get isLoadingLowStock => _isLoadingLowStock;
  String? get error => _error;

  Future<void> loadProducts(String shopId, {bool refresh = false}) async {
    if (_isLoadingProducts) return;
    if (refresh) {
      _products.clear();
      _lastProductDoc = null;
      _hasMoreProducts = true;
    }
    if (!_hasMoreProducts) return;
    _isLoadingProducts = true;
    notifyListeners();
    try {
      final snapshot = await _service.getProductsPaginated(shopId, limit: 20, lastDocument: _lastProductDoc).first;
      _hasMoreProducts = snapshot.docs.length == 20;
      final newProducts = snapshot.docs.map((doc) => ProductModel.fromMap(doc.id, doc.data())).toList();
      if (refresh) {
        _products = newProducts;
      } else {
        _products.addAll(newProducts);
      }
      _lastProductDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingProducts = false;
      notifyListeners();
    }
  }

  Future<void> loadLowStockProducts(String shopId) async {
    _isLoadingLowStock = true;
    notifyListeners();
    try {
      final snapshot = await _service.getLowStockProducts(shopId).first;
      // Since the query may return all, we filter client-side
      final allProducts = snapshot.docs.map((doc) => ProductModel.fromMap(doc.id, doc.data())).toList();
      _lowStockProducts = allProducts.where((p) => p.currentStock <= p.lowStockAlert).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingLowStock = false;
      notifyListeners();
    }
  }
}