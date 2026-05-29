import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart'; // Add this for BuildContext
import '../../../core/services/profile_service.dart';

class ProfileProvider extends ChangeNotifier {
  final ProfileService _profileService = ProfileService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Map<String, dynamic>? _profile;
  bool _isLoading = false;
  String? _error;

  // Getters
  Map<String, dynamic>? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fix: Define _user properly
  User? get _user => _auth.currentUser; // This is likely what you need
  Future<void> loadProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Use the getter
      if (_user == null) {
        _error = 'User not authenticated';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final profile = await _profileService.getUserProfile(_user!.uid);

      if (profile != null) {
        _profile = profile;
      } else {
        _error = 'Profile not found';
      }
    } catch (e) {
      _error = 'Unable to load profile';
      debugPrint('Profile loading error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add this method for password change
  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Re-authenticate user before changing password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);

      _error = null;
    } catch (e) {
      _error = 'Failed to change password: ${e.toString()}';
      debugPrint('Password change error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add this method that updateUserProfile refers to
  Future<void> updateProfile(Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_user == null) throw Exception('User not authenticated');

      // Call the profile service method
      await _profileService.updateUserProfile(_user!.uid, data);

      // Update local profile data
      _profile = {...?profile, ...data};
      _error = null;
      debugPrint('Profile updated successfully');
    } catch (e) {
      _error = 'Failed to update profile: ${e.toString()}';
      debugPrint('Profile update error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
