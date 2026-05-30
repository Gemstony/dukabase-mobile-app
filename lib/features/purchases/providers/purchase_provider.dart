import 'package:flutter/material.dart';
import '../../../core/models/record_write_result.dart';
import '../../../core/services/purchase_service.dart';
import '../../../core/models/purchase_model.dart';

class PurchaseProvider extends ChangeNotifier {
  final PurchaseService _purchaseService = PurchaseService();
  List<PurchaseModel> _purchases = [];
  bool _isLoading = false;
  String? _error;

  List<PurchaseModel> get purchases => _purchases;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void loadPurchases(String shopId) {
    _isLoading = true;
    if (hasListeners) notifyListeners();
    _purchaseService.getPurchases(shopId).listen((purchases) {
      _purchases = purchases;
      _isLoading = false;
      _error = null;
      if (hasListeners) notifyListeners();
    }, onError: (error) {
      _error = error.toString();
      _isLoading = false;
      if (hasListeners) notifyListeners();
    });
  }

  Future<RecordWriteResult> recordPurchase({
    required String shopId,
    required String supplierId,
    required String supplierName,
    required double totalAmount,
    required double paidAmount,
    required String paymentMethodId,
    required List<({
      String productId,
      String productName,
      String batchCode,
      double quantity,
      double costPrice,
      double sellingPrice,
      DateTime? expiryDate,
    })> items,
  }) async {
    _isLoading = true;
    if (hasListeners) notifyListeners();
    final result = await _purchaseService.recordPurchase(
      shopId: shopId,
      supplierId: supplierId,
      supplierName: supplierName,
      totalAmount: totalAmount,
      paidAmount: paidAmount,
      paymentMethodId: paymentMethodId,
      items: items,
    );
    _isLoading = false;
    if (hasListeners) notifyListeners();
    if (!result.success) {
      _error = 'Failed to record purchase';
      if (hasListeners) notifyListeners();
    }
    return result;
  }

  void clearError() {
    _error = null;
    if (hasListeners) notifyListeners();
  }
}