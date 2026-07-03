import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'supabase_service.dart';

class BackupService {
  static final BackupService instance = BackupService._internal();
  BackupService._internal();

  final SupabaseService _db = SupabaseService.instance;

  /// Exports all user data into a JSON file and prompts the user to share/save it.
  Future<void> exportData() async {
    // DEVELOPMENT ONLY
    // Replace with authenticated user before production.
    // final userId = _db.currentUser?.id;
    // if (userId == null) throw Exception("User not logged in");
    final userId = _db.currentUser?.id ?? '00000000-0000-0000-0000-000000000000';

    // Fetch subjects
    final subjectsResponse = await _db.client
        .from('subjects')
        .select('id, name, created_at');
        // .eq('user_id', userId);

    // Fetch chapters (sub-query or load via subjects)
    final subjectIds = (subjectsResponse as List).map((s) => s['id'] as String).toList();
    List<dynamic> chaptersResponse = [];
    List<dynamic> notesResponse = [];

    if (subjectIds.isNotEmpty) {
      chaptersResponse = await _db.client
          .from('chapters')
          .select('id, subject_id, name, is_completed, created_at')
          .inFilter('subject_id', subjectIds);

      final chapterIds = chaptersResponse.map((c) => c['id'] as String).toList();
      if (chapterIds.isNotEmpty) {
        notesResponse = await _db.client
            .from('notes')
            .select('id, chapter_id, name, file_url, file_path, file_size, created_at')
            .inFilter('chapter_id', chapterIds);
      }
    }

    // Fetch study sessions
    final sessionsResponse = await _db.client
        .from('study_sessions')
        .select('id, subject_id, study_type, notes, start_time, end_time, is_completed, created_at');
        // .eq('user_id', userId);

    // Fetch study session chapters relationships
    final sessionIds = (sessionsResponse as List).map((s) => s['id'] as String).toList();
    List<dynamic> sessionChaptersResponse = [];
    if (sessionIds.isNotEmpty) {
      sessionChaptersResponse = await _db.client
          .from('study_session_chapters')
          .select('study_session_id, chapter_id')
          .inFilter('study_session_id', sessionIds);
    }

    // Fetch profile
    final profileResponse = await _db.client
        .from('profiles')
        .select('streak_count, last_study_date')
        .eq('id', userId)
        .maybeSingle();

    // Assemble payload
    final Map<String, dynamic> backupData = {
      'version': '1.0',
      'user_id': userId,
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'profile': profileResponse,
      'subjects': subjectsResponse,
      'chapters': chaptersResponse,
      'notes': notesResponse,
      'study_sessions': sessionsResponse,
      'study_session_chapters': sessionChaptersResponse,
    };

    // Save to local file
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/ExamPrep_Backup_${DateTime.now().millisecondsSinceEpoch}.json');
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(backupData));

    // Share the file
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'My Exam Preparation Backup Data',
    );
  }

  /// Restores user data from a selected JSON backup file.
  /// Inserts records into subjects, chapters, notes, study_sessions, and junction table.
  Future<void> restoreData() async {
    // DEVELOPMENT ONLY
    // Replace with authenticated user before production.
    // final userId = _db.currentUser?.id;
    // if (userId == null) throw Exception("User not logged in");
    final userId = _db.currentUser?.id ?? '00000000-0000-0000-0000-000000000000';

    // Let user pick the file
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null || result.files.single.path == null) {
      return; // Canceled
    }

    final file = File(result.files.single.path!);
    final jsonStr = await file.readAsString();
    final backupData = jsonDecode(jsonStr) as Map<String, dynamic>;

    if (backupData['version'] == null) {
      throw Exception("Invalid backup file format");
    }

    final subjects = backupData['subjects'] as List<dynamic>;
    final chapters = backupData['chapters'] as List<dynamic>;
    final notes = backupData['notes'] as List<dynamic>;
    final studySessions = backupData['study_sessions'] as List<dynamic>;
    final studySessionChapters = backupData['study_session_chapters'] as List<dynamic>;

    // Restore profile statistics
    final profile = backupData['profile'];
    if (profile != null) {
      await _db.client.from('profiles').update({
        'streak_count': profile['streak_count'],
        'last_study_date': profile['last_study_date'],
      }).eq('id', userId);
    }

    // Restore Subjects (use upsert to handle existing ids)
    if (subjects.isNotEmpty) {
      final subjectsToInsert = subjects.map((s) {
        return {
          'id': s['id'],
          'user_id': userId,
          'name': s['name'],
          'created_at': s['created_at'],
        };
      }).toList();
      await _db.client.from('subjects').upsert(subjectsToInsert);
    }

    // Restore Chapters
    if (chapters.isNotEmpty) {
      final chaptersToInsert = chapters.map((c) {
        return {
          'id': c['id'],
          'subject_id': c['subject_id'],
          'name': c['name'],
          'is_completed': c['is_completed'],
          'created_at': c['created_at'],
        };
      }).toList();
      await _db.client.from('chapters').upsert(chaptersToInsert);
    }

    // Restore Notes
    if (notes.isNotEmpty) {
      final notesToInsert = notes.map((n) {
        return {
          'id': n['id'],
          'chapter_id': n['chapter_id'],
          'name': n['name'],
          'file_url': n['file_url'],
          'file_path': n['file_path'],
          'file_size': n['file_size'],
          'created_at': n['created_at'],
        };
      }).toList();
      await _db.client.from('notes').upsert(notesToInsert);
    }

    // Restore Study Sessions
    if (studySessions.isNotEmpty) {
      final sessionsToInsert = studySessions.map((s) {
        return {
          'id': s['id'],
          'user_id': userId,
          'subject_id': s['subject_id'],
          'study_type': s['study_type'],
          'notes': s['notes'],
          'start_time': s['start_time'],
          'end_time': s['end_time'],
          'is_completed': s['is_completed'],
          'created_at': s['created_at'],
        };
      }).toList();
      await _db.client.from('study_sessions').upsert(sessionsToInsert);
    }

    // Restore study session chapters relationships
    if (studySessionChapters.isNotEmpty) {
      final relationToInsert = studySessionChapters.map((sc) {
        return {
          'study_session_id': sc['study_session_id'],
          'chapter_id': sc['chapter_id'],
        };
      }).toList();
      await _db.client.from('study_session_chapters').upsert(relationToInsert);
    }
  }
}
