import '../services/supabase_service.dart';
import '../services/notification_service.dart';
import '../models/study_session.dart';

class SessionRepository {
  final SupabaseService _db = SupabaseService.instance;
  final NotificationService _notifications = NotificationService.instance;

  /// Fetch all study sessions for the current user.
  Future<List<StudySession>> fetchSessions() async {
    // DEVELOPMENT ONLY
    // Replace with authenticated user before production.
    // final userId = _db.currentUser?.id;
    // if (userId == null) throw Exception("User is not authenticated");

    final List<dynamic> data = await _db.client
        .from('study_sessions')
        .select('*, subjects(name), study_session_chapters(chapters(*, notes(id)))')
        // .eq('user_id', userId)
        .order('start_time', ascending: true);

    return data.map((json) => StudySession.fromJson(json)).toList();
  }

  /// Create a new study session with associated chapters.
  Future<StudySession> createSession({
    required String subjectId,
    required String studyType,
    required List<String> chapterIds,
    required DateTime startTime,
    required DateTime endTime,
    String? notes,
  }) async {
    // DEVELOPMENT ONLY
    // Replace with authenticated user before production.
    // final userId = _db.currentUser?.id;
    // if (userId == null) throw Exception("User is not authenticated");
    final userId = _db.currentUser?.id ?? '00000000-0000-0000-0000-000000000000';

    // 1. Insert session
    final Map<String, dynamic> sessionData = await _db.client
        .from('study_sessions')
        .insert({
          'user_id': userId,
          'subject_id': subjectId,
          'study_type': studyType,
          'notes': notes,
          'start_time': startTime.toUtc().toIso8601String(),
          'end_time': endTime.toUtc().toIso8601String(),
          'is_completed': false,
        })
        .select('*, subjects(name)')
        .single();

    final sessionId = sessionData['id'] as String;

    // 2. Insert session-chapter mappings
    if (chapterIds.isNotEmpty) {
      final List<Map<String, dynamic>> mappings = chapterIds.map((cId) {
        return {
          'study_session_id': sessionId,
          'chapter_id': cId,
        };
      }).toList();

      await _db.client.from('study_session_chapters').insert(mappings);
    }

    // 3. Fetch full session structure with chapters to return
    final fullSessionData = await _db.client
        .from('study_sessions')
        .select('*, subjects(name), study_session_chapters(chapters(*, notes(id)))')
        .eq('id', sessionId)
        .single();

    final session = StudySession.fromJson(fullSessionData);

    // 4. Schedule Local Notifications
    await _notifications.scheduleSessionNotifications(session: session);

    return session;
  }

  /// Update an existing study session details and chapter selections.
  Future<StudySession> updateSession({
    required String sessionId,
    required String subjectId,
    required String studyType,
    required List<String> chapterIds,
    required DateTime startTime,
    required DateTime endTime,
    required bool isCompleted,
    String? notes,
  }) async {
    // 1. Update session columns
    await _db.client.from('study_sessions').update({
      'subject_id': subjectId,
      'study_type': studyType,
      'notes': notes,
      'start_time': startTime.toUtc().toIso8601String(),
      'end_time': endTime.toUtc().toIso8601String(),
      'is_completed': isCompleted,
    }).eq('id', sessionId);

    // 2. Refresh chapters mappings: Delete all old mappings and insert new ones
    await _db.client
        .from('study_session_chapters')
        .delete()
        .eq('study_session_id', sessionId);

    if (chapterIds.isNotEmpty) {
      final List<Map<String, dynamic>> mappings = chapterIds.map((cId) {
        return {
          'study_session_id': sessionId,
          'chapter_id': cId,
        };
      }).toList();

      await _db.client.from('study_session_chapters').insert(mappings);
    }

    // 3. Get updated full session
    final fullSessionData = await _db.client
        .from('study_sessions')
        .select('*, subjects(name), study_session_chapters(chapters(*, notes(id)))')
        .eq('id', sessionId)
        .single();

    final session = StudySession.fromJson(fullSessionData);

    // 4. Reschedule local notifications (cancel old ones first)
    await _notifications.cancelSessionNotifications(sessionId);
    if (!isCompleted) {
      await _notifications.scheduleSessionNotifications(session: session);
    }

    return session;
  }

  /// Mark study session completed
  Future<StudySession> toggleSessionCompletion(String sessionId, bool isCompleted) async {
    final Map<String, dynamic> sessionData = await _db.client
        .from('study_sessions')
        .update({'is_completed': isCompleted})
        .eq('id', sessionId)
        .select('*, subjects(name), study_session_chapters(chapters(*, notes(id)))')
        .single();

    final session = StudySession.fromJson(sessionData);

    // Cancel or reschedule notifications
    if (isCompleted) {
      await _notifications.cancelSessionNotifications(sessionId);
    } else {
      await _notifications.scheduleSessionNotifications(session: session);
    }

    return session;
  }

  /// Delete a study session.
  Future<void> deleteSession(String sessionId) async {
    // Cancel scheduled notifications
    await _notifications.cancelSessionNotifications(sessionId);

    // Delete session from DB (junction rows deleted via cascade)
    await _db.client.from('study_sessions').delete().eq('id', sessionId);
  }
}
