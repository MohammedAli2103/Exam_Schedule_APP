import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/subject.dart';
import '../models/study_session.dart';
import '../models/profile.dart';
import '../repositories/subject_repository.dart';
import '../repositories/session_repository.dart';
import '../repositories/auth_repository.dart';
import '../services/pdf_service.dart';

class ProgressViewModel extends ChangeNotifier {
  final SubjectRepository _subjectRepo = SubjectRepository();
  final SessionRepository _sessionRepo = SessionRepository();
  final AuthRepository _authRepo = AuthRepository();
  final PdfService _pdfService = PdfService.instance;

  List<Subject> _subjects = [];
  List<StudySession> _sessions = [];
  UserProfile? _profile;

  bool _isLoading = false;
  String? _errorMessage;

  // Computed statistics
  double _todayHours = 0.0;
  double _weeklyHours = 0.0;
  double _monthlyHours = 0.0;
  int _completedSessionsCount = 0;
  int _pendingSessionsCount = 0;
  int _completedChaptersCount = 0;
  int _totalChaptersCount = 0;
  int _streakCount = 0;

  List<Subject> get subjects => _subjects;
  List<StudySession> get sessions => _sessions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  double get todayHours => _todayHours;
  double get weeklyHours => _weeklyHours;
  double get monthlyHours => _monthlyHours;
  int get completedSessionsCount => _completedSessionsCount;
  int get pendingSessionsCount => _pendingSessionsCount;
  int get completedChaptersCount => _completedChaptersCount;
  int get totalChaptersCount => _totalChaptersCount;
  int get streakCount => _streakCount;

  Future<void> fetchProgressData({bool forceRefresh = false}) async {
    if (_subjects.isEmpty || _sessions.isEmpty || forceRefresh) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      // 1. Fetch data from repositories
      _subjects = await _subjectRepo.fetchSubjects(forceRefresh: forceRefresh);
      _sessions = await _sessionRepo.fetchSessions(forceRefresh: forceRefresh);
      
      final currentUserId = _authRepo.currentUser?.id;
      if (currentUserId != null) {
        _profile = await _authRepo.fetchProfile(currentUserId);
        _streakCount = _profile?.streakCount ?? 0;
      }

      // 2. Perform aggregations
      _calculateStats();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _calculateStats() {
    final now = DateTime.now();
    
    // Reset counters
    _todayHours = 0.0;
    _weeklyHours = 0.0;
    _monthlyHours = 0.0;
    _completedSessionsCount = 0;
    _pendingSessionsCount = 0;
    _completedChaptersCount = 0;
    _totalChaptersCount = 0;

    // A. Session-based calculations
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final monthStart = DateTime(now.year, now.month, 1);

    for (var session in _sessions) {
      final start = session.startTime;
      final durationHrs = session.endTime.difference(start).inMinutes / 60.0;

      if (session.isCompleted) {
        _completedSessionsCount++;
        // Today
        if (start.isAfter(todayStart)) {
          _todayHours += durationHrs;
        }
        // Weekly
        if (start.isAfter(weekStart)) {
          _weeklyHours += durationHrs;
        }
        // Monthly
        if (start.isAfter(monthStart)) {
          _monthlyHours += durationHrs;
        }
      } else {
        _pendingSessionsCount++;
      }
    }

    // B. Chapter-based calculations
    for (var subject in _subjects) {
      _totalChaptersCount += subject.chapterCount;
      // We estimate completed chapters from progress percentage
      final completed = (subject.chapterCount * (subject.progressPercentage / 100.0)).round();
      _completedChaptersCount += completed;
    }
  }

  // --- PDF REPORT ACTIONS ---

  Future<Uint8List> generatePdfBytes(String studentName) async {
    double totalHoursCompleted = 0.0;
    double totalHoursRemaining = 0.0;

    for (var session in _sessions) {
      final hrs = session.endTime.difference(session.startTime).inMinutes / 60.0;
      if (session.isCompleted) {
        totalHoursCompleted += hrs;
      } else {
        totalHoursRemaining += hrs;
      }
    }

    return await _pdfService.generateReportPdf(
      studentName: studentName,
      subjects: _subjects,
      sessions: _sessions,
      totalHoursCompleted: totalHoursCompleted,
      totalHoursRemaining: totalHoursRemaining,
      completedSessionsCount: _completedSessionsCount,
      pendingSessionsCount: _pendingSessionsCount,
      completedChaptersCount: _completedChaptersCount,
      totalChaptersCount: _totalChaptersCount,
    );
  }

  Future<void> printReport(String studentName) async {
    final bytes = await generatePdfBytes(studentName);
    await _pdfService.printReport(bytes);
  }

  Future<void> shareReport(String studentName) async {
    final bytes = await generatePdfBytes(studentName);
    await _pdfService.shareReport(bytes);
  }
}
