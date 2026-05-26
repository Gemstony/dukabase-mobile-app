import 'package:flutter/material.dart';
import '../../../core/models/record_write_result.dart';
import '../../../core/services/payment_service.dart';

class PaymentProvider extends ChangeNotifier {
  final PaymentService _paymentService = PaymentService();
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<RecordWriteResult> recordPayment({
    required String shopId,
    required String customerId,
    required double amount,
    required String paymentMethodId,
    String? saleId,
    String note = '',
  }) async {
    _isLoading = true;
    notifyListeners();
    final result = await _paymentService.recordPayment(
      shopId: shopId,
      customerId: customerId,
      amount: amount,
      paymentMethodId: paymentMethodId,
      saleId: saleId,
      note: note,
    );
    _isLoading = false;
    if (!result.success) {
      _error = 'Failed to record payment';
      notifyListeners();
    } else {
      _error = null;
    }
    return result;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}