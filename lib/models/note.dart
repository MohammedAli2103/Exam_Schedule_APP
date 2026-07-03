class Note {
  final String id;
  final String chapterId;
  final String name;
  final String fileUrl;
  final String filePath;
  final int? fileSize;
  final DateTime createdAt;

  Note({
    required this.id,
    required this.chapterId,
    required this.name,
    required this.fileUrl,
    required this.filePath,
    this.fileSize,
    required this.createdAt,
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] as String,
      chapterId: json['chapter_id'] as String,
      name: json['name'] as String,
      fileUrl: json['file_url'] as String,
      filePath: json['file_path'] as String,
      fileSize: json['file_size'] != null ? (json['file_size'] as num).toInt() : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chapter_id': chapterId,
      'name': name,
      'file_url': fileUrl,
      'file_path': filePath,
      'file_size': fileSize,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Note copyWith({
    String? id,
    String? chapterId,
    String? name,
    String? fileUrl,
    String? filePath,
    int? fileSize,
    DateTime? createdAt,
  }) {
    return Note(
      id: id ?? this.id,
      chapterId: chapterId ?? this.chapterId,
      name: name ?? this.name,
      fileUrl: fileUrl ?? this.fileUrl,
      filePath: filePath ?? this.filePath,
      fileSize: fileSize ?? this.fileSize,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
