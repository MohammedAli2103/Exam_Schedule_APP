import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/study_session.dart';
import '../../models/subject.dart';
import '../../models/chapter.dart';
import '../../utils/constants.dart';
import '../../viewmodels/schedule_viewmodel.dart';
import '../../viewmodels/subject_viewmodel.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../viewmodels/progress_viewmodel.dart';

class CreateStudySessionPage extends StatefulWidget {
  final StudySession? existingSession;

  const CreateStudySessionPage({
    super.key,
    this.existingSession,
  });

  @override
  State<CreateStudySessionPage> createState() => _CreateStudySessionPageState();
}

class _CreateStudySessionPageState extends State<CreateStudySessionPage> {
  final _formKey = GlobalKey<FormState>();

  // Values
  String? _selectedSubjectId;
  List<Chapter> _availableChapters = [];
  final List<String> _selectedChapterIds = [];
  String? _selectedStudyType;
  final _customStudyTypeController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  bool _isSaving = false;
  bool _isChaptersLoading = false;

  @override
  void initState() {
    super.initState();

    final scheduleVm = Provider.of<ScheduleViewModel>(context, listen: false);
    
    // Default dates and times
    _selectedDate = scheduleVm.selectedDate;
    _startTime = TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 1)));
    // Rounded to nearest hour
    _startTime = TimeOfDay(hour: _startTime!.hour, minute: 0);
    _endTime = TimeOfDay(hour: _startTime!.hour + 2, minute: 0);

    // If editing existing session, pre-populate
    if (widget.existingSession != null) {
      final session = widget.existingSession!;
      _selectedSubjectId = session.subjectId;
      
      final isStandardType = AppConstants.studyTypes.contains(session.studyType);
      if (isStandardType) {
        _selectedStudyType = session.studyType;
      } else {
        _selectedStudyType = 'Custom';
        _customStudyTypeController.text = session.studyType;
      }
      
      _notesController.text = session.notes ?? '';
      _selectedDate = session.startTime;
      _startTime = TimeOfDay.fromDateTime(session.startTime);
      _endTime = TimeOfDay.fromDateTime(session.endTime);
      _selectedChapterIds.addAll(session.chapters.map((c) => c.id));
    }

    // Load subjects
    final subVm = Provider.of<SubjectViewModel>(context, listen: false);
    if (!subVm.isSubjectsLoaded) {
      subVm.fetchSubjects();
    }

    // Auto-select subject if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final subjectsList = subVm.subjects;
      if (subjectsList.isNotEmpty) {
        setState(() {
          _selectedSubjectId ??= subjectsList.first.id;
        });
        _loadChaptersForSubject();
      }
    });
  }

  @override
  void dispose() {
    _customStudyTypeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _loadChaptersForSubject() async {
    if (_selectedSubjectId == null) return;
    setState(() {
      _isChaptersLoading = true;
      _availableChapters = [];
    });

    final subVm = Provider.of<SubjectViewModel>(context, listen: false);
    try {
      await subVm.fetchChapters(_selectedSubjectId!);
      if (mounted) {
        setState(() {
          _availableChapters = subVm.chapters;
          // Filter selected chapters list to ensure no stale ids are left
          final availableIds = _availableChapters.map((c) => c.id).toSet();
          _selectedChapterIds.removeWhere((id) => !availableIds.contains(id));
        });
      }
    } catch (e) {
      debugPrint("Error loading chapters: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isChaptersLoading = false;
        });
      }
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(bool isStart) async {
    final initialTime = isStart 
        ? (_startTime ?? const TimeOfDay(hour: 10, minute: 0))
        : (_endTime ?? const TimeOfDay(hour: 12, minute: 0));

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
          _endTime = TimeOfDay(hour: (picked.hour + 1) % 24, minute: picked.minute);
        } else {
          _endTime = picked;
        }
      });
    }
  }

  String _calculateDuration() {
    if (_startTime == null || _endTime == null) return "0 mins";
    final startMinutes = _startTime!.hour * 60 + _startTime!.minute;
    final endMinutes = _endTime!.hour * 60 + _endTime!.minute;

    int diff = endMinutes - startMinutes;
    if (diff <= 0) diff += 24 * 60; // handles midnight span

    final hrs = diff ~/ 60;
    final mins = diff % 60;

    if (hrs == 0) {
      return "$mins mins";
    } else if (mins == 0) {
      return "$hrs ${hrs == 1 ? 'hour' : 'hours'}";
    } else {
      return "$hrs ${hrs == 1 ? 'hr' : 'hrs'} $mins ${mins == 1 ? 'min' : 'mins'}";
    }
  }

  void _showAddSubjectDialogInline() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("New Subject"),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: "Enter subject name (e.g. Operating Systems)",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  final subVm = Provider.of<SubjectViewModel>(context, listen: false);
                  final success = await subVm.addSubject(name);
                  if (success && context.mounted) {
                    Navigator.pop(context);
                    final subjectsList = subVm.subjects;
                    if (subjectsList.isNotEmpty) {
                      setState(() {
                        _selectedSubjectId = subjectsList.last.id;
                      });
                      _loadChaptersForSubject();
                    }
                  }
                }
              },
              child: const Text("Create"),
            ),
          ],
        );
      },
    );
  }

  void _saveSession() async {
    final scheduleVm = Provider.of<ScheduleViewModel>(context, listen: false);
    final homeVm = Provider.of<HomeViewModel>(context, listen: false);
    final theme = Theme.of(context);

    // Validate Subject
    if (_selectedSubjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a subject.")),
      );
      return;
    }

    // Validate Chapters
    if (_selectedChapterIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select at least one chapter.")),
      );
      return;
    }

    // Validate Study Type
    if (_selectedStudyType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a study type.")),
      );
      return;
    }

    final finalStudyType = _selectedStudyType == 'Custom' 
        ? _customStudyTypeController.text.trim()
        : _selectedStudyType;

    if (finalStudyType == null || finalStudyType.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a custom study type.")),
      );
      return;
    }

    // Validate Date and Time
    if (_selectedDate == null || _startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select date and time slots.")),
      );
      return;
    }

    final startDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _startTime!.hour,
      _startTime!.minute,
    );

    var endDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _endTime!.hour,
      _endTime!.minute,
    );

    // If End Time is before Start Time, assume next day
    if (endDateTime.isBefore(startDateTime)) {
      endDateTime = endDateTime.add(const Duration(days: 1));
    }

    if (endDateTime.isAtSameMomentAs(startDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("End time cannot be identical to start time.")),
      );
      return;
    }

    setState(() => _isSaving = true);

    bool success;
    if (widget.existingSession != null) {
      success = await scheduleVm.updateSession(
        sessionId: widget.existingSession!.id,
        subjectId: _selectedSubjectId!,
        studyType: finalStudyType,
        chapterIds: _selectedChapterIds,
        startTime: startDateTime,
        endTime: endDateTime,
        isCompleted: widget.existingSession!.isCompleted,
        notes: _notesController.text.trim(),
      );
    } else {
      debugPrint("[CreateStudySessionPage] _saveSession: calling scheduleVm.createSession()");
      success = await scheduleVm.createSession(
        subjectId: _selectedSubjectId!,
        studyType: finalStudyType,
        chapterIds: _selectedChapterIds,
        startTime: startDateTime,
        endTime: endDateTime,
        notes: _notesController.text.trim(),
      );
    }

    setState(() => _isSaving = false);

    if (success && mounted) {
      homeVm.fetchHomeSessions(forceRefresh: true);
      Provider.of<ProgressViewModel>(context, listen: false).fetchProgressData(forceRefresh: true);
      scheduleVm.changeSelectedDate(startDateTime);
      final hasFailed = scheduleVm.notificationSchedulingFailed;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(hasFailed
              ? (widget.existingSession != null
                  ? "Study session updated successfully. Reminder could not be scheduled."
                  : "Study session created successfully. Reminder could not be scheduled.")
              : (widget.existingSession != null
                  ? "Study session updated successfully!"
                  : "Study session scheduled successfully!")),
          backgroundColor: hasFailed ? Colors.orange : Colors.green,
        ),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(scheduleVm.errorMessage ?? "Failed to save study session."),
          backgroundColor: theme.colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subVm = Provider.of<SubjectViewModel>(context);
    final subjects = subVm.subjects;

    final isEditing = widget.existingSession != null;
    final selectedSubject = subjects.isEmpty
        ? null
        : subjects.firstWhere((s) => s.id == _selectedSubjectId, orElse: () => subjects.first);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? "Edit Study Session" : "Schedule Session"),
        elevation: 0,
      ),
      body: subVm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : subjects.isEmpty
              ? _buildEmptySubjectsState(theme)
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    children: [
                      // 1. SUBJECT SECTION
                      _buildSubjectCard(theme, subjects),
                      const SizedBox(height: 16),

                      // 2. CHAPTERS SECTION
                      _buildChaptersCard(theme),
                      const SizedBox(height: 16),

                      // 3. STUDY TYPE SECTION
                      _buildStudyTypeCard(theme),
                      const SizedBox(height: 16),

                      // 4. DATE AND TIME SECTION
                      _buildDateTimeCard(theme),
                      const SizedBox(height: 16),

                      // 5. NOTES SECTION
                      _buildNotesCard(theme),
                      const SizedBox(height: 24),

                      // 6. SUMMARY CARD
                      _buildSummaryCard(theme, selectedSubject),
                      const SizedBox(height: 24),

                      // 7. ACTIONS BUTTONS
                      _buildActionButtons(theme),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
    );
  }

  Widget _buildEmptySubjectsState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.library_books_outlined, size: 64, color: theme.colorScheme.secondary.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              "No subjects available.",
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Create a subject first before scheduling a study session.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddSubjectDialogInline,
              icon: const Icon(Icons.add),
              label: const Text("Create Subject"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectCard(ThemeData theme, List<Subject> subjects) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("1. Subject", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: "Select Subject",
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    key: ValueKey(_selectedSubjectId),
                    initialValue: _selectedSubjectId,
                    items: subjects.map((sub) {
                      return DropdownMenuItem<String>(
                        value: sub.id,
                        child: Text(sub.name),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedSubjectId = val;
                        _selectedChapterIds.clear();
                      });
                      _loadChaptersForSubject();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: _showAddSubjectDialogInline,
                  icon: const Icon(Icons.add),
                  tooltip: "Add New Subject",
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChaptersCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("2. Chapters", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                if (_availableChapters.isNotEmpty)
                  Text(
                    "Selected: ${_selectedChapterIds.length} / ${_availableChapters.length}",
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_selectedSubjectId == null)
              const Text("Please select a subject first.", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey))
            else if (_isChaptersLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: Column(
                    children: [
                      CircularProgressIndicator(strokeWidth: 3),
                      SizedBox(height: 12),
                      Text("Loading chapters...", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              )
            else if (_availableChapters.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  "No chapters found in this subject. Go to Subjects detail to add chapters.",
                  style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic, color: theme.colorScheme.error),
                ),
              )
            else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
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
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableChapters.map((chapter) {
                  final isSelected = _selectedChapterIds.contains(chapter.id);
                  return FilterChip(
                    label: Text(chapter.name),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedChapterIds.add(chapter.id);
                        } else {
                          _selectedChapterIds.remove(chapter.id);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStudyTypeCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("3. Study Type", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppConstants.studyTypes.map((type) {
                final isSelected = _selectedStudyType == type;
                return ChoiceChip(
                  label: Text(type),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedStudyType = selected ? type : null;
                    });
                  },
                );
              }).toList(),
            ),
            if (_selectedStudyType == 'Custom') ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _customStudyTypeController,
                decoration: const InputDecoration(
                  labelText: "Custom Study Type",
                  hintText: "e.g., Assignment, Lab, Writing Practice",
                ),
                validator: (val) {
                  if (_selectedStudyType == 'Custom' && (val == null || val.trim().isEmpty)) {
                    return "Please enter custom study type";
                  }
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeCard(ThemeData theme) {
    final dateStr = _selectedDate == null 
        ? "Select Date" 
        : DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate!);
    final startStr = _startTime == null ? "Select Start" : _startTime!.format(context);
    final endStr = _endTime == null ? "Select End" : _endTime!.format(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("4. Schedule Date & Time Slot", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            
            // Date Picker Tile
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.calendar_today, color: theme.colorScheme.primary),
              title: const Text("Study Date"),
              subtitle: Text(dateStr, style: TextStyle(fontWeight: _selectedDate != null ? FontWeight.bold : FontWeight.normal)),
              trailing: const Icon(Icons.arrow_drop_down),
              onTap: _selectDate,
            ),
            const Divider(),

            // Times Row
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.access_time, color: theme.colorScheme.primary),
                    title: const Text("Start Time"),
                    subtitle: Text(startStr, style: TextStyle(fontWeight: _startTime != null ? FontWeight.bold : FontWeight.normal)),
                    onTap: () => _selectTime(true),
                  ),
                ),
                Container(width: 1, height: 40, color: theme.dividerColor),
                Expanded(
                  child: ListTile(
                    contentPadding: const EdgeInsets.only(left: 16),
                    leading: Icon(Icons.access_time_filled, color: theme.colorScheme.primary),
                    title: const Text("End Time"),
                    subtitle: Text(endStr, style: TextStyle(fontWeight: _endTime != null ? FontWeight.bold : FontWeight.normal)),
                    onTap: () => _selectTime(false),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("5. Session Notes (Optional)", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: "Add specific goals or reminders for this session...",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(ThemeData theme, Subject? selectedSubject) {
    final chaptersListStr = _selectedChapterIds.isEmpty
        ? "No chapters selected"
        : _availableChapters
            .where((c) => _selectedChapterIds.contains(c.id))
            .map((c) => c.name)
            .join(", ");

    final finalStudyType = _selectedStudyType == 'Custom' 
        ? _customStudyTypeController.text.trim()
        : _selectedStudyType;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.primaryContainer, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.assignment_turned_in_outlined, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text("Session Summary", style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(height: 24),
          _buildSummaryRow(theme, "Subject:", selectedSubject?.name ?? "Not Selected"),
          const SizedBox(height: 8),
          _buildSummaryRow(theme, "Chapters:", _selectedChapterIds.isEmpty ? "None" : "${_selectedChapterIds.length} chapter(s) selected"),
          if (_selectedChapterIds.isNotEmpty) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 100.0),
              child: Text(
                chaptersListStr,
                style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic, color: Colors.grey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          const SizedBox(height: 8),
          _buildSummaryRow(theme, "Study Type:", finalStudyType == null || finalStudyType.isEmpty ? "Not Selected" : finalStudyType),
          const SizedBox(height: 8),
          _buildSummaryRow(
            theme, 
            "Date:", 
            _selectedDate == null ? "Not Selected" : DateFormat('MMMM d, yyyy').format(_selectedDate!)
          ),
          const SizedBox(height: 8),
          _buildSummaryRow(
            theme, 
            "Time slot:", 
            (_startTime == null || _endTime == null) 
                ? "Not Selected" 
                : "${_startTime!.format(context)} - ${_endTime!.format(context)}"
          ),
          const SizedBox(height: 8),
          _buildSummaryRow(theme, "Duration:", _calculateDuration()),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(ThemeData theme, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(label, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.secondary)),
        ),
        Expanded(
          child: Text(value, style: theme.textTheme.bodyMedium),
        ),
      ],
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text("Cancel"),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveSession,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isSaving
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(widget.existingSession != null ? "Update Session" : "Schedule Session"),
          ),
        ),
      ],
    );
  }
}
