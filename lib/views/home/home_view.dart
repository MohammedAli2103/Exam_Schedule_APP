import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../viewmodels/subject_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/progress_viewmodel.dart';
import '../../models/study_session.dart';
import '../../models/chapter.dart';
import '../subjects/subject_details_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<HomeViewModel>(context, listen: false).fetchHomeSessions();
      Provider.of<SubjectViewModel>(context, listen: false).fetchSubjects();
    });
  }

  @override
  Widget build(BuildContext context) {
    final homeVm = Provider.of<HomeViewModel>(context);
    final authVm = Provider.of<AuthViewModel>(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          final subVm = Provider.of<SubjectViewModel>(context, listen: false);
          await homeVm.fetchHomeSessions(forceRefresh: true);
          await subVm.fetchSubjects(forceRefresh: true);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: const BoxConstraints().maxWidth > 600
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.stretch,
            children: [
              // --- WELCOME CARD ---
              _buildWelcomeCard(theme, authVm),
              const SizedBox(height: 16),

              // --- TODAY'S PROGRESS PROGRESS BAR ---
              _buildTodayProgressCard(theme, homeVm),
              const SizedBox(height: 16),

              // --- CURRENT SESSION ACTIVE SECTION ---
              _buildActiveSessionSection(theme, homeVm),
              const SizedBox(height: 16),

              // --- NEXT SESSION CARD ---
              _buildNextSessionCard(theme, homeVm),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(ThemeData theme, AuthViewModel authVm) {
    final timeStr = DateFormat('EEEE, MMMM d').format(DateTime.now());
    final name = authVm.profile?.fullName ?? "Student";
    final streak = authVm.profile?.streakCount ?? 0;

    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Welcome back, $name!",
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Keep up the effort!",
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    timeStr,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_fire_department, color: Colors.orange, size: 24),
                  const SizedBox(width: 4),
                  Text(
                    "$streak",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayProgressCard(ThemeData theme, HomeViewModel homeVm) {
    final totalHours = homeVm.todayCompletedHours + homeVm.todayRemainingHours;
    final progress = totalHours > 0 ? (homeVm.todayCompletedHours / totalHours) : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Today's Progress",
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  "${(progress * 100).toStringAsFixed(0)}% Done",
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTimeDetailItem(
                  theme,
                  Icons.check_circle_outline,
                  "Completed",
                  "${homeVm.todayCompletedHours.toStringAsFixed(1)} hrs",
                  Colors.green,
                ),
                _buildTimeDetailItem(
                  theme,
                  Icons.hourglass_empty,
                  "Remaining",
                  "${homeVm.todayRemainingHours.toStringAsFixed(1)} hrs",
                  theme.colorScheme.secondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeDetailItem(
    ThemeData theme,
    IconData icon,
    String label,
    String duration,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.bodySmall),
            Text(
              duration,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildActiveSessionSection(ThemeData theme, HomeViewModel homeVm) {
    final session = homeVm.currentSession;

    if (session == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40.0, horizontal: 20.0),
          child: Column(
            children: [
              Icon(Icons.event_busy_outlined, size: 48, color: Colors.grey),
              SizedBox(height: 12),
              Text(
                "No study session scheduled right now.",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final startStr = DateFormat('h:mm a').format(session.startTime);
    final endStr = DateFormat('h:mm a').format(session.endTime);

    return Card(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.primary, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    session.studyType.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                const Icon(Icons.alarm, color: Colors.redAccent, size: 18),
                const SizedBox(width: 4),
                Text(
                  "Remaining: ${homeVm.remainingTimeString}",
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              session.subjectName ?? "Study Subject",
              style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              "$startStr - $endStr",
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary),
            ),
            const SizedBox(height: 16),
            const Text(
              "CHAPTERS TO STUDY",
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            if (session.chapters.isEmpty)
              const Text("No specific chapters mapped", style: TextStyle(fontStyle: FontStyle.italic))
            else
              ...session.chapters.map(
                (ch) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Icon(
                        ch.isCompleted ? Icons.check_circle : Icons.circle_outlined,
                        color: ch.isCompleted ? Colors.green : Colors.grey,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          ch.name,
                          style: TextStyle(
                            decoration: ch.isCompleted ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (session.notes != null && session.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                "SESSION NOTES",
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(session.notes!),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openSessionNotes(context, session),
                    icon: const Icon(Icons.description_outlined),
                    label: const Text("Open Notes"),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: session.isCompleted ? null : () async {
                      await homeVm.markCurrentSessionCompleted();
                      if (mounted) {
                        Provider.of<ProgressViewModel>(context, listen: false).fetchProgressData(forceRefresh: true);
                      }
                    },
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text(session.isCompleted ? "Completed" : "Mark Done"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextSessionCard(ThemeData theme, HomeViewModel homeVm) {
    final next = homeVm.nextSession;
    if (next == null) return const SizedBox.shrink();

    final timeStr = DateFormat('h:mm a').format(next.startTime);
    final dayStr = DateFormat('MMM d').format(next.startTime);

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(Icons.next_plan, color: theme.colorScheme.primary),
        ),
        title: Text(
          "Next: ${next.subjectName ?? 'Subject'}",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text("${next.studyType} • $dayStr at $timeStr"),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      ),
    );
  }

  void _openSessionNotes(BuildContext context, StudySession session) {
    if (session.chapters.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No chapters mapped to this session.")),
      );
      return;
    }

    if (session.chapters.length == 1) {
      _navigateToChapterNotes(session.chapters.first, session.subjectName ?? "Subject");
    } else {
      // Prompt user to select chapter
      showModalBottomSheet(
        context: context,
        builder: (context) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    "Choose Chapter",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                const Divider(),
                ...session.chapters.map(
                  (ch) => ListTile(
                    leading: const Icon(Icons.menu_book),
                    title: Text(ch.name),
                    subtitle: Text("${ch.notesCount} notes uploaded"),
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToChapterNotes(ch, session.subjectName ?? "Subject");
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    }
  }

  void _navigateToChapterNotes(Chapter chapter, String subjectName) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SubjectDetailsView(
          subjectId: chapter.subjectId,
          subjectName: subjectName,
          initialChapterIdToOpenNotes: chapter.id,
        ),
      ),
    );
  }
}
