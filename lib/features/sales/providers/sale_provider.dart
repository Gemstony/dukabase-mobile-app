import 'package:flutter/material.dart';
import '../../../core/models/record_write_result.dart';
import '../../../core/services/sale_service.dart';
import '../../../core/models/sale_model.dart';

class SaleProvider extends ChangeNotifier {
  final SaleService _saleService = SaleService();
  List<SaleModel> _sales = [];
  bool _isLoading = false;
  String? _error;

  List<SaleModel> get sales => _sales;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void loadSales(String shopId) {
    _isLoading = true;
    notifyListeners();
    _saleService.getSales(shopId).listen((sales) {
      _sales = sales;
      _isLoading = false;
      _error = null;
      notifyListeners();
    }, onError: (error) {
      _isLoading = false;
      notifyListeners();
    });
  }

  Stream<List<SaleModel>> getTodaySalesStream(String shopId) {
    return _saleService.getTodaySales(shopId);
  }

  Future<RecordWriteResult> recordSale({
    required String shopId,
    required String? customerId,
    required String paymentMethodId,
    required double paidAmount,
    required List<({
      String batchId,
      String productId,
      String productName,
      double quantity,
      double sellingPrice,
    })> items,
  }) async {
    _isLoading = true;
    notifyListeners();
    final result = await _saleService.recordSale(
      shopId: shopId,
      customerId: customerId,
      paymentMethodId: paymentMethodId,
      paidAmount: paidAmount,
      items: items,
    );
    _isLoading = false;
    if (!result.success) {
      _error = 'Failed to record sale';
      notifyListeners();
    }
    return result;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}