import 'package:flutter/material.dart';
import '../../../core/services/payment_method_service.dart';
import '../../../core/models/payment_method_model.dart';

class PaymentMethodProvider extends ChangeNotifier {
  final PaymentMethodService _service = PaymentMethodService();
  List<PaymentMethodModel> _methods = [];
  bool _isLoading = false;
  String? _error;

  List<PaymentMethodModel> get methods => _methods;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void loadPaymentMethods(String shopId) {
    _isLoading = true;
    notifyListeners();
    _service.getPaymentMethods(shopId).listen((methods) {
      _methods = methods;
      _isLoading = false;
      _error = null;
      notifyListeners();
    }, onError: (error) {
      _error = error.toString();
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<bool> createPaymentMethod({
    required String shopId,
    required String name,
    required PaymentMethodType type,
    required double initialBalance,
  }) async {
    _isLoading = true;
    notifyListeners();
    final method = await _service.createPaymentMethod(
      shopId: shopId,
      name: name,
      type: type,
      initialBalance: initialBalance,
    );
    _isLoading = false;
    if (method != null) return true;
    _error = 'Failed to create payment method';
    notifyListeners();
    return false;
  }

  Future<bool> deletePaymentMethod(String shopId, String methodId) async {
    _isLoading = true;
    notifyListeners();
    final success = await _service.deletePaymentMethod(shopId, methodId);
    _isLoading = false;
    if (!success) {
      _error = 'Failed to delete payment method';
      notifyListeners();
    }
    return success;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}