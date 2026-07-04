class Subject {
  final String id;
  final String userId;
  final String name;
  final DateTime createdAt;

  // Aggregate fields populated via SQL joins/calculations
  final int chapterCount;
  final int notesCount;
  final double progressPercentage;

  Subject({
    required this.id,
    required this.userId,
    required this.name,
    required this.createdAt,
    this.chapterCount = 0,
    this.notesCount = 0,
    this.progressPercentage = 0.0,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    // Check if aggregates exist in payload
    final chapterAgg = json['chapter_count'] ?? json['chapters']?[0]?['count'] ?? 0;
    final notesAgg = json['notes_count'] ?? 0; // We will calculate this separately or fetch it
    final completedChapters = json['completed_chapters'] ?? 0;
    
    double progress = 0.0;
    if (chapterAgg > 0) {
      progress = (completedChapters / chapterAgg) * 100.0;
    }

    return Subject(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      chapterCount: (chapterAgg as num).toInt(),
      notesCount: (notesAgg as num).toInt(),
      progressPercentage: progress,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Subject copyWith({
    String? id,
    String? userId,
    String? name,
    DateTime? createdAt,
    int? chapterCount,
    int? notesCount,
    double? progressPercentage,
  }) {
    return Subject(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      chapterCount: chapterCount ?? this.chapterCount,
      notesCount: notesCount ?? this.notesCount,
      progressPercentage: progressPercentage ?? this.progressPercentage,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Subject &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
