import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/constants.dart';

class SupabaseService {
  static final SupabaseService instance = SupabaseService._internal();

  SupabaseService._internal();

  SupabaseClient get client => Supabase.instance.client;

  User? get currentUser => client.auth.currentUser;

  Session? get currentSession => client.auth.currentSession;

  bool get isAuthenticated => currentUser != null;

  // Initialize Supabase
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      publishableKey: AppConstants.supabaseAnonKey,
    );
  }

  // --- AUTHENTICATION ---

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    return await client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await client.auth.resetPasswordForEmail(email);
  }

  Future<UserResponse> updateUserPassword(String newPassword) async {
    return await client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  // --- STORAGE ---

  /// Upload note file to Supabase storage.
  /// Path: user_id/subject_name/chapter_name/filename.ext
  Future<String> uploadNoteFile({
    required File file,
    required String subjectName,
    required String chapterName,
    required String fileName,
  }) async {
    // DEVELOPMENT ONLY
    // Replace with authenticated user before production.
    // if (currentUser == null) throw Exception("User is not authenticated");
    final userId = currentUser?.id ?? '00000000-0000-0000-0000-000000000000';
    
    // Clean strings to prevent folder path issues
    final cleanSubjectName = _sanitizeFolderName(subjectName);
    final cleanChapterName = _sanitizeFolderName(chapterName);
    final cleanFileName = _sanitizeFolderName(fileName);

    final storagePath = '$userId/$cleanSubjectName/$cleanChapterName/$cleanFileName';

    // Upload file to the storage bucket
    await client.storage.from(AppConstants.storageBucketName).upload(
          storagePath,
          file,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
        );

    // Get public URL
    final fileUrl = client.storage
        .from(AppConstants.storageBucketName)
        .getPublicUrl(storagePath);

    return fileUrl;
  }

  /// Delete note file from Supabase storage
  Future<void> deleteNoteFile(String filePath) async {
    await client.storage.from(AppConstants.storageBucketName).remove([filePath]);
  }

  String _sanitizeFolderName(String name) {
    return name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
  }
}
