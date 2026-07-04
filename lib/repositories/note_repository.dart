import 'dart:io';
import '../services/supabase_service.dart';
import '../models/note.dart';
import 'chapter_repository.dart';
import 'subject_repository.dart';

class NoteRepository {
  // Singleton instance
  static final NoteRepository _instance = NoteRepository._internal();

  factory NoteRepository() {
    return _instance;
  }

  NoteRepository._internal();

  final SupabaseService _db = SupabaseService.instance;

  // Cache: chapterId -> list of notes
  final Map<String, List<Note>> _cachedNotes = {};

  /// Clears the notes cache.
  void clearCache({String? chapterId}) {
    if (chapterId != null) {
      _cachedNotes.remove(chapterId);
    } else {
      _cachedNotes.clear();
    }
  }

  /// Fetch notes for a given chapter.
  Future<List<Note>> fetchNotes(String chapterId, {bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedNotes.containsKey(chapterId)) {
      return _cachedNotes[chapterId]!;
    }

    final List<dynamic> data = await _db.client
        .from('notes')
        .select('*')
        .eq('chapter_id', chapterId)
        .order('created_at', ascending: true);

    final notes = data.map((json) => Note.fromJson(json)).toList();
    _cachedNotes[chapterId] = notes;
    return notes;
  }

  /// Upload note to storage, and then insert metadata into DB.
  Future<Note> uploadNote({
    required File file,
    required String chapterId,
    required String chapterName,
    required String subjectName,
    required String fileName,
  }) async {
    // 1. Upload to Supabase Storage
    final fileUrl = await _db.uploadNoteFile(
      file: file,
      subjectName: subjectName,
      chapterName: chapterName,
      fileName: fileName,
    );

    // Formulate storage path for DB reference to allow deletions
    // DEVELOPMENT ONLY
    // Replace with authenticated user before production.
    final userId = _db.currentUser?.id ?? '00000000-0000-0000-0000-000000000000';
    final cleanSubjectName = _sanitizeFolderName(subjectName);
    final cleanChapterName = _sanitizeFolderName(chapterName);
    final cleanFileName = _sanitizeFolderName(fileName);
    final filePath = '$userId/$cleanSubjectName/$cleanChapterName/$cleanFileName';
    final fileSize = await file.length();

    // 2. Save metadata in DB
    final Map<String, dynamic> data = await _db.client
        .from('notes')
        .insert({
          'chapter_id': chapterId,
          'name': fileName,
          'file_url': fileUrl,
          'file_path': filePath,
          'file_size': fileSize,
        })
        .select()
        .single();

    final note = Note.fromJson(data);

    // 3. Clear caches
    clearCache(chapterId: chapterId);
    ChapterRepository().clearCache();
    SubjectRepository().clearCache();

    return note;
  }

  /// Rename note metadata in database.
  Future<Note> renameNote(String id, String newName) async {
    final Map<String, dynamic> data = await _db.client
        .from('notes')
        .update({'name': newName})
        .eq('id', id)
        .select()
        .single();

    final note = Note.fromJson(data);
    clearCache(chapterId: note.chapterId);
    return note;
  }

  /// Delete note from storage and DB.
  Future<void> deleteNote(Note note) async {
    // 1. Delete from Supabase Storage
    try {
      await _db.deleteNoteFile(note.filePath);
    } catch (e) {
      // Log or handle storage deletion failure, but proceed to clear DB
      // in case the file was already deleted or doesn't exist in storage
    }

    // 2. Delete from DB
    await _db.client.from('notes').delete().eq('id', note.id);

    // 3. Clear caches
    clearCache(chapterId: note.chapterId);
    ChapterRepository().clearCache();
    SubjectRepository().clearCache();
  }

  String _sanitizeFolderName(String name) {
    return name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
  }
}

