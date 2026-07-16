class AppConfig {
  final bool maintenanceEnabled;
  final String maintenanceMessage;
  final String latestVersion;
  final String minimumSupportedVersion;
  final String downloadUrl;

  AppConfig({
    required this.maintenanceEnabled,
    required this.maintenanceMessage,
    required this.latestVersion,
    required this.minimumSupportedVersion,
    required this.downloadUrl,
  });

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      maintenanceEnabled: json['maintenance_enabled'] as bool? ?? false,
      maintenanceMessage: json['maintenance_message'] as String? ?? 'The app is currently undergoing maintenance. Please try again later.',
      latestVersion: json['latest_version'] as String? ?? '1.0.0',
      minimumSupportedVersion: json['minimum_supported_version'] as String? ?? '1.0.0',
      downloadUrl: json['download_url'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maintenance_enabled': maintenanceEnabled,
      'maintenance_message': maintenanceMessage,
      'latest_version': latestVersion,
      'minimum_supported_version': minimumSupportedVersion,
      'download_url': downloadUrl,
    };
  }
}
