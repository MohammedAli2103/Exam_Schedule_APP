import '../services/supabase_service.dart';
import '../models/chapter.dart';
import 'subject_repository.dart';

class ChapterRepository {
  // Singleton instance
  static final ChapterRepository _instance = ChapterRepository._internal();

  factory ChapterRepository() {
    return _instance;
  }

  ChapterRepository._internal();

  final SupabaseService _db = SupabaseService.instance;

  // Cache: subjectId -> list of chapters
  final Map<String, List<Chapter>> _cachedChapters = {};

  /// Clears the chapters cache.
  void clearCache({String? subjectId}) {
    if (subjectId != null) {
      _cachedChapters.remove(subjectId);
    } else {
      _cachedChapters.clear();
    }
  }

  /// Fetch chapters for a given subject.
  Future<List<Chapter>> fetchChapters(String subjectId, {bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedChapters.containsKey(subjectId)) {
      return _cachedChapters[subjectId]!;
    }

    final List<dynamic> data = await _db.client
        .from('chapters')
        .select('*, notes(id)')
        .eq('subject_id', subjectId)
        .order('created_at', ascending: true);

    final chapters = data.map((json) {
      final notes = json['notes'] as List? ?? [];
      return Chapter(
        id: json['id'] as String,
        subjectId: json['subject_id'] as String,
        name: json['name'] as String,
        isCompleted: json['is_completed'] as bool? ?? false,
        createdAt: DateTime.parse(json['created_at'] as String),
        notesCount: notes.length,
      );
    }).toList();

    _cachedChapters[subjectId] = chapters;
    return chapters;
  }

  // Create Chapter
  Future<Chapter> createChapter(String subjectId, String name) async {
    final Map<String, dynamic> data = await _db.client
        .from('chapters')
        .insert({
          'subject_id': subjectId,
          'name': name,
          'is_completed': false,
        })
        .select()
        .single();

    clearCache(subjectId: subjectId);
    SubjectRepository().clearCache();
    return Chapter.fromJson(data);
  }

  // Rename Chapter
  Future<Chapter> renameChapter(String id, String newName) async {
    final Map<String, dynamic> data = await _db.client
        .from('chapters')
        .update({'name': newName})
        .eq('id', id)
        .select()
        .single();

    final chapter = Chapter.fromJson(data);
    clearCache(subjectId: chapter.subjectId);
    SubjectRepository().clearCache();
    return chapter;
  }

  // Toggle Chapter Completion Status
  Future<Chapter> toggleCompletion(String id, bool isCompleted) async {
    final Map<String, dynamic> data = await _db.client
        .from('chapters')
        .update({'is_completed': isCompleted})
        .eq('id', id)
        .select()
        .single();

    final chapter = Chapter.fromJson(data);
    clearCache(subjectId: chapter.subjectId);
    SubjectRepository().clearCache();
    return chapter;
  }

  // Delete Chapter
  Future<void> deleteChapter(String id) async {
    // We need to know the subjectId to clear the cache before deleting.
    final Map<String, dynamic>? data = await _db.client
        .from('chapters')
        .select('subject_id')
        .eq('id', id)
        .maybeSingle();

    await _db.client.from('chapters').delete().eq('id', id);

    if (data != null) {
      final subjectId = data['subject_id'] as String;
      clearCache(subjectId: subjectId);
    } else {
      clearCache();
    }
    SubjectRepository().clearCache();
  }
}

