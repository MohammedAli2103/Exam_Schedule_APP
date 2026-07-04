import 'package:flutter/foundation.dart';
import '../services/supabase_service.dart';
import '../services/notification_service.dart';
import '../models/study_session.dart';

class SessionRepository {
  // Singleton instance
  static final SessionRepository _instance = SessionRepository._internal();

  factory SessionRepository() {
    return _instance;
  }

  SessionRepository._internal();

  final SupabaseService _db = SupabaseService.instance;
  final NotificationService _notifications = NotificationService.instance;

  // Cache
  List<StudySession>? _cachedSessions;

  // Notification Status Flag
  bool notificationSchedulingFailed = false;

  /// Clears the sessions cache.
  void clearCache() {
    _cachedSessions = null;
  }

  /// Adds or updates a session in the local cache, preventing duplicates by checking ID.
  void _addOrUpdateInCache(StudySession session) {
    if (_cachedSessions == null) {
      _cachedSessions = [session];
      return;
    }
    final idx = _cachedSessions!.indexWhere((s) => s.id == session.id);
    if (idx != -1) {
      _cachedSessions![idx] = session;
    } else {
      _cachedSessions!.add(session);
    }
    _cachedSessions!.sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  /// Fetch all study sessions for the current user.
  Future<List<StudySession>> fetchSessions({bool forceRefresh = false}) async {
    debugPrint("[SessionRepository] fetchSessions() executed (forceRefresh: $forceRefresh)");
    if (!forceRefresh && _cachedSessions != null) {
      return _cachedSessions!;
    }

    // DEVELOPMENT ONLY
    // Replace with authenticated user before production.
    // final userId = _db.currentUser?.id;
    // if (userId == null) throw Exception("User is not authenticated");

    final List<dynamic> data = await _db.client
        .from('study_sessions')
        .select('*, subjects(name), study_session_chapters(chapters(*, notes(id)))')
        // .eq('user_id', userId)
        .order('start_time', ascending: true);

    _cachedSessions = data.map((json) => StudySession.fromJson(json)).toList();
    return _cachedSessions!;
  }

  Future<StudySession> createSession({
    required String subjectId,
    required String studyType,
    required List<String> chapterIds,
    required DateTime startTime,
    required DateTime endTime,
    String? notes,
  }) async {
    debugPrint("[SessionRepository] createSession() called");
    if (_cachedSessions != null) {
      debugPrint("[SessionRepository] session count before update: ${_cachedSessions!.length}");
    } else {
      debugPrint("[SessionRepository] session count before update: Cache is null");
    }

    // DEVELOPMENT ONLY
    // Replace with authenticated user before production.
    // final userId = _db.currentUser?.id;
    // if (userId == null) throw Exception("User is not authenticated");
    final userId = _db.currentUser?.id ?? '00000000-0000-0000-0000-000000000000';

    // 1. Insert session
    debugPrint("[SessionRepository] Supabase insert executed (inserting into study_sessions)");
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
    notificationSchedulingFailed = false;
    try {
      final result = await _notifications.scheduleSessionNotifications(session: session);
      if (!result) {
        notificationSchedulingFailed = true;
      }
    } catch (e) {
      notificationSchedulingFailed = true;
      debugPrint("Failed to schedule notifications: $e");
    }

    // 5. Update local cache
    _addOrUpdateInCache(session);
    debugPrint("[SessionRepository] session count after update: ${_cachedSessions?.length}");

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
    notificationSchedulingFailed = false;
    if (!isCompleted) {
      try {
        final result = await _notifications.scheduleSessionNotifications(session: session);
        if (!result) {
          notificationSchedulingFailed = true;
        }
      } catch (e) {
        notificationSchedulingFailed = true;
        debugPrint("Failed to schedule notifications: $e");
      }
    }

    // 5. Update local cache
    _addOrUpdateInCache(session);

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
    notificationSchedulingFailed = false;
    if (isCompleted) {
      await _notifications.cancelSessionNotifications(sessionId);
    } else {
      try {
        final result = await _notifications.scheduleSessionNotifications(session: session);
        if (!result) {
          notificationSchedulingFailed = true;
        }
      } catch (e) {
        notificationSchedulingFailed = true;
        debugPrint("Failed to schedule notifications: $e");
      }
    }

    // Update local cache
    _addOrUpdateInCache(session);

    return session;
  }

  /// Delete a study session.
  Future<void> deleteSession(String sessionId) async {
    // Cancel scheduled notifications
    await _notifications.cancelSessionNotifications(sessionId);

    // Delete session from DB (junction rows deleted via cascade)
    await _db.client.from('study_sessions').delete().eq('id', sessionId);

    // Update local cache
    if (_cachedSessions != null) {
      _cachedSessions!.removeWhere((s) => s.id == sessionId);
    }
  }
}

