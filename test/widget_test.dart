import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:exam_preparation/main.dart';
import 'package:exam_preparation/services/supabase_service.dart';
import 'package:exam_preparation/viewmodels/auth_viewmodel.dart';
import 'package:exam_preparation/viewmodels/home_viewmodel.dart';
import 'package:exam_preparation/viewmodels/subject_viewmodel.dart';
import 'package:exam_preparation/viewmodels/schedule_viewmodel.dart';
import 'package:exam_preparation/viewmodels/progress_viewmodel.dart';
import 'package:exam_preparation/viewmodels/settings_viewmodel.dart';
import 'package:exam_preparation/viewmodels/search_viewmodel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  setUpAll(() async {
    try {
      await SupabaseService.initialize();
    } catch (_) {
      // Ignored if already initialized or in test mode
    }
  });

  testWidgets('App navigation smoke test', (WidgetTester tester) async {
    // Build our app with all providers initialized.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthViewModel()),
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

    // Verify we are on Dashboard/Home page by checking title
    expect(find.text('Dashboard'), findsOneWidget);
    
    // Check navigation items are present
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Subjects'), findsOneWidget);
    expect(find.text('Schedule'), findsOneWidget);
  });
}
