import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/models/record_write_result.dart';
import '../../../core/services/shop_service.dart';
import '../../../core/models/shop_model.dart';
import '../../../core/utils/connectivity_helper.dart';

class ShopProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final ShopService _shopService = ShopService();
  List<ShopModel> _shops = [];
  ShopModel? _currentShop;
  bool _isLoading = false;
  String? _error;

  List<ShopModel> get shops => _shops;
  ShopModel? get currentShop => _currentShop;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load user's shops (call after login)
  void loadUserShops(String userId) {
    _isLoading = true;
    _error = null;
    notifyListeners();

    _shopService
        .getUserShops(userId)
        .listen(
          (shops) async {
            _shops = shops;
            _isLoading = false;
            _error = null;
            print('✅ ShopProvider: received ${shops.length} active shops');

            final prefs = await SharedPreferences.getInstance();

            // Clear current shop if it was deactivated or removed
            if (_currentShop != null &&
                !shops.any((s) => s.id == _currentShop!.id)) {
              _currentShop = null;
              await prefs.remove('currentShopId');
            }

            // Restore saved shop only if still active
            final savedShopId = prefs.getString('currentShopId');
            if (savedShopId != null && _currentShop == null) {
              try {
                _currentShop = shops.firstWhere((s) => s.id == savedShopId);
              } catch (_) {
                await prefs.remove('currentShopId');
              }
            }

            notifyListeners();
          },
          onError: (error) {
            _error = error.toString();
            _isLoading = false;
            print('❌ ShopProvider error: $error');
            notifyListeners();
          },
        );
  }

  Future<bool> createShop({
    required String name,
    required String ownerId,
    String? address,
    String? phone,
    String? currency,
  }) async {
    if (!await ConnectivityHelper.isOnline()) {
      _error = 'You need an internet connection to create a new shop';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    final shop = await _shopService.createShop(
      name: name,
      ownerId: ownerId,
      address: address,
      phone: phone,
      currency: currency,
    );

    _isLoading = false;
    if (shop != null) {
      // Refresh list automatically via stream
      return true;
    } else {
      _error = 'Failed to create shop';
      notifyListeners();
      return false;
    }
  }

  void setCurrentShop(ShopModel shop) async {
    _currentShop = shop;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currentShopId', shop.id);
    notifyListeners();
  }

  void clearCurrentShop() async {
    _currentShop = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('currentShopId');
    notifyListeners();
  }

  Future<bool> inviteStaff(
    String shopId,
    String email,
    String invitedByUserId,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final success = await _shopService.inviteStaff(
      shopId: shopId,
      email: email,
      invitedByUserId: invitedByUserId,
    );

    _isLoading = false;
    if (!success) {
      _error = 'User already a member or invitation failed';
      notifyListeners();
    }
    return success;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<RecordWriteResult> updateShop({
    required String shopId,
    required String name,
    String? address,
    String? phone,
    required String currency,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _shopService.updateShop(
      shopId: shopId,
      name: name,
      address: address,
      phone: phone,
      currency: currency,
    );

    _isLoading = false;
    if (!result.success) {
      _error = 'Failed to update shop';
      notifyListeners();
    }
    return result;
  }

  Future<RecordWriteResult> deleteShop(String shopId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _shopService.deleteShop(shopId);

    _isLoading = false;
    if (!result.success) {
      _error = 'Failed to delete shop';
      notifyListeners();
    } else {
      _shops = _shops.where((s) => s.id != shopId).toList();
      if (_currentShop?.id == shopId) {
        clearCurrentShop();
      } else {
        notifyListeners();
      }
    }
    return result;
  }

  Future<ShopModel?> getShopById(String shopId) async {
    final doc = await _firestore.collection('shops').doc(shopId).get();
    if (doc.exists) {
      final shop = ShopModel.fromMap(doc.id, doc.data()!);
      if (!shop.isActive) return null;
      return shop;
    }
    return null;
  }
}
