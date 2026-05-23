import 'package:flutter/material.dart';
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
    notifyListeners();
    _purchaseService.getPurchases(shopId).listen((purchases) {
      _purchases = purchases;
      _isLoading = false;
      _error = null;
      notifyListeners();
    }, onError: (error) {
      _error = error.toString();
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<bool> recordPurchase({
    required String shopId,
    required String supplierId,
    required double totalAmount,
    required double paidAmount,
    required String paymentMethodId,
    required List<({
      String productId,
      String batchCode,
      double quantity,
      double costPrice,
      double sellingPrice,
      DateTime? expiryDate,
    })> items,
  }) async {
    _isLoading = true;
    notifyListeners();
    final success = await _purchaseService.recordPurchase(
      shopId: shopId,
      supplierId: supplierId,
      totalAmount: totalAmount,
      paidAmount: paidAmount,
      paymentMethodId: paymentMethodId,
      items: items,
    );
    _isLoading = false;
    if (!success) {
      _error = 'Failed to record purchase';
      notifyListeners();
    }
    return success;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}