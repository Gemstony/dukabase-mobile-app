import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/shop_service.dart';
import '../../../core/models/shop_model.dart';

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
            print('✅ ShopProvider: received ${shops.length} shops');
            
            // Try to restore previous current shop
            final prefs = await SharedPreferences.getInstance();
            final savedShopId = prefs.getString('currentShopId');
            if (savedShopId != null && _currentShop == null) {
              try {
                _currentShop = shops.firstWhere((s) => s.id == savedShopId);
              } catch (_) {
                // Shop not found in list, maybe it was deleted or permissions changed
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

  Future<bool> updateShop({
    required String shopId,
    required String name,
    String? address,
    String? phone,
    required String currency,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final shopRef = _firestore.collection('shops').doc(shopId);
      await shopRef.update({
        'name': name,
        'address': address,
        'phone': phone,
        'currency': currency,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteShop(String shopId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _firestore.collection('shops').doc(shopId).update({
        'isActive': false,
        'deletedAt': FieldValue.serverTimestamp(),
      });
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<ShopModel?> getShopById(String shopId) async {
    final doc = await _firestore.collection('shops').doc(shopId).get();
    if (doc.exists) {
      return ShopModel.fromMap(doc.id, doc.data()!);
    }
    return null;
  }
}
