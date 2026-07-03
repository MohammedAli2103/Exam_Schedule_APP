import '../services/supabase_service.dart';
import '../models/subject.dart';

class SubjectRepository {
  final SupabaseService _db = SupabaseService.instance;

  /// Fetches all subjects for the authenticated user along with their chapters and notes
  /// to compute counts and progress percentages dynamically.
  Future<List<Subject>> fetchSubjects() async {
    // DEVELOPMENT ONLY
    // Replace with authenticated user before production.
    // final userId = _db.currentUser?.id;
    // if (userId == null) throw Exception("User is not authenticated");

    final List<dynamic> data = await _db.client
        .from('subjects')
        .select('*, chapters(id, is_completed, notes(id))')
        // .eq('user_id', userId)
        .order('name', ascending: true);

    return data.map((json) {
      final chapters = json['chapters'] as List? ?? [];
      final chapterCount = chapters.length;
      final completedChapters = chapters.where((c) => c['is_completed'] == true).length;
      
      int notesCount = 0;
      for (var chapter in chapters) {
        final notes = chapter['notes'] as List? ?? [];
        notesCount += notes.length;
      }

      double progressPercentage = 0.0;
      if (chapterCount > 0) {
        progressPercentage = (completedChapters / chapterCount) * 100.0;
      }

      return Subject(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        name: json['name'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        chapterCount: chapterCount,
        notesCount: notesCount,
        progressPercentage: progressPercentage,
      );
    }).toList();
  }

  // Create Subject
  Future<Subject> createSubject(String name) async {
    // DEVELOPMENT ONLY
    // Replace with authenticated user before production.
    // final userId = _db.currentUser?.id;
    // if (userId == null) throw Exception("User is not authenticated");
    final userId = _db.currentUser?.id ?? '00000000-0000-0000-0000-000000000000';

    final Map<String, dynamic> data = await _db.client
        .from('subjects')
        .insert({
          'name': name,
          'user_id': userId,
        })
        .select()
        .single();

    return Subject.fromJson(data);
  }

  // Update Subject
  Future<Subject> updateSubject(String id, String name) async {
    final Map<String, dynamic> data = await _db.client
        .from('subjects')
        .update({'name': name})
        .eq('id', id)
        .select()
        .single();

    return Subject.fromJson(data);
  }

  // Delete Subject (Cascades deletion on Supabase side)
  Future<void> deleteSubject(String id) async {
    await _db.client.from('subjects').delete().eq('id', id);
  }
}
