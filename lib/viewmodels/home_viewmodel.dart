import 'dart:async';
import 'package:flutter/material.dart';
import '../models/study_session.dart';
import '../repositories/session_repository.dart';

class HomeViewModel extends ChangeNotifier {
  final SessionRepository _sessionRepo = SessionRepository();

  List<StudySession> _allSessions = [];
  StudySession? _currentSession;
  StudySession? _nextSession;
  Timer? _tickerTimer;
  bool _isLoading = false;

  // Countdown fields
  Duration _remainingDuration = Duration.zero;

  // Today progress fields
  double _todayCompletedHours = 0.0;
  double _todayRemainingHours = 0.0;

  StudySession? get currentSession => _currentSession;
  StudySession? get nextSession => _nextSession;
  Duration get remainingDuration => _remainingDuration;
  double get todayCompletedHours => _todayCompletedHours;
  double get todayRemainingHours => _todayRemainingHours;
  bool get isLoading => _isLoading;

  String get remainingTimeString {
    if (_remainingDuration.isNegative || _remainingDuration == Duration.zero) {
      return "00:00:00";
    }
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(_remainingDuration.inHours);
    final minutes = twoDigits(_remainingDuration.inMinutes.remainder(60));
    final seconds = twoDigits(_remainingDuration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  HomeViewModel() {
    _startTicker();
  }

  @override
  void dispose() {
    _tickerTimer?.cancel();
    super.dispose();
  }

  // Load and refresh sessions from repository
  Future<void> fetchHomeSessions() async {
    _isLoading = true;
    notifyListeners();
    try {
      _allSessions = await _sessionRepo.fetchSessions();
      _evaluateTimeSlots();
    } catch (e) {
      debugPrint("Error loading home sessions: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Starts the clock ticker to auto-refresh session states
  void _startTicker() {
    _tickerTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _evaluateTimeSlots();
    });
  }

  // Calculates active, upcoming, and completed/remaining metrics based on current time
  void _evaluateTimeSlots() {
    final now = DateTime.now();

    StudySession? activeSession;
    StudySession? upcomingSession;

    double completedHrs = 0.0;
    double remainingHrs = 0.0;

    // Filter sessions scheduled for today
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

    for (var session in _allSessions) {
      // 1. Find Current Active Session
      if (session.startTime.isBefore(now) && session.endTime.isAfter(now)) {
        activeSession = session;
      }

      // 2. Find Next Session
      if (session.startTime.isAfter(now)) {
        if (upcomingSession == null || session.startTime.isBefore(upcomingSession.startTime)) {
          upcomingSession = session;
        }
      }

      // 3. Compute Today's Stats
      if (session.startTime.isAfter(todayStart) && session.startTime.isBefore(todayEnd)) {
        final durationHours = session.endTime.difference(session.startTime).inMinutes / 60.0;
        if (session.isCompleted) {
          completedHrs += durationHours;
        } else {
          remainingHrs += durationHours;
        }
      }
    }

    // Update state fields
    _currentSession = activeSession;
    _nextSession = upcomingSession;
    _todayCompletedHours = completedHrs;
    _todayRemainingHours = remainingHrs;

    if (_currentSession != null) {
      _remainingDuration = _currentSession!.endTime.difference(now);
    } else {
      _remainingDuration = Duration.zero;
    }

    // Only notify if current session changes or countdown updates
    // In order to animate/refresh countdown smoothly, we notify every tick
    notifyListeners();
  }

  // Mark current study session completed
  Future<void> markCurrentSessionCompleted() async {
    if (_currentSession == null) return;
    try {
      final updated = await _sessionRepo.toggleSessionCompletion(_currentSession!.id, true);
      
      // Update local memory list
      final idx = _allSessions.indexWhere((s) => s.id == updated.id);
      if (idx != -1) {
        _allSessions[idx] = updated;
      }
      _evaluateTimeSlots();
    } catch (e) {
      debugPrint("Error completing session: $e");
    }
  }
}
