import 'package:flutter/material.dart';
import '../models/study_session.dart';
import '../repositories/session_repository.dart';

class ScheduleViewModel extends ChangeNotifier {
  final SessionRepository _sessionRepo = SessionRepository();

  List<StudySession> _sessions = [];
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  String? _errorMessage;

  List<StudySession> get allSessions => _sessions;
  DateTime get selectedDate => _selectedDate;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Returns study sessions scheduled on the selected date.
  List<StudySession> get sessionsForSelectedDate {
    return _sessions.where((session) {
      final start = session.startTime;
      return start.year == _selectedDate.year &&
          start.month == _selectedDate.month &&
          start.day == _selectedDate.day;
    }).toList();
  }

  void changeSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  Future<void> fetchSessions() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _sessions = await _sessionRepo.fetchSessions();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createSession({
    required String subjectId,
    required String studyType,
    required List<String> chapterIds,
    required DateTime startTime,
    required DateTime endTime,
    String? notes,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final newSession = await _sessionRepo.createSession(
        subjectId: subjectId,
        studyType: studyType,
        chapterIds: chapterIds,
        startTime: startTime,
        endTime: endTime,
        notes: notes,
      );
      _sessions.add(newSession);
      _sessions.sort((a, b) => a.startTime.compareTo(b.startTime));
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateSession({
    required String sessionId,
    required String subjectId,
    required String studyType,
    required List<String> chapterIds,
    required DateTime startTime,
    required DateTime endTime,
    required bool isCompleted,
    String? notes,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final updated = await _sessionRepo.updateSession(
        sessionId: sessionId,
        subjectId: subjectId,
        studyType: studyType,
        chapterIds: chapterIds,
        startTime: startTime,
        endTime: endTime,
        isCompleted: isCompleted,
        notes: notes,
      );

      final idx = _sessions.indexWhere((s) => s.id == sessionId);
      if (idx != -1) {
        _sessions[idx] = updated;
        _sessions.sort((a, b) => a.startTime.compareTo(b.startTime));
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Duplicates an existing study session details, shifting the timing by exactly 24 hours (next day).
  Future<bool> duplicateSession(StudySession session) async {
    _isLoading = true;
    notifyListeners();

    try {
      final newStart = session.startTime.add(const Duration(days: 1));
      final newEnd = session.endTime.add(const Duration(days: 1));
      final chapterIds = session.chapters.map((c) => c.id).toList();

      final newSession = await _sessionRepo.createSession(
        subjectId: session.subjectId,
        studyType: session.studyType,
        chapterIds: chapterIds,
        startTime: newStart,
        endTime: newEnd,
        notes: session.notes,
      );

      _sessions.add(newSession);
      _sessions.sort((a, b) => a.startTime.compareTo(b.startTime));
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteSession(String sessionId) async {
    try {
      await _sessionRepo.deleteSession(sessionId);
      _sessions.removeWhere((s) => s.id == sessionId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> toggleSessionCompletion(String sessionId, bool isCompleted) async {
    try {
      final updated = await _sessionRepo.toggleSessionCompletion(sessionId, isCompleted);
      final idx = _sessions.indexWhere((s) => s.id == sessionId);
      if (idx != -1) {
        _sessions[idx] = updated;
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
