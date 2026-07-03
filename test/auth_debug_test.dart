import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:exam_preparation/services/supabase_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  test('Debug Supabase Auth and Insert', () async {
    print("--- START DIAGNOSTIC TEST ---");
    try {
      await SupabaseService.initialize();
      print("Supabase Initialized successfully.");
    } catch (e) {
      print("Supabase Initialization failed: $e");
      return;
    }

    final client = SupabaseService.instance.client;
    print("Initial currentUser: ${client.auth.currentUser}");

    try {
      print("Attempting Sign In...");
      final response = await client.auth.signInWithPassword(
        email: 'developer@example.com',
        password: 'developer_password',
      );
      print("Sign In succeeded. User ID: ${response.user?.id}");
    } catch (e) {
      print("Sign In failed: $e");
      print("Attempting Sign Up...");
      try {
        final response = await client.auth.signUp(
          email: 'developer@example.com',
          password: 'developer_password',
          data: {'full_name': 'Developer Account'},
        );
        print("Sign Up succeeded. User ID: ${response.user?.id}");
        print("Is Email Confirmed? ${response.user?.emailConfirmedAt}");
      } catch (signUpError) {
        print("Sign Up failed: $signUpError");
      }
    }

    print("Post-auth currentUser: ${client.auth.currentUser}");
    final user = client.auth.currentUser;
    final userId = user?.id ?? '00000000-0000-0000-0000-000000000000';

    try {
      print("Attempting to insert a subject with user_id: $userId...");
      final data = await client
          .from('subjects')
          .insert({
            'name': 'Test Subject ${DateTime.now().millisecondsSinceEpoch}',
            'user_id': userId,
          })
          .select()
          .single();
      print("Subject Insert Succeeded! Data: $data");
    } catch (e) {
      print("Subject Insert Failed: $e");
    }
  });
}
