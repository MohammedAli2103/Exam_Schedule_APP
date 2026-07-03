import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/supabase_service.dart';
import 'services/notification_service.dart';
import 'utils/theme.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/home_viewmodel.dart';
import 'viewmodels/subject_viewmodel.dart';
import 'viewmodels/schedule_viewmodel.dart';
import 'viewmodels/progress_viewmodel.dart';
import 'viewmodels/settings_viewmodel.dart';
import 'viewmodels/search_viewmodel.dart';
// import 'views/auth/login_view.dart';
import 'views/main_navigation_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Supabase
  try {
    await SupabaseService.initialize();
  } catch (e) {
    debugPrint("Failed to initialize Supabase: $e");
    // Continue running, the user will see connection/auth error states in UI
  }

  // 2. Initialize Local Notifications Service
  try {
    await NotificationService.instance.initialize();
    await NotificationService.instance.requestPermissions();
  } catch (e) {
    debugPrint("Failed to initialize Notifications: $e");
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()..checkAuthStatus()),
        ChangeNotifierProvider(create: (_) => SettingsViewModel()),
        ChangeNotifierProvider(create: (_) => HomeViewModel()),
        ChangeNotifierProvider(create: (_) => SubjectViewModel()),
        ChangeNotifierProvider(create: (_) => ScheduleViewModel()),
        ChangeNotifierProvider(create: (_) => ProgressViewModel()),
        ChangeNotifierProvider(create: (_) => SearchViewModel()),
      ],
      child: const ExamPreparationApp(),
    ),
  );
}

class ExamPreparationApp extends StatelessWidget {
  const ExamPreparationApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsVm = Provider.of<SettingsViewModel>(context);
    final authVm = Provider.of<AuthViewModel>(context);

    return MaterialApp(
      title: 'Exam Preparation',
      debugShowCheckedModeBanner: false,
      themeMode: settingsVm.themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      // Authentication temporarily disabled.
      // Restore before production release.
      home: authVm.isLoading
          ? const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            )
          : const MainNavigationView(),
    );
  }
}
