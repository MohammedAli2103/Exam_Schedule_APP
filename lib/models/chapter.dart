class Chapter {
  final String id;
  final String subjectId;
  final String name;
  final bool isCompleted;
  final DateTime createdAt;

  // UI helpers
  final int notesCount;

  Chapter({
    required this.id,
    required this.subjectId,
    required this.name,
    required this.isCompleted,
    required this.createdAt,
    this.notesCount = 0,
  });

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      id: json['id'] as String,
      subjectId: json['subject_id'] as String,
      name: json['name'] as String,
      isCompleted: json['is_completed'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      notesCount: json['notes_count'] != null
          ? (json['notes_count'] as num).toInt()
          : (json['notes'] is List ? (json['notes'] as List).length : 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subject_id': subjectId,
      'name': name,
      'is_completed': isCompleted,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Chapter copyWith({
    String? id,
    String? subjectId,
    String? name,
    bool? isCompleted,
    DateTime? createdAt,
    int? notesCount,
  }) {
    return Chapter(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      name: name ?? this.name,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      notesCount: notesCount ?? this.notesCount,
    );
  }
}
