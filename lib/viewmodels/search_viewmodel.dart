import 'package:flutter/material.dart';
import '../repositories/subject_repository.dart';
import '../repositories/chapter_repository.dart';
import '../repositories/note_repository.dart';
import '../repositories/session_repository.dart';

enum SearchResultType { subject, chapter, note, session }

class SearchResult {
  final String title;
  final String subtitle;
  final SearchResultType type;
  final dynamic originalObject;

  SearchResult({
    required this.title,
    required this.subtitle,
    required this.type,
    required this.originalObject,
  });
}

class SearchViewModel extends ChangeNotifier {
  final SubjectRepository _subjectRepo = SubjectRepository();
  final ChapterRepository _chapterRepo = ChapterRepository();
  final NoteRepository _noteRepo = NoteRepository();
  final SessionRepository _sessionRepo = SessionRepository();

  List<SearchResult> _results = [];
  bool _isSearching = false;
  String? _errorMessage;

  List<SearchResult> get results => _results;
  bool get isSearching => _isSearching;
  String? get errorMessage => _errorMessage;

  /// Perform global search across all tables.
  Future<void> performGlobalSearch(String query) async {
    if (query.trim().isEmpty) {
      _results = [];
      notifyListeners();
      return;
    }

    _isSearching = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final String term = query.toLowerCase().trim();
      final List<SearchResult> tempResults = [];

      // 1. Fetch data from DB
      final subjects = await _subjectRepo.fetchSubjects();
      final sessions = await _sessionRepo.fetchSessions();

      // 2. Search Subjects
      for (var sub in subjects) {
        if (sub.name.toLowerCase().contains(term)) {
          tempResults.add(
            SearchResult(
              title: sub.name,
              subtitle: 'Subject • ${sub.chapterCount} chapters',
              type: SearchResultType.subject,
              originalObject: sub,
            ),
          );
        }

        // Fetch chapters and notes for this subject
        final chapters = await _chapterRepo.fetchChapters(sub.id);
        for (var ch in chapters) {
          if (ch.name.toLowerCase().contains(term)) {
            tempResults.add(
              SearchResult(
                title: ch.name,
                subtitle: 'Chapter in ${sub.name}',
                type: SearchResultType.chapter,
                originalObject: ch,
              ),
            );
          }

          // Fetch notes for this chapter
          final notes = await _noteRepo.fetchNotes(ch.id);
          for (var note in notes) {
            if (note.name.toLowerCase().contains(term)) {
              tempResults.add(
                SearchResult(
                  title: note.name,
                  subtitle: 'Note in ${sub.name} > ${ch.name}',
                  type: SearchResultType.note,
                  originalObject: note,
                ),
              );
            }
          }
        }
      }

      // 3. Search Timetable Sessions
      for (var session in sessions) {
        final matchesType = session.studyType.toLowerCase().contains(term);
        final matchesSubject = (session.subjectName ?? '').toLowerCase().contains(term);
        final matchesNotes = (session.notes ?? '').toLowerCase().contains(term);

        if (matchesType || matchesSubject || matchesNotes) {
          final timeStr = "${session.startTime.hour}:${session.startTime.minute.toString().padLeft(2, '0')}";
          tempResults.add(
            SearchResult(
              title: '${session.subjectName ?? "Study Session"} - ${session.studyType}',
              subtitle: 'Timetable Slot • $timeStr (${session.isCompleted ? "Completed" : "Pending"})',
              type: SearchResultType.session,
              originalObject: session,
            ),
          );
        }
      }

      _results = tempResults;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  void clearSearch() {
    _results = [];
    _isSearching = false;
    notifyListeners();
  }
}
