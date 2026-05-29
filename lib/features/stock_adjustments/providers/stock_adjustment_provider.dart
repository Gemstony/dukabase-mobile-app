import 'package:flutter/material.dart';
import '../../../core/models/record_write_result.dart';
import '../../../core/services/stock_adjustment_service.dart';
import '../../../core/services/product_service.dart';
import '../../../core/services/staff_service.dart';
import '../../../core/models/stock_adjustment_model.dart';

class StockAdjustmentProvider extends ChangeNotifier {
  final StockAdjustmentService _service = StockAdjustmentService();
  final ProductService _productService = ProductService();
  final StaffService _staffService = StaffService();
  List<StockAdjustmentModel> _adjustments = [];
  bool _isLoading = false;
  String? _error;
  Map<String, String> _productNames = {};
  Map<String, String> _creatorNames = {};

  List<StockAdjustmentModel> get adjustments => _adjustments;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, String> get productNames => _productNames;
  Map<String, String> get creatorNames => _creatorNames;

  void loadAdjustments(String shopId) {
    _isLoading = true;
    notifyListeners();

    // Load products to get product names
    _productService.getProducts(shopId).listen((products) {
      _productNames = {for (var p in products) p.id: p.name};
      notifyListeners();
    });

    // Load shop members to get creator names
    _staffService.getShopMembers(shopId).listen((members) {
      _creatorNames = {for (var m in members) m.user.id: m.user.name};
      notifyListeners();
    });

    _service
        .getAdjustments(shopId)
        .listen(
          (adjustments) {
            _adjustments = adjustments;
            _isLoading = false;
            _error = null;
            notifyListeners();
          },
          onError: (error) {
            _error = error.toString();
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  Future<RecordWriteResult> recordAdjustment({
    required String shopId,
    required String productId,
    required String batchId,
    required String reason,
    required double quantityChange,
    String? note,
    required String createdBy,
  }) async {
    _isLoading = true;
    notifyListeners();
    final result = await _service.recordAdjustment(
      shopId: shopId,
      productId: productId,
      batchId: batchId,
      reason: reason,
      quantityChange: quantityChange,
      note: note,
      createdBy: createdBy,
    );
    _isLoading = false;
    if (!result.success) {
      _error = 'Failed to record adjustment';
      notifyListeners();
    }
    return result;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
