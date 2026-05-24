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

    _service
        .getProductsPaginated(shopId, limit: 20, lastDocument: _lastProductDoc)
        .listen(
          (snapshot) {
            _hasMoreProducts = snapshot.docs.length == 20;
            final newProducts = snapshot.docs
                .map((doc) => ProductModel.fromMap(doc.id, doc.data()))
                .toList();
            if (refresh) {
              _products = newProducts;
            } else {
              _products.addAll(newProducts);
            }
            _lastProductDoc = snapshot.docs.isNotEmpty
                ? snapshot.docs.last
                : null;
            _isLoadingProducts = false;
            _error = null;
            notifyListeners();
          },
          onError: (error) {
            _error = error.toString();
            _isLoadingProducts = false;
            notifyListeners();
          },
        );
  }

  Future<void> loadLowStockProducts(String shopId) async {
    _isLoadingLowStock = true;
    notifyListeners();
    _service
        .getLowStockProductsStream(shopId)
        .listen(
          (lowStock) {
            _lowStockProducts = lowStock;
            _isLoadingLowStock = false;
            _error = null;
            notifyListeners();
          },
          onError: (error) {
            _error = error.toString();
            _isLoadingLowStock = false;
            notifyListeners();
          },
        );
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
