import 'package:flutter/material.dart';
import '../../../core/models/record_write_result.dart';
import '../../../core/services/customer_service.dart';
import '../../../core/models/customer_model.dart';

class CustomerProvider extends ChangeNotifier {
  final CustomerService _customerService = CustomerService();
  List<CustomerModel> _customers = [];
  bool _isLoading = false;
  String? _error;

  List<CustomerModel> get customers => _customers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void loadCustomers(String shopId) {
    _isLoading = true;
    notifyListeners();
    _customerService.getCustomers(shopId).listen((customers) {
      _customers = customers;
      _isLoading = false;
      _error = null;
      notifyListeners();
    }, onError: (error) {
      _error = error.toString();
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<RecordWriteResult> createCustomer({
    required String shopId,
    required String name,
    required String phone,
    String? email,
    double openingBalance = 0,
  }) async {
    _isLoading = true;
    notifyListeners();
    final result = await _customerService.createCustomer(
      shopId: shopId,
      name: name,
      phone: phone,
      email: email,
      openingBalance: openingBalance,
    );
    _isLoading = false;
    if (!result.success) {
      _error = 'Failed to create customer';
      notifyListeners();
    }
    return result;
  }

  Future<RecordWriteResult> updateCustomer({
    required String shopId,
    required String customerId,
    required String name,
    required String phone,
    String? email,
  }) async {
    _isLoading = true;
    notifyListeners();
    final result = await _customerService.updateCustomer(
      shopId: shopId,
      customerId: customerId,
      name: name,
      phone: phone,
      email: email,
    );
    _isLoading = false;
    if (!result.success) {
      _error = 'Failed to update customer';
    }
    notifyListeners();
    return result;
  }

  Future<RecordWriteResult> deleteCustomer(
    String shopId,
    String customerId,
  ) async {
    _isLoading = true;
    notifyListeners();
    final result = await _customerService.deleteCustomer(shopId, customerId);
    _isLoading = false;
    if (!result.success) {
      _error = 'Failed to delete customer';
    }
    notifyListeners();
    return result;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}