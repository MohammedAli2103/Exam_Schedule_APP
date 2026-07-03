import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../models/profile.dart';

class AuthRepository {
  final SupabaseService _supabaseService = SupabaseService.instance;

  User? get currentUser => _supabaseService.currentUser;
  bool get isAuthenticated => _supabaseService.isAuthenticated;

  // Sign Up
  Future<UserProfile> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final response = await _supabaseService.signUp(
      email: email,
      password: password,
      fullName: fullName,
    );

    if (response.user == null) {
      throw Exception("Sign up failed");
    }

    // Fetch the newly created profile
    return await fetchProfile(response.user!.id);
  }

  // Sign In
  Future<UserProfile> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _supabaseService.signIn(
      email: email,
      password: password,
    );

    if (response.user == null) {
      throw Exception("Sign in failed");
    }

    return await fetchProfile(response.user!.id);
  }

  // Sign Out
  Future<void> signOut() async {
    await _supabaseService.signOut();
  }

  // Forgot Password
  Future<void> sendPasswordResetEmail(String email) async {
    await _supabaseService.resetPassword(email);
  }

  // Update Password (when clicked reset link)
  Future<void> updatePassword(String newPassword) async {
    await _supabaseService.updateUserPassword(newPassword);
  }

  // Fetch User Profile
  Future<UserProfile> fetchProfile(String userId) async {
    final data = await _supabaseService.client
        .from('profiles')
        .select('*')
        .eq('id', userId)
        .single();
    return UserProfile.fromJson(data);
  }
}
