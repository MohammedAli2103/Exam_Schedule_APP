import '../services/supabase_service.dart';
import '../models/chapter.dart';

class ChapterRepository {
  final SupabaseService _db = SupabaseService.instance;

  /// Fetch chapters for a given subject.
  Future<List<Chapter>> fetchChapters(String subjectId) async {
    final List<dynamic> data = await _db.client
        .from('chapters')
        .select('*, notes(id)')
        .eq('subject_id', subjectId)
        .order('created_at', ascending: true);

    return data.map((json) {
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

    return Chapter.fromJson(data);
  }

  // Toggle Chapter Completion Status
  Future<Chapter> toggleCompletion(String id, bool isCompleted) async {
    final Map<String, dynamic> data = await _db.client
        .from('chapters')
        .update({'is_completed': isCompleted})
        .eq('id', id)
        .select()
        .single();

    return Chapter.fromJson(data);
  }

  // Delete Chapter
  Future<void> deleteChapter(String id) async {
    await _db.client.from('chapters').delete().eq('id', id);
  }
}
