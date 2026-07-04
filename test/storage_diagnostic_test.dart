import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:exam_preparation/services/supabase_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  test('Diagnose Supabase Storage Buckets', () async {
    print("--- START STORAGE DIAGNOSTIC TEST ---");
    try {
      await SupabaseService.initialize();
      print("Supabase Initialized successfully.");
    } catch (e) {
      print("Supabase Initialization failed: $e");
      return;
    }

    final client = SupabaseService.instance.client;

    try {
      print("Signing in developer account...");
      final authResponse = await client.auth.signInWithPassword(
        email: 'developer@example.com',
        password: 'developer_password',
      );
      print("Signed in as: ${authResponse.user?.email}");
    } catch (e) {
      print("Sign in failed (might be signing up instead): $e");
      try {
        final authResponse = await client.auth.signUp(
          email: 'developer@example.com',
          password: 'developer_password',
        );
        print("Signed up as: ${authResponse.user?.email}");
      } catch (signUpError) {
        print("Sign up failed: $signUpError");
      }
    }

    print("\n--- Listing Buckets ---");
    try {
      final buckets = await client.storage.listBuckets();
      print("Buckets currently configured in Supabase:");
      for (var b in buckets) {
        print("  - ID: '${b.id}', Name: '${b.name}', Public: ${b.public}");
      }
    } catch (e) {
      print("Error listing buckets: $e");
    }

    print("\n--- Done ---");
  });
}
