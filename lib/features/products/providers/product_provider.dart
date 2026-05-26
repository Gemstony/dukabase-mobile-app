import 'package:flutter/material.dart';
import '../../../core/models/record_write_result.dart';
import '../../../core/services/product_service.dart';
import '../../../core/models/product_model.dart';

class ProductProvider extends ChangeNotifier {
  final ProductService _productService = ProductService();
  List<ProductModel> _products = [];
  bool _isLoading = false;
  String? _error;

  List<ProductModel> get products => _products;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void loadProducts(String shopId) {
    _isLoading = true;
    notifyListeners();
    _productService.getProducts(shopId).listen((products) {
      _products = products;
      _isLoading = false;
      _error = null;
      notifyListeners();
    }, onError: (error) {
      _error = error.toString();
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<RecordWriteResult> createProduct({
    required String shopId,
    required String name,
    required String sku,
    required String unit,
    required double defaultSellingPrice,
    required double lowStockAlert,
  }) async {
    _isLoading = true;
    notifyListeners();
    final result = await _productService.createProduct(
      shopId: shopId,
      name: name,
      sku: sku,
      unit: unit,
      defaultSellingPrice: defaultSellingPrice,
      lowStockAlert: lowStockAlert,
    );
    _isLoading = false;
    if (!result.success) {
      _error = 'Failed to create product';
      notifyListeners();
    }
    return result;
  }

  Future<RecordWriteResult> updateProduct({
    required String shopId,
    required String productId,
    required String name,
    required String unit,
    required double defaultSellingPrice,
    required double lowStockAlert,
  }) async {
    _isLoading = true;
    notifyListeners();
    final result = await _productService.updateProduct(
      shopId: shopId,
      productId: productId,
      name: name,
      unit: unit,
      defaultSellingPrice: defaultSellingPrice,
      lowStockAlert: lowStockAlert,
    );
    _isLoading = false;
    if (!result.success) {
      _error = 'Failed to update product';
    }
    notifyListeners();
    return result;
  }

  Future<RecordWriteResult> deleteProduct(
    String shopId,
    String productId,
  ) async {
    _isLoading = true;
    notifyListeners();
    final result = await _productService.deleteProduct(shopId, productId);
    _isLoading = false;
    if (!result.success) {
      _error = 'Failed to delete product';
      notifyListeners();
    }
    return result;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
