import 'package:flutter/material.dart';
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

  Future<bool> createCustomer({
    required String shopId,
    required String name,
    required String phone,
    String? email,
    double openingBalance = 0,
  }) async {
    _isLoading = true;
    notifyListeners();
    final customer = await _customerService.createCustomer(
      shopId: shopId,
      name: name,
      phone: phone,
      email: email,
      openingBalance: openingBalance,
    );
    _isLoading = false;
    if (customer != null) return true;
    _error = 'Failed to create customer';
    notifyListeners();
    return false;
  }

  Future<bool> updateCustomer({
    required String shopId,
    required String customerId,
    required String name,
    required String phone,
    String? email,
  }) async {
    _isLoading = true;
    notifyListeners();
    final success = await _customerService.updateCustomer(
      shopId: shopId,
      customerId: customerId,
      name: name,
      phone: phone,
      email: email,
    );
    _isLoading = false;
    if (!success) {
      _error = 'Failed to update customer';
    }
    notifyListeners();
    return success;
  }

  Future<bool> deleteCustomer(String shopId, String customerId) async {
    _isLoading = true;
    notifyListeners();
    final success = await _customerService.deleteCustomer(shopId, customerId);
    _isLoading = false;
    if (!success) {
      _error = 'Failed to delete customer';
    }
    notifyListeners();
    return success;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}