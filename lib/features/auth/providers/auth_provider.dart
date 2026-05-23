import 'package:flutter/material.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;

  AuthProvider() {
    // Listen to Firebase auth state and refresh user
    _authService.userChanges.listen((firebaseUser) async {
      if (firebaseUser != null) {
        _isLoading = true;
        notifyListeners();
        _currentUser = await _authService.getCurrentUserModel();
        _isLoading = false;
        notifyListeners();
      } else {
        _currentUser = null;
        notifyListeners();
      }
    });
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _authService.signInWithEmail(email: email, password: password);
    _isLoading = false;
    if (result.error != null) {
      _error = result.error;
      notifyListeners();
      return false;
    }
    _currentUser = result.userModel;
    _error = null;
    notifyListeners();
    return true;
  }

  Future<bool> register(String email, String password, String name, UserRole role) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _authService.registerWithEmail(
      email: email,
      password: password,
      name: name,
      role: role,
    );
    _isLoading = false;
    if (result.error != null) {
      _error = result.error;
      notifyListeners();
      return false;
    }
    _currentUser = result.userModel;
    _error = null;
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    await _authService.signOut();
    _currentUser = null;
    notifyListeners();
  }

  Future<bool> isAdmin() async {
    return await _authService.isCurrentUserAdmin();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}