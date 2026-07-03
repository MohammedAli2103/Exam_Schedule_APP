import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/schedule_viewmodel.dart';
import '../../viewmodels/subject_viewmodel.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../models/study_session.dart';
import '../../models/subject.dart';
import '../../models/chapter.dart';
import '../../utils/constants.dart';
import '../subjects/subject_details_view.dart';

class ScheduleView extends StatefulWidget {
  const ScheduleView({super.key});

  @override
  State<ScheduleView> createState() => _ScheduleViewState();
}

class _ScheduleViewState extends State<ScheduleView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ScheduleViewModel>(context, listen: false).fetchSessions();
      Provider.of<SubjectViewModel>(context, listen: false).fetchSubjects();
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheduleVm = Provider.of<ScheduleViewModel>(context);
    final theme = Theme.of(context);

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
    final today = DateTime.now();
    // Render a 14-day strip (-7 days to +7 days)
    final List<DateTime> dates = List.generate(
      15,
      (index) => today.subtract(const Duration(days: 7)).add(Duration(days: index)),
    );

    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: dates.length,
        itemBuilder: (context, index) {
          final date = dates[index];
          final isSelected = date.year == vm.selectedDate.year &&
              date.month == vm.selectedDate.month &&
              date.day == vm.selectedDate.day;

          final weekdayStr = DateFormat('E').format(date).toUpperCase();
          final dayStr = DateFormat('d').format(date);

          return GestureDetector(
            onTap: () => vm.changeSelectedDate(date),
            child: Container(
              width: 56,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? Colors.transparent : theme.colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    weekdayStr,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    dayStr,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
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
            "No sessions scheduled for today.",
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
                onTap: () {
                  Navigator.pop(context);
                  vm.toggleSessionCompletion(session.id, !session.isCompleted);
                  Provider.of<HomeViewModel>(context, listen: false).fetchHomeSessions();
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
                  Provider.of<HomeViewModel>(context, listen: false).fetchHomeSessions();
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

  // CREATE STUDY SESSION WIZARD (DIALOG)
  void _openCreateSessionDialog(
    BuildContext context,
    ScheduleViewModel vm,
    StudySession? existingSession, // Null if new creation, otherwise edit
  ) {
    final subVm = Provider.of<SubjectViewModel>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return SessionWizardDialog(
          subjects: subVm.subjects,
          existingSession: existingSession,
          scheduleVm: vm,
        );
      },
    );
  }
}

// Dialog Wizard Class for Create Study Session
class SessionWizardDialog extends StatefulWidget {
  final List<Subject> subjects;
  final StudySession? existingSession;
  final ScheduleViewModel scheduleVm;

  const SessionWizardDialog({
    super.key,
    required this.subjects,
    this.existingSession,
    required this.scheduleVm,
  });

  @override
  State<SessionWizardDialog> createState() => _SessionWizardDialogState();
}

class _SessionWizardDialogState extends State<SessionWizardDialog> {
  int _currentStep = 1;

  // Values
  Subject? _selectedSubject;
  List<Chapter> _availableChapters = [];
  final List<String> _selectedChapterIds = [];
  String _selectedStudyType = AppConstants.studyTypes.first;
  final _notesController = TextEditingController();

  DateTime _startTime = DateTime.now().add(const Duration(hours: 1));
  DateTime _endTime = DateTime.now().add(const Duration(hours: 2));

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime(
      widget.scheduleVm.selectedDate.year,
      widget.scheduleVm.selectedDate.month,
      widget.scheduleVm.selectedDate.day,
      _startTime.hour,
      0,
    );
    _endTime = _startTime.add(const Duration(hours: 2));

    if (widget.existingSession != null) {
      final session = widget.existingSession!;
      _selectedStudyType = session.studyType;
      _notesController.text = session.notes ?? '';
      _startTime = session.startTime;
      _endTime = session.endTime;

      // Match subject
      if (widget.subjects.isNotEmpty) {
        _selectedSubject = widget.subjects.firstWhere(
          (s) => s.id == session.subjectId,
          orElse: () => widget.subjects.first,
        );
        _selectedChapterIds.addAll(session.chapters.map((c) => c.id));
        _loadChaptersForSubject();
      }
    } else if (widget.subjects.isNotEmpty) {
      _selectedSubject = widget.subjects.first;
      _loadChaptersForSubject();
    }
  }

  void _loadChaptersForSubject() async {
    if (_selectedSubject == null) return;
    final subVm = Provider.of<SubjectViewModel>(context, listen: false);
    await subVm.fetchChapters(_selectedSubject!.id);
    setState(() {
      _availableChapters = subVm.chapters;
    });
  }

  Future<void> _selectTime(bool isStart) async {
    final initialTime = TimeOfDay.fromDateTime(isStart ? _startTime : _endTime);
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked != null) {
      setState(() {
        final base = widget.scheduleVm.selectedDate;
        if (isStart) {
          _startTime = DateTime(base.year, base.month, base.day, picked.hour, picked.minute);
          // Auto adjust end time to be +1 hour
          _endTime = _startTime.add(const Duration(hours: 1));
        } else {
          _endTime = DateTime(base.year, base.month, base.day, picked.hour, picked.minute);
        }
      });
    }
  }

  void _save() async {
    if (_selectedSubject == null) return;
    if (_endTime.isBefore(_startTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("End time must be after start time.")),
      );
      return;
    }

    setState(() => _isSaving = true);

    bool success;
    if (widget.existingSession != null) {
      success = await widget.scheduleVm.updateSession(
        sessionId: widget.existingSession!.id,
        subjectId: _selectedSubject!.id,
        studyType: _selectedStudyType,
        chapterIds: _selectedChapterIds,
        startTime: _startTime,
        endTime: _endTime,
        isCompleted: widget.existingSession!.isCompleted,
        notes: _notesController.text.trim(),
      );
    } else {
      success = await widget.scheduleVm.createSession(
        subjectId: _selectedSubject!.id,
        studyType: _selectedStudyType,
        chapterIds: _selectedChapterIds,
        startTime: _startTime,
        endTime: _endTime,
        notes: _notesController.text.trim(),
      );
    }

    setState(() => _isSaving = false);

    if (success && mounted) {
      Provider.of<HomeViewModel>(context, listen: false).fetchHomeSessions();
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.scheduleVm.errorMessage ?? "Failed to save session.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(widget.existingSession != null ? "Edit Study Session" : "Create Study Session"),
      content: SingleChildScrollView(
        child: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Step Indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final step = index + 1;
                  final isDone = step < _currentStep;
                  final isActive = step == _currentStep;
                  return Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: isDone
                            ? Colors.green
                            : isActive
                                ? theme.colorScheme.primary
                                : Colors.grey[300],
                        child: isDone
                            ? const Icon(Icons.check, size: 12, color: Colors.white)
                            : Text(
                                step.toString(),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isActive || isDone ? Colors.white : Colors.black87,
                                ),
                              ),
                      ),
                      if (index < 4)
                        Container(
                          width: 20,
                          height: 2,
                          color: step < _currentStep ? Colors.green : Colors.grey[300],
                        ),
                    ],
                  );
                }),
              ),
              const SizedBox(height: 24),

              // Steps Contents
              if (_currentStep == 1) _buildStep1(theme),
              if (_currentStep == 2) _buildStep2(theme),
              if (_currentStep == 3) _buildStep3(theme),
              if (_currentStep == 4) _buildStep4(theme),
              if (_currentStep == 5) _buildStep5(theme),
            ],
          ),
        ),
      ),
      actions: [
        if (_currentStep > 1)
          TextButton(
            onPressed: () => setState(() => _currentStep--),
            child: const Text("Back"),
          ),
        const Spacer(),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        if (_currentStep < 5)
          ElevatedButton(
            onPressed: widget.subjects.isEmpty ? null : () => setState(() => _currentStep++),
            child: const Text("Next"),
          )
        else
          ElevatedButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text("Save"),
          ),
      ],
    );
  }

  // STEP 1: Choose Subject
  Widget _buildStep1(ThemeData theme) {
    if (widget.subjects.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20.0),
        child: Text(
          "You must create a Subject first before scheduling a study session.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.red),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Choose Subject", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        DropdownButtonFormField<Subject>(
          initialValue: _selectedSubject,
          decoration: const InputDecoration(labelText: "Subject"),
          items: widget.subjects.map((sub) {
            return DropdownMenuItem<Subject>(
              value: sub,
              child: Text(sub.name),
            );
          }).toList(),
          onChanged: (val) {
            setState(() {
              _selectedSubject = val;
              _selectedChapterIds.clear();
              _availableChapters = [];
            });
            _loadChaptersForSubject();
          },
        ),
      ],
    );
  }

  // STEP 2: Choose Chapters (Checkboxes)
  Widget _buildStep2(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Choose Chapters", style: TextStyle(fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: () {
                setState(() {
                  if (_selectedChapterIds.length == _availableChapters.length) {
                    _selectedChapterIds.clear();
                  } else {
                    _selectedChapterIds.clear();
                    _selectedChapterIds.addAll(_availableChapters.map((c) => c.id));
                  }
                });
              },
              child: Text(_selectedChapterIds.length == _availableChapters.length ? "Deselect All" : "Select All"),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_availableChapters.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("No chapters found in this subject. Go to Subjects details to add some.", style: TextStyle(fontStyle: FontStyle.italic)),
          )
        else
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _availableChapters.length,
              itemBuilder: (context, index) {
                final chapter = _availableChapters[index];
                final isChecked = _selectedChapterIds.contains(chapter.id);
                return CheckboxListTile(
                  title: Text(chapter.name),
                  value: isChecked,
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (bool? val) {
                    setState(() {
                      if (val == true) {
                        _selectedChapterIds.add(chapter.id);
                      } else {
                        _selectedChapterIds.remove(chapter.id);
                      }
                    });
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildStep3(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Choose Study Type", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        RadioGroup<String>(
          groupValue: _selectedStudyType,
          onChanged: (val) {
            if (val != null) {
              setState(() => _selectedStudyType = val);
            }
          },
          child: Column(
            children: AppConstants.studyTypes.map(
              (type) => RadioListTile<String>(
                title: Text(type),
                value: type,
              ),
            ).toList(),
          ),
        ),
      ],
    );
  }

  // STEP 4: Choose Timing Slot
  Widget _buildStep4(ThemeData theme) {
    final startStr = DateFormat('hh:mm a').format(_startTime);
    final endStr = DateFormat('hh:mm a').format(_endTime);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Select Time Slot", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ListTile(
          title: const Text("Start Time"),
          trailing: Text(startStr, style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
          onTap: () => _selectTime(true),
        ),
        const Divider(),
        ListTile(
          title: const Text("End Time"),
          trailing: Text(endStr, style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
          onTap: () => _selectTime(false),
        ),
      ],
    );
  }

  // STEP 5: Add Optional Notes
  Widget _buildStep5(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Optional Notes", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        TextField(
          controller: _notesController,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: "Add specific goals or reminders for this study session...",
          ),
        ),
      ],
    );
  }
}
