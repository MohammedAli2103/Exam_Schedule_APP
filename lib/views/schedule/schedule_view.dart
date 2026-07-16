import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/schedule_viewmodel.dart';
import '../../viewmodels/subject_viewmodel.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../viewmodels/progress_viewmodel.dart';
import '../../models/study_session.dart';
import '../../models/chapter.dart';
import '../subjects/subject_details_view.dart';
import 'create_study_session_view.dart';

class ScheduleView extends StatefulWidget {
  const ScheduleView({super.key});

  @override
  State<ScheduleView> createState() => _ScheduleViewState();
}

class _ScheduleViewState extends State<ScheduleView> {
  late final ScrollController _scrollController;
  DateTime? _lastSelectedDate;
  static const int _centerIndex = 5000;
  static const double _itemWidth = 68.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedDate(animate: false);
      Provider.of<ScheduleViewModel>(context, listen: false).fetchSessions();
      Provider.of<SubjectViewModel>(context, listen: false).fetchSubjects();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSelectedDate({bool animate = false}) {
    if (!_scrollController.hasClients) return;

    final vm = Provider.of<ScheduleViewModel>(context, listen: false);
    final today = DateUtils.dateOnly(DateTime.now());
    final selected = DateUtils.dateOnly(vm.selectedDate);
    final differenceInDays = selected.difference(today).inDays;

    final screenWidth = MediaQuery.of(context).size.width;
    final targetOffset = ((_centerIndex + differenceInDays) * _itemWidth) - (screenWidth / 2) + (_itemWidth / 2);

    if (animate) {
      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _scrollController.jumpTo(targetOffset);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheduleVm = Provider.of<ScheduleViewModel>(context);
    final theme = Theme.of(context);

    // Track selected date changes to auto-scroll
    final normalizedSelectedDate = DateUtils.dateOnly(scheduleVm.selectedDate);
    if (_lastSelectedDate == null) {
      _lastSelectedDate = normalizedSelectedDate;
    } else if (_lastSelectedDate != normalizedSelectedDate) {
      _lastSelectedDate = normalizedSelectedDate;
      // Scroll to the new date after the current frame builds
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToSelectedDate(animate: true);
      });
    }

    return Scaffold(
      body: Column(
        children: [
          // --- HORIZONTAL CALENDAR STRIP ---
          _buildCalendarStrip(theme, scheduleVm),
          const Divider(height: 1),

          // --- TIMETABLE LIST ---
          Expanded(
            child: scheduleVm.isLoading
                ? const Center(child: CircularProgressIndicator())
                : scheduleVm.sessionsForSelectedDate.isEmpty
                    ? _buildEmptyTimetableState(theme, scheduleVm)
                    : RefreshIndicator(
                        onRefresh: () => scheduleVm.fetchSessions(),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: scheduleVm.sessionsForSelectedDate.length,
                          itemBuilder: (context, index) {
                            final session = scheduleVm.sessionsForSelectedDate[index];
                            return _buildSessionCard(context, theme, scheduleVm, session);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreateSessionDialog(context, scheduleVm, null),
        icon: const Icon(Icons.add_alarm),
        label: const Text("Schedule Session"),
      ),
    );
  }

  Widget _buildCalendarStrip(ThemeData theme, ScheduleViewModel vm) {
    final today = DateUtils.dateOnly(DateTime.now());

    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: 10000, // Large number for virtually infinite scrolling
        itemBuilder: (context, index) {
          final date = today.add(Duration(days: index - _centerIndex));
          final isSelected = DateUtils.isSameDay(date, vm.selectedDate);
          final isToday = DateUtils.isSameDay(date, today);

          final weekdayStr = DateFormat('E').format(date).toUpperCase();
          final dayStr = DateFormat('d').format(date);

          final Color containerColor = isSelected
              ? theme.colorScheme.primary
              : isToday
                  ? theme.colorScheme.primaryContainer.withValues(alpha: 0.4)
                  : Colors.transparent;

          final Color borderColor = isSelected
              ? Colors.transparent
              : isToday
                  ? theme.colorScheme.primary.withValues(alpha: 0.5)
                  : theme.colorScheme.outline.withValues(alpha: 0.3);

          return GestureDetector(
            onTap: () {
              vm.changeSelectedDate(date);
            },
            child: Container(
              width: 56,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: containerColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor, width: isToday && !isSelected ? 2 : 1),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    weekdayStr,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? theme.colorScheme.onPrimary
                          : isToday
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    dayStr,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? theme.colorScheme.onPrimary
                          : isToday
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyTimetableState(ThemeData theme, ScheduleViewModel vm) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today_outlined, size: 64, color: theme.colorScheme.secondary.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            "No sessions scheduled.",
            style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.secondary),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => _openCreateSessionDialog(context, vm, null),
            icon: const Icon(Icons.add),
            label: const Text("Create Study Session"),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(
    BuildContext context,
    ThemeData theme,
    ScheduleViewModel vm,
    StudySession session,
  ) {
    final startStr = DateFormat('h:mm a').format(session.startTime);
    final endStr = DateFormat('h:mm a').format(session.endTime);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: session.isCompleted
            ? BorderSide(color: Colors.green.withValues(alpha: 0.5), width: 1.5)
            : BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                session.studyType,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (session.isCompleted)
              const Icon(Icons.check_circle, color: Colors.green, size: 18),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              session.subjectName ?? "Study Subject",
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text("$startStr - $endStr", style: const TextStyle(fontSize: 14)),
              ],
            ),
            if (session.chapters.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: session.chapters.map((ch) {
                  return Chip(
                    label: Text(ch.name, style: const TextStyle(fontSize: 10)),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
        trailing: const Icon(Icons.more_vert),
        onTap: () => _showSessionActionsBottomSheet(context, vm, session),
      ),
    );
  }

  // Session Click Context Menu Bottom Sheet
  void _showSessionActionsBottomSheet(
    BuildContext context,
    ScheduleViewModel vm,
    StudySession session,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: const Text("Open Notes"),
                onTap: () {
                  Navigator.pop(context);
                  _openSessionNotesFlow(context, session);
                },
              ),
              ListTile(
                leading: const Icon(Icons.check_circle_outline),
                title: Text(session.isCompleted ? "Mark as Pending" : "Mark as Completed"),
                onTap: () async {
                  Navigator.pop(context);
                  await vm.toggleSessionCompletion(session.id, !session.isCompleted);
                  if (context.mounted) {
                    Provider.of<HomeViewModel>(context, listen: false).fetchHomeSessions(forceRefresh: true);
                    Provider.of<ProgressViewModel>(context, listen: false).fetchProgressData(forceRefresh: true);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text("Edit Session"),
                onTap: () {
                  Navigator.pop(context);
                  _openCreateSessionDialog(context, vm, session);
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy_outlined),
                title: const Text("Duplicate Session (Tomorrow)"),
                onTap: () async {
                  Navigator.pop(context);
                  final success = await vm.duplicateSession(session);
                  if (success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Session duplicated for tomorrow!"), backgroundColor: Colors.green),
                    );
                    Provider.of<HomeViewModel>(context, listen: false).fetchHomeSessions();
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text("Delete Session", style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteSession(context, vm, session);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _openSessionNotesFlow(BuildContext context, StudySession session) {
    if (session.chapters.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No chapters mapped to this session.")),
      );
      return;
    }

    if (session.chapters.length == 1) {
      _navigateToChapterNotes(session.chapters.first, session.subjectName ?? "Subject");
    } else {
      showModalBottomSheet(
        context: context,
        builder: (context) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text("Choose Chapter Notes", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ),
                const Divider(),
                ...session.chapters.map(
                  (ch) => ListTile(
                    leading: const Icon(Icons.menu_book),
                    title: Text(ch.name),
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

  void _confirmDeleteSession(BuildContext context, ScheduleViewModel vm, StudySession session) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete Study Session?"),
          content: const Text("Are you sure you want to remove this session from your timetable?"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            TextButton(
              onPressed: () async {
                final success = await vm.deleteSession(session.id);
                if (success && context.mounted) {
                  Navigator.pop(context);
                  Provider.of<HomeViewModel>(context, listen: false).fetchHomeSessions(forceRefresh: true);
                  Provider.of<ProgressViewModel>(context, listen: false).fetchProgressData(forceRefresh: true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Study session deleted.")),
                  );
                }
              },
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  // NAVIGATE TO CREATE STUDY SESSION PAGE
  void _openCreateSessionDialog(
    BuildContext context,
    ScheduleViewModel vm,
    StudySession? existingSession, // Null if new creation, otherwise edit
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateStudySessionPage(
          existingSession: existingSession,
        ),
      ),
    );
  }
}

