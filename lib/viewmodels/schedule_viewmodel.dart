import 'dart:async';
import 'package:flutter/material.dart';
import '../models/study_session.dart';
import '../repositories/session_repository.dart';

class ScheduleViewModel extends ChangeNotifier {
  final SessionRepository _sessionRepo = SessionRepository();

  List<StudySession> _sessions = [];
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  String? _errorMessage;

  Timer? _dateCheckTimer;
  DateTime _lastCheckedToday = DateUtils.dateOnly(DateTime.now());
  bool _notificationSchedulingFailed = false;

  bool get notificationSchedulingFailed => _notificationSchedulingFailed;

  ScheduleViewModel() {
    _startTodayDateChecker();
  }

  void _startTodayDateChecker() {
    _dateCheckTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      final currentToday = DateUtils.dateOnly(DateTime.now());
      if (currentToday != _lastCheckedToday) {
        final wasTodaySelected = DateUtils.isSameDay(_selectedDate, _lastCheckedToday);
        _lastCheckedToday = currentToday;
        if (wasTodaySelected) {
          _selectedDate = currentToday;
        }
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _dateCheckTimer?.cancel();
    super.dispose();
  }

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

  bool _isSessionsLoaded = false;
  bool get isSessionsLoaded => _isSessionsLoaded;

  Future<void> fetchSessions({bool forceRefresh = false}) async {
    if (!_isSessionsLoaded || forceRefresh) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      _sessions = await _sessionRepo.fetchSessions(forceRefresh: forceRefresh);
      _isSessionsLoaded = true;
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
      await _sessionRepo.createSession(
        subjectId: subjectId,
        studyType: studyType,
        chapterIds: chapterIds,
        startTime: startTime,
        endTime: endTime,
        notes: notes,
      );
      _notificationSchedulingFailed = _sessionRepo.notificationSchedulingFailed;
      _sessions = await _sessionRepo.fetchSessions();
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
      await _sessionRepo.updateSession(
        sessionId: sessionId,
        subjectId: subjectId,
        studyType: studyType,
        chapterIds: chapterIds,
        startTime: startTime,
        endTime: endTime,
        isCompleted: isCompleted,
        notes: notes,
      );
      _notificationSchedulingFailed = _sessionRepo.notificationSchedulingFailed;
      _sessions = await _sessionRepo.fetchSessions();
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

      await _sessionRepo.createSession(
        subjectId: session.subjectId,
        studyType: session.studyType,
        chapterIds: chapterIds,
        startTime: newStart,
        endTime: newEnd,
        notes: session.notes,
      );

      _notificationSchedulingFailed = _sessionRepo.notificationSchedulingFailed;
      _sessions = await _sessionRepo.fetchSessions();
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
      await _sessionRepo.toggleSessionCompletion(sessionId, isCompleted);
      _sessions = await _sessionRepo.fetchSessions();
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
