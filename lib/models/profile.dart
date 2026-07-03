class UserProfile {
  final String id;
  final String email;
  final String? fullName;
  final int streakCount;
  final DateTime? lastStudyDate;
  final DateTime createdAt;

  UserProfile({
    required this.id,
    required this.email,
    this.fullName,
    required this.streakCount,
    this.lastStudyDate,
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
      streakCount: (json['streak_count'] as num?)?.toInt() ?? 0,
      lastStudyDate: json['last_study_date'] != null
          ? DateTime.parse(json['last_study_date'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'streak_count': streakCount,
      'last_study_date': lastStudyDate?.toIso8601String().split('T').first,
      'created_at': createdAt.toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? fullName,
    int? streakCount,
    DateTime? lastStudyDate,
    DateTime? createdAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      streakCount: streakCount ?? this.streakCount,
      lastStudyDate: lastStudyDate ?? this.lastStudyDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
