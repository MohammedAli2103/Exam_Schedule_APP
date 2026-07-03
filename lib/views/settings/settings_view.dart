import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/settings_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../viewmodels/schedule_viewmodel.dart';
import '../../viewmodels/subject_viewmodel.dart';
import '../../viewmodels/progress_viewmodel.dart';
// import '../auth/login_view.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsVm = Provider.of<SettingsViewModel>(context);
    final authVm = Provider.of<AuthViewModel>(context, listen: false);
    final theme = Theme.of(context);

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // --- USER PROFILE CARD ---
          _buildUserProfileHeader(theme, authVm),
          const SizedBox(height: 20),

          // --- SECTION: APPEARANCE ---
          _buildSectionTitle("Appearance"),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.dark_mode_outlined),
                  title: const Text("Dark Mode"),
                  subtitle: const Text("Switch between light and dark themes"),
                  value: settingsVm.isDarkMode,
                  onChanged: (bool val) {
                    settingsVm.toggleTheme(val);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // --- SECTION: NOTIFICATIONS ---
          _buildSectionTitle("Notifications"),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_active_outlined),
                  title: const Text("Enable Reminders"),
                  subtitle: const Text("Receive warning alerts before study slots"),
                  value: settingsVm.notificationsEnabled,
                  onChanged: (bool val) {
                    settingsVm.toggleNotifications(val);
                  },
                ),
                if (settingsVm.notificationsEnabled) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.alarm_on),
                    title: const Text("Reminder Offset"),
                    subtitle: Text("Alert me ${settingsVm.reminderTimeOffset} minutes before"),
                    trailing: DropdownButton<int>(
                      value: settingsVm.reminderTimeOffset,
                      items: [5, 10, 15, 30, 45].map((int val) {
                        return DropdownMenuItem<int>(
                          value: val,
                          child: Text("$val min"),
                        );
                      }).toList(),
                      onChanged: (int? newVal) {
                        if (newVal != null) {
                          settingsVm.setReminderTimeOffset(newVal);
                        }
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // --- SECTION: BACKUP & RESTORE ---
          _buildSectionTitle("Data Management"),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: settingsVm.isBackingUp
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.backup_outlined),
                  title: const Text("Backup Data"),
                  subtitle: const Text("Export subjects and sessions to JSON"),
                  onTap: settingsVm.isBackingUp
                      ? null
                      : () async {
                          final success = await settingsVm.backupData();
                          if (success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Data backed up successfully!"), backgroundColor: Colors.green),
                            );
                          } else if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(settingsVm.errorMessage ?? "Backup failed"), backgroundColor: Colors.red),
                            );
                          }
                        },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: settingsVm.isRestoring
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.restore_outlined),
                  title: const Text("Restore Data"),
                  subtitle: const Text("Import study data from a JSON backup file"),
                  onTap: settingsVm.isRestoring
                      ? null
                      : () async {
                          final success = await settingsVm.restoreData();
                          if (success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Data restored successfully!"), backgroundColor: Colors.green),
                            );
                            // Refresh all ViewModels
                            Provider.of<HomeViewModel>(context, listen: false).fetchHomeSessions();
                            Provider.of<ScheduleViewModel>(context, listen: false).fetchSessions();
                            Provider.of<SubjectViewModel>(context, listen: false).fetchSubjects();
                            Provider.of<ProgressViewModel>(context, listen: false).fetchProgressData();
                          } else if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(settingsVm.errorMessage ?? "Restore failed"), backgroundColor: Colors.red),
                            );
                          }
                        },
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // --- LOGOUT BUTTON ---
          // Authentication temporarily disabled.
          // Restore before production release.
          /*
          ElevatedButton.icon(
            onPressed: () async {
              await authVm.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginView()),
                  (route) => false,
                );
              }
            },
            icon: const Icon(Icons.logout),
            label: const Text("Logout", style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.errorContainer,
              foregroundColor: theme.colorScheme.onErrorContainer,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          */
        ],
      ),
    );
  }

  Widget _buildUserProfileHeader(ThemeData theme, AuthViewModel authVm) {
    return Card(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: theme.colorScheme.primary,
              child: Text(
                authVm.profile?.fullName?.substring(0, 1).toUpperCase() ?? "S",
                style: TextStyle(color: theme.colorScheme.onPrimary, fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    authVm.profile?.fullName ?? "Student",
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    authVm.profile?.email ?? "No Email",
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
      ),
    );
  }
}
