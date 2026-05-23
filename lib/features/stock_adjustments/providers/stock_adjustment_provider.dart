import 'package:flutter/material.dart';
import '../../../core/services/stock_adjustment_service.dart';
import '../../../core/models/stock_adjustment_model.dart';

class StockAdjustmentProvider extends ChangeNotifier {
  final StockAdjustmentService _service = StockAdjustmentService();
  List<StockAdjustmentModel> _adjustments = [];
  bool _isLoading = false;
  String? _error;

  List<StockAdjustmentModel> get adjustments => _adjustments;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void loadAdjustments(String shopId) {
    _isLoading = true;
    notifyListeners();
    _service.getAdjustments(shopId).listen((adjustments) {
      _adjustments = adjustments;
      _isLoading = false;
      _error = null;
      notifyListeners();
    }, onError: (error) {
      _error = error.toString();
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<bool> recordAdjustment({
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
    final success = await _service.recordAdjustment(
      shopId: shopId,
      productId: productId,
      batchId: batchId,
      reason: reason,
      quantityChange: quantityChange,
      note: note,
      createdBy: createdBy,
    );
    _isLoading = false;
    if (!success) {
      _error = 'Failed to record adjustment';
      notifyListeners();
    }
    return success;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}