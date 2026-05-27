import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Update user's display name in Firebase Auth and Firestore
  Future<bool> updateName(String newName) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      // Update in Auth (optional, but good for display name)
      await user.updateDisplayName(newName);
      // Update in Firestore
      await _firestore.collection('users').doc(user.uid).update({'name': newName});
      return true;
    } catch (e) {
      print('Update name error: $e');
      return false;
    }
  }

  /// Update user's phone number in Firestore only (Auth phone is separate)
  Future<bool> updatePhone(String newPhone) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      await _firestore.collection('users').doc(user.uid).update({'phone': newPhone});
      return true;
    } catch (e) {
      print('Update phone error: $e');
      return false;
    }
  }

  /// Change password (requires re-authentication for security)
  Future<({bool success, String? error})> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return (success: false, error: 'Not logged in');
      
      // Re-authenticate user
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      
      // Update password
      await user.updatePassword(newPassword);
      return (success: true, error: null);
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'wrong-password':
          message = 'Current password is incorrect';
          break;
        case 'weak-password':
          message = 'New password is too weak';
          break;
        default:
          message = e.message ?? 'Password change failed';
      }
      return (success: false, error: message);
    } catch (e) {
      return (success: false, error: e.toString());
    }
  }
}