import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/services/staff_service.dart';
import '../../../core/models/user_model.dart';
import '../../../core/models/shop_member_model.dart';
import '../../../core/models/invitation_model.dart';

class StaffProvider extends ChangeNotifier {
  final StaffService _staffService = StaffService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<InvitationModel> _shopInvitations = [];
  List<InvitationModel> get shopInvitations => _shopInvitations;

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
      inviterId: invitedByUserId,
      role: role,
    );
    _isLoading = false;
    if (!result.success) {
      _error = result.message;
      notifyListeners();
    } else {
      _error = null;
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

  Future<bool> acceptInvitation(String invitationId) async {
    _isLoading = true;
    notifyListeners();
    final user = _auth.currentUser;
    if (user == null) {
      _error = 'Not logged in';
      _isLoading = false;
      notifyListeners();
      return false;
    }
    final result = await _staffService.acceptInvitation(invitationId, user.uid);
    _isLoading = false;
    if (!result.success) {
      _error = result.message;
      notifyListeners();
      return false;
    }
    return true;
  }

  Future<bool> declineInvitation(String invitationId) async {
    _isLoading = true;
    notifyListeners();
    final user = _auth.currentUser;
    if (user == null) {
      _error = 'Not logged in';
      _isLoading = false;
      notifyListeners();
      return false;
    }
    final result = await _staffService.declineInvitation(
      invitationId,
      user.uid,
    );
    _isLoading = false;
    if (!result.success) {
      _error = result.message;
      notifyListeners();
      return false;
    }
    return true;
  }

  Stream<List<InvitationModel>> getPendingInvitations(String userId) {
    return _firestore
        .collection('invitations')
        .where('inviteeUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => InvitationModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Stream<List<InvitationModel>> getPendingInvitationsForShop(String shopId) {
    return _staffService.getPendingInvitationsForShop(shopId);
  }

  Stream<List<InvitationModel>> getAllInvitationsForShop(String shopId) {
    return _staffService.getAllInvitationsForShop(shopId);
  }

  Stream<List<Map<String, dynamic>>> getPendingInvitationsWithShop() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);
    return _staffService.getPendingInvitationsWithShop(user.uid);
  }

  Future<void> loadShopInvitations(String shopId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final snapshot = await _firestore
          .collection('invitations')
          .where('shopId', isEqualTo: shopId)
          .get();
      final list = snapshot.docs
          .map((doc) => InvitationModel.fromMap(doc.id, doc.data()))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _shopInvitations = list;
      _error = null;
    } catch (e) {
      print('loadShopInvitations error: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
