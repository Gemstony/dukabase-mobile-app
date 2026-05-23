import 'package:flutter/material.dart';
import '../../../core/services/shop_service.dart';
import '../../../core/models/shop_model.dart';

class ShopProvider extends ChangeNotifier {
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
          (shops) {
            _shops = shops;
            _isLoading = false;
            _error = null;
            print('✅ ShopProvider: received ${shops.length} shops');
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

  void setCurrentShop(ShopModel shop) {
    _currentShop = shop;
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
}
