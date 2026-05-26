import 'package:flutter/material.dart';
import '../../../core/models/record_write_result.dart';
import '../../../core/services/supplier_service.dart';
import '../../../core/models/supplier_model.dart';

class SupplierProvider extends ChangeNotifier {
  final SupplierService _supplierService = SupplierService();
  List<SupplierModel> _suppliers = [];
  bool _isLoading = false;
  String? _error;

  List<SupplierModel> get suppliers => _suppliers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void loadSuppliers(String shopId) {
    _isLoading = true;
    notifyListeners();
    _supplierService.getSuppliers(shopId).listen((suppliers) {
      _suppliers = suppliers;
      _isLoading = false;
      _error = null;
      notifyListeners();
    }, onError: (error) {
      _error = error.toString();
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<RecordWriteResult> createSupplier({
    required String shopId,
    required String name,
    required String phone,
    String? email,
    String? address,
    double openingBalance = 0,
  }) async {
    _isLoading = true;
    notifyListeners();
    final result = await _supplierService.createSupplier(
      shopId: shopId,
      name: name,
      phone: phone,
      email: email,
      address: address,
      openingBalance: openingBalance,
    );
    _isLoading = false;
    if (!result.success) {
      _error = 'Failed to create supplier';
      notifyListeners();
    }
    return result;
  }

  Future<RecordWriteResult> updateSupplier({
    required String shopId,
    required String supplierId,
    required String name,
    required String phone,
    String? email,
    String? address,
  }) async {
    _isLoading = true;
    notifyListeners();
    final result = await _supplierService.updateSupplier(
      shopId: shopId,
      supplierId: supplierId,
      name: name,
      phone: phone,
      email: email,
      address: address,
    );
    _isLoading = false;
    if (!result.success) {
      _error = 'Failed to update supplier';
    }
    notifyListeners();
    return result;
  }

  Future<RecordWriteResult> deleteSupplier(
    String shopId,
    String supplierId,
  ) async {
    _isLoading = true;
    notifyListeners();
    final result = await _supplierService.deleteSupplier(shopId, supplierId);
    _isLoading = false;
    if (!result.success) {
      _error = 'Failed to delete supplier';
    }
    notifyListeners();
    return result;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}