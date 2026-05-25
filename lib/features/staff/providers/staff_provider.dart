import 'package:flutter/material.dart';
import '../../../core/services/staff_service.dart';
import '../../../core/models/user_model.dart';
import '../../../core/models/shop_member_model.dart';

class StaffProvider extends ChangeNotifier {
  final StaffService _staffService = StaffService();
  List<({UserModel user, MemberRole role, DateTime joinedAt})> _members = [];
  bool _isLoading = false;
  String? _error;

  List get members => _members;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void loadMembers(String shopId) {
    _isLoading = true;
    notifyListeners();
    _staffService
        .getShopMembers(shopId)
        .listen(
          (members) {
            _members = members;
            _isLoading = false;
            _error = null;
            notifyListeners();
          },
          onError: (err) {
            _error = err.toString();
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  Future<bool> inviteStaff({
    required String shopId,
    required String email,
    required String invitedByUserId,
    required MemberRole role,
  }) async {
    _isLoading = true;
    notifyListeners();
    final result = await _staffService.inviteStaff(
      shopId: shopId,
      email: email,
      invitedByUserId: invitedByUserId,
      role: role,
    );
    _isLoading = false;
    if (!result.success) {
      _error = result.message;
      notifyListeners();
    }
    return result.success;
  }

  Future<bool> removeStaff(String shopId, String userId) async {
    _isLoading = true;
    notifyListeners();
    final success = await _staffService.removeStaff(shopId, userId);
    _isLoading = false;
    if (!success) {
      _error = 'Failed to remove staff';
      notifyListeners();
    } else {
      _error = null;
    }
    return success;
  }

  Future<bool> updateMemberRole(
    String shopId,
    String userId,
    MemberRole newRole,
  ) async {
    _isLoading = true;
    notifyListeners();
    final success = await _staffService.updateMemberRole(
      shopId,
      userId,
      newRole,
    );
    _isLoading = false;
    if (!success) {
      _error = 'Failed to update role';
      notifyListeners();
    } else {
      _error = null;
    }
    return success;
  }

  Future<bool> updateUserDetails(
    String userId, {
    String? name,
    String? phone,
  }) async {
    _isLoading = true;
    notifyListeners();
    final success = await _staffService.updateUserDetails(
      userId,
      name: name,
      phone: phone,
    );
    _isLoading = false;
    if (!success) {
      _error = 'Failed to update user details';
      notifyListeners();
    }
    return success;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
