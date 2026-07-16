class AppConstants {
  // App Version
  static const String appVersion = '1.0.0';

  // Supabase Configuration
  // TODO: Replace with your actual Supabase credentials
  static const String supabaseUrl = 'https://lpllkuvornkmppkkldjg.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxwbGxrdXZvcm5rbXBwa2tsZGpnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODMwNjM4NDcsImV4cCI6MjA5ODYzOTg0N30.CqklbbY9zU0razht3bbt47qwMPfQCvjZxN4VC9kc6iE';

  // Storage Bucket Name
  static const String storageBucketName = 'notes';

  // App Metadata
  static const String appName = 'Exam Preparation';

  // Date and Time Formats
  static const String dateFormat = 'yyyy-MM-dd';
  static const String timeFormat = 'hh:mm a';

  // Validation Patterns
  static final RegExp emailRegExp = RegExp(
    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
  );

  // Study Types
  static const List<String> studyTypes = [
    'Reading',
    'Revision',
    'Practice',
    'Assignment',
    'Lab',
    'Mock Test',
    'Custom',
  ];
}
