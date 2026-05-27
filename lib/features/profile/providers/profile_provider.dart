import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/profile_service.dart';
import '../../../core/models/user_model.dart';

class ProfileProvider extends ChangeNotifier {
  final ProfileService _profileService = ProfileService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadUserProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final userId = _auth.currentUser?.uid;
      print('🔍 loadUserProfile - userId: $userId');
      if (userId == null) {
        _error = 'Not logged in';
        print('❌ No user logged in');
        return;
      }
      final doc = await _firestore.collection('users').doc(userId).get();
      print('📄 Document exists: ${doc.exists}');
      if (!doc.exists) {
        _error = 'User profile not found';
        print('❌ User document missing for uid: $userId');
        // Optionally create the document
        final defaultUser = UserModel(
          id: userId,
          email: _auth.currentUser!.email!,
          name:
              _auth.currentUser!.displayName ??
              _auth.currentUser!.email!.split('@')[0],
          role: UserRole.staff,
          createdAt: DateTime.now(),
        );
        await _firestore
            .collection('users')
            .doc(userId)
            .set(defaultUser.toMap());
        print('✅ Created missing user document');
        // Reload
        final newDoc = await _firestore.collection('users').doc(userId).get();
        _user = UserModel.fromMap(newDoc.id, newDoc.data()!);
        _error = null;
      } else {
        _user = UserModel.fromMap(doc.id, doc.data()!);
        print('✅ User loaded: ${_user!.name}');
        _error = null;
      }
    } catch (e, stack) {
      print('❌ Error loading profile: $e');
      print(stack);
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateName(String newName) async {
    _isLoading = true;
    notifyListeners();
    final success = await _profileService.updateName(newName);
    if (success) {
      _user = _user?.copyWith(name: newName);
    } else {
      _error = 'Failed to update name';
    }
    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> updatePhone(String newPhone) async {
    _isLoading = true;
    notifyListeners();
    final success = await _profileService.updatePhone(newPhone);
    if (success) {
      _user = _user?.copyWith(phone: newPhone);
    } else {
      _error = 'Failed to update phone';
    }
    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<({bool success, String? error})> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _isLoading = true;
    notifyListeners();
    final result = await _profileService.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
    _isLoading = false;
    notifyListeners();
    return result;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
