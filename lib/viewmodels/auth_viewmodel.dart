import 'package:flutter/material.dart';
import '../repositories/auth_repository.dart';
import '../models/profile.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepo = AuthRepository();

  UserProfile? _profile;
  bool _isLoading = false;
  String? _errorMessage;

  UserProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Authentication temporarily disabled.
  // Restore before production release.
  bool get isAuthenticated => true; // _authRepo.isAuthenticated;

  // Initialize and check current user
  Future<void> checkAuthStatus() async {
    // Authentication temporarily disabled.
    // Restore before production release.
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // DEVELOPMENT ONLY: Auto login with developer credentials to satisfy database foreign keys.
      if (!_authRepo.isAuthenticated || _authRepo.currentUser == null) {
        try {
          await _authRepo.signIn(
            email: 'developer@example.com',
            password: 'developer_password',
          );
        } catch (e) {
          try {
            await _authRepo.signUp(
              email: 'developer@example.com',
              password: 'developer_password',
              fullName: 'Developer Account',
            );
          } catch (signUpError) {
            debugPrint("Auto-registration failed: $signUpError");
          }
        }
      }

      final user = _authRepo.currentUser;
      if (user != null) {
        _profile = await _authRepo.fetchProfile(user.id);
      }
    } catch (e) {
      _errorMessage = e.toString();
      _profile = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Register
  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await _authRepo.signUp(
        email: email,
        password: password,
        fullName: fullName,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Login
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await _authRepo.signIn(
        email: email,
        password: password,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Logout
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authRepo.signOut();
      _profile = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Forgot Password
  Future<bool> forgotPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _authRepo.sendPasswordResetEmail(email);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update Password
  Future<bool> updatePassword(String newPassword) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _authRepo.updatePassword(newPassword);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
