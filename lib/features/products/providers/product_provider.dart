import 'package:flutter/material.dart';
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

  Future<bool> createProduct({
    required String shopId,
    required String name,
    required String sku,
    required String unit,
    required double defaultSellingPrice,
    required double lowStockAlert,
  }) async {
    _isLoading = true;
    notifyListeners();
    final product = await _productService.createProduct(
      shopId: shopId,
      name: name,
      sku: sku,
      unit: unit,
      defaultSellingPrice: defaultSellingPrice,
      lowStockAlert: lowStockAlert,
    );
    _isLoading = false;
    if (product != null) {
      // The stream will add it automatically
      return true;
    } else {
      _error = 'Failed to create product';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProduct({
    required String shopId,
    required String productId,
    required String name,
    required String unit,
    required double defaultSellingPrice,
    required double lowStockAlert,
  }) async {
    _isLoading = true;
    notifyListeners();
    final success = await _productService.updateProduct(
      shopId: shopId,
      productId: productId,
      name: name,
      unit: unit,
      defaultSellingPrice: defaultSellingPrice,
      lowStockAlert: lowStockAlert,
    );
    _isLoading = false;
    if (!success) {
      _error = 'Failed to update product';
    }
    notifyListeners();
    return success;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}