import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream of auth state changes (nullable User from Firebase)
  Stream<User?> get userChanges => _auth.authStateChanges();

  // Get current user's custom data from Firestore
  Future<UserModel?> getCurrentUserModel() async {
    final User? firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;
    final doc = await _firestore.collection('users').doc(firebaseUser.uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.id, doc.data()!);
  }

  // Sign in with email and password
  Future<({UserModel? userModel, String? error})> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final User? firebaseUser = result.user;
      if (firebaseUser == null) {
        return (userModel: null, error: 'Sign in failed – no user returned');
      }
      // Fetch user document from Firestore
      final doc = await _firestore.collection('users').doc(firebaseUser.uid).get();
      if (!doc.exists) {
        // Should not happen if you create user doc on registration
        return (userModel: null, error: 'User profile not found');
      }
      final userModel = UserModel.fromMap(doc.id, doc.data()!);
      return (userModel: userModel, error: null);
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No user found with this email.';
          break;
        case 'wrong-password':
          message = 'Incorrect password.';
          break;
        case 'invalid-email':
          message = 'Invalid email address.';
          break;
        default:
          message = 'Login failed: ${e.message}';
      }
      return (userModel: null, error: message);
    } catch (e) {
      return (userModel: null, error: 'Unexpected error: $e');
    }
  }

  // Register new user (owner or staff – we'll default to staff, admin cannot register)
  Future<({UserModel? userModel, String? error})> registerWithEmail({
    required String email,
    required String password,
    required String name,
    UserRole role = UserRole.staff, // default to staff, owners are created separately
  }) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final User? firebaseUser = result.user;
      if (firebaseUser == null) {
        return (userModel: null, error: 'Registration failed');
      }

      // Create user document in Firestore
      final userModel = UserModel(
        id: firebaseUser.uid,
        email: email.trim(),
        name: name.trim(),
        role: role,
        createdAt: DateTime.now(),
      );
      await _firestore.collection('users').doc(firebaseUser.uid).set(userModel.toMap());

      // Also create an entry in shopMembers later when invited to shop
      return (userModel: userModel, error: null);
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = 'This email is already registered.';
          break;
        case 'weak-password':
          message = 'Password is too weak.';
          break;
        case 'invalid-email':
          message = 'Invalid email address.';
          break;
        default:
          message = 'Registration failed: ${e.message}';
      }
      return (userModel: null, error: message);
    } catch (e) {
      return (userModel: null, error: 'Unexpected error: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Check if current user is admin (custom claim or explicit role)
  Future<bool> isCurrentUserAdmin() async {
    final User? firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return false;
    // Method 1: Check custom claim (set via Firebase Admin SDK)
    final idTokenResult = await firebaseUser.getIdTokenResult();
    if (idTokenResult.claims?['admin'] == true) return true;
    // Method 2: Fallback to Firestore user role (for safety)
    final doc = await _firestore.collection('users').doc(firebaseUser.uid).get();
    if (doc.exists && doc.data()?['role'] == 'admin') return true;
    return false;
  }

  // Special: create an admin user (only callable from a secure backend or manually)
  // Not exposed in the app – left for reference
}