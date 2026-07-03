import 'chapter.dart';

class StudySession {
  final String id;
  final String userId;
  final String subjectId;
  final String studyType; // 'Learning', 'Revision', 'Practice Questions', 'Mock Test'
  final String? notes;
  final DateTime startTime;
  final DateTime endTime;
  final bool isCompleted;
  final DateTime createdAt;

  // Joined properties
  final String? subjectName;
  final List<Chapter> chapters;

  StudySession({
    required this.id,
    required this.userId,
    required this.subjectId,
    required this.studyType,
    this.notes,
    required this.startTime,
    required this.endTime,
    required this.isCompleted,
    required this.createdAt,
    this.subjectName,
    this.chapters = const [],
  });

  factory StudySession.fromJson(Map<String, dynamic> json) {
    // Read chapters if provided in JSON join query (e.g. from study_session_chapters)
    List<Chapter> chaptersList = [];
    if (json['study_session_chapters'] != null) {
      final list = json['study_session_chapters'] as List;
      for (var item in list) {
        if (item['chapters'] != null) {
          chaptersList.add(Chapter.fromJson(item['chapters']));
        }
      }
    } else if (json['chapters'] != null) {
      final list = json['chapters'] as List;
      chaptersList = list.map((c) => Chapter.fromJson(c)).toList();
    }

    return StudySession(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      subjectId: json['subject_id'] as String,
      studyType: json['study_type'] as String,
      notes: json['notes'] as String?,
      startTime: DateTime.parse(json['start_time'] as String).toLocal(),
      endTime: DateTime.parse(json['end_time'] as String).toLocal(),
      isCompleted: json['is_completed'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      subjectName: json['subjects']?['name'] as String?,
      chapters: chaptersList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'subject_id': subjectId,
      'study_type': studyType,
      'notes': notes,
      'start_time': startTime.toUtc().toIso8601String(),
      'end_time': endTime.toUtc().toIso8601String(),
      'is_completed': isCompleted,
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }

  StudySession copyWith({
    String? id,
    String? userId,
    String? subjectId,
    String? studyType,
    String? notes,
    DateTime? startTime,
    DateTime? endTime,
    bool? isCompleted,
    DateTime? createdAt,
    String? subjectName,
    List<Chapter>? chapters,
  }) {
    return StudySession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      subjectId: subjectId ?? this.subjectId,
      studyType: studyType ?? this.studyType,
      notes: notes ?? this.notes,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      subjectName: subjectName ?? this.subjectName,
      chapters: chapters ?? this.chapters,
    );
  }
}
