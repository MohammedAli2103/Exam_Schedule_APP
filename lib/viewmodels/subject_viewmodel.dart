import 'dart:io';
import 'package:flutter/material.dart';
import '../models/subject.dart';
import '../models/chapter.dart';
import '../models/note.dart';
import '../repositories/subject_repository.dart';
import '../repositories/chapter_repository.dart';
import '../repositories/note_repository.dart';

class SubjectViewModel extends ChangeNotifier {
  final SubjectRepository _subjectRepo = SubjectRepository();
  final ChapterRepository _chapterRepo = ChapterRepository();
  final NoteRepository _noteRepo = NoteRepository();

  List<Subject> _subjects = [];
  List<Subject> _filteredSubjects = [];
  
  List<Chapter> _chapters = [];
  List<Chapter> _filteredChapters = [];
  
  List<Note> _notes = [];

  bool _isLoading = false;
  bool _isDetailsLoading = false;
  bool _isNotesLoading = false;
  String? _errorMessage;

  List<Subject> get subjects => _filteredSubjects;
  List<Chapter> get chapters => _filteredChapters;
  List<Note> get notes => _notes;
  
  bool get isLoading => _isLoading;
  bool get isDetailsLoading => _isDetailsLoading;
  bool get isNotesLoading => _isNotesLoading;
  String? get errorMessage => _errorMessage;

  // --- SUBJECTS CRUD ---

  Future<void> fetchSubjects() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _subjects = await _subjectRepo.fetchSubjects();
      _filteredSubjects = List.from(_subjects);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void searchSubjects(String query) {
    if (query.isEmpty) {
      _filteredSubjects = List.from(_subjects);
    } else {
      _filteredSubjects = _subjects
          .where((sub) => sub.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    notifyListeners();
  }

  Future<bool> addSubject(String name) async {
    try {
      final sub = await _subjectRepo.createSubject(name);
      _subjects.add(sub);
      _filteredSubjects = List.from(_subjects);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> editSubject(String id, String newName) async {
    try {
      final updated = await _subjectRepo.updateSubject(id, newName);
      final idx = _subjects.indexWhere((sub) => sub.id == id);
      if (idx != -1) {
        _subjects[idx] = updated;
        _filteredSubjects = List.from(_subjects);
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteSubject(String id) async {
    try {
      await _subjectRepo.deleteSubject(id);
      _subjects.removeWhere((sub) => sub.id == id);
      _filteredSubjects = List.from(_subjects);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // --- CHAPTERS CRUD ---

  Future<void> fetchChapters(String subjectId) async {
    _isDetailsLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _chapters = await _chapterRepo.fetchChapters(subjectId);
      _filteredChapters = List.from(_chapters);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isDetailsLoading = false;
      notifyListeners();
    }
  }

  void searchChapters(String query) {
    if (query.isEmpty) {
      _filteredChapters = List.from(_chapters);
    } else {
      _filteredChapters = _chapters
          .where((ch) => ch.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    notifyListeners();
  }

  Future<bool> addChapter(String subjectId, String name) async {
    try {
      final ch = await _chapterRepo.createChapter(subjectId, name);
      _chapters.add(ch);
      _filteredChapters = List.from(_chapters);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> renameChapter(String chapterId, String newName) async {
    try {
      final updated = await _chapterRepo.renameChapter(chapterId, newName);
      final idx = _chapters.indexWhere((ch) => ch.id == chapterId);
      if (idx != -1) {
        _chapters[idx] = updated;
        _filteredChapters = List.from(_chapters);
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> toggleChapterCompletion(String chapterId, bool isCompleted) async {
    try {
      final updated = await _chapterRepo.toggleCompletion(chapterId, isCompleted);
      final idx = _chapters.indexWhere((ch) => ch.id == chapterId);
      if (idx != -1) {
        _chapters[idx] = updated;
        _filteredChapters = List.from(_chapters);
      }
      // Also refresh subjects to update progress percentages
      await fetchSubjects();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<bool> deleteChapter(String chapterId) async {
    try {
      await _chapterRepo.deleteChapter(chapterId);
      _chapters.removeWhere((ch) => ch.id == chapterId);
      _filteredChapters = List.from(_chapters);
      await fetchSubjects(); // Update counts
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // --- NOTES CRUD ---

  Future<void> fetchNotes(String chapterId) async {
    _isNotesLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _notes = await _noteRepo.fetchNotes(chapterId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isNotesLoading = false;
      notifyListeners();
    }
  }

  Future<bool> uploadNote({
    required File file,
    required String chapterId,
    required String chapterName,
    required String subjectName,
    required String fileName,
  }) async {
    _isNotesLoading = true;
    notifyListeners();

    try {
      final note = await _noteRepo.uploadNote(
        file: file,
        chapterId: chapterId,
        chapterName: chapterName,
        subjectName: subjectName,
        fileName: fileName,
      );
      _notes.add(note);
      
      // Update note count in the chapter representation locally
      final chIdx = _chapters.indexWhere((ch) => ch.id == chapterId);
      if (chIdx != -1) {
        _chapters[chIdx] = _chapters[chIdx].copyWith(
          notesCount: _chapters[chIdx].notesCount + 1,
        );
        _filteredChapters = List.from(_chapters);
      }
      
      await fetchSubjects(); // Update subject stats
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isNotesLoading = false;
      notifyListeners();
    }
  }

  Future<bool> renameNote(String noteId, String newName) async {
    try {
      final updated = await _noteRepo.renameNote(noteId, newName);
      final idx = _notes.indexWhere((n) => n.id == noteId);
      if (idx != -1) {
        _notes[idx] = updated;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteNote(Note note) async {
    _isNotesLoading = true;
    notifyListeners();

    try {
      await _noteRepo.deleteNote(note);
      _notes.removeWhere((n) => n.id == note.id);
      
      // Update notes count in chapter locally
      final chIdx = _chapters.indexWhere((ch) => ch.id == note.chapterId);
      if (chIdx != -1) {
        _chapters[chIdx] = _chapters[chIdx].copyWith(
          notesCount: _chapters[chIdx].notesCount - 1,
        );
        _filteredChapters = List.from(_chapters);
      }

      await fetchSubjects(); // Update subject stats
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isNotesLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
