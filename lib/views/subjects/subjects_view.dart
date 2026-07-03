import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/subject_viewmodel.dart';
import '../../models/subject.dart';
import 'subject_details_view.dart';

class SubjectsView extends StatefulWidget {
  const SubjectsView({super.key});

  @override
  State<SubjectsView> createState() => _SubjectsViewState();
}

class _SubjectsViewState extends State<SubjectsView> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SubjectViewModel>(context, listen: false).fetchSubjects();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subVm = Provider.of<SubjectViewModel>(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        children: [
          // --- SEARCH BAR ---
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => subVm.searchSubjects(val),
              decoration: InputDecoration(
                hintText: "Search subjects...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          subVm.searchSubjects('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              ),
            ),
          ),

          // --- SUBJECTS LIST ---
          Expanded(
            child: subVm.isLoading
                ? const Center(child: CircularProgressIndicator())
                : subVm.subjects.isEmpty
                    ? _buildEmptyState(theme)
                    : RefreshIndicator(
                        onRefresh: () => subVm.fetchSubjects(),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          itemCount: subVm.subjects.length,
                          itemBuilder: (context, index) {
                            final subject = subVm.subjects[index];
                            return _buildSubjectCard(context, theme, subVm, subject);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSubjectDialog(context, subVm),
        icon: const Icon(Icons.add),
        label: const Text("Add Subject"),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.library_books_outlined, size: 64, color: theme.colorScheme.secondary.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            "No subjects created yet.",
            style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.secondary),
          ),
          const SizedBox(height: 8),
          const Text("Tap 'Add Subject' below to begin manual setup."),
        ],
      ),
    );
  }

  Widget _buildSubjectCard(
    BuildContext context,
    ThemeData theme,
    SubjectViewModel subVm,
    Subject subject,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SubjectDetailsView(
                subjectId: subject.id,
                subjectName: subject.name,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      subject.name,
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (val) {
                      if (val == 'edit') {
                        _showEditSubjectDialog(context, subVm, subject);
                      } else if (val == 'delete') {
                        _confirmDeleteSubject(context, subVm, subject);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Rename')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("${subject.chapterCount} Chapters", style: theme.textTheme.bodyMedium),
                  Text("${subject.notesCount} Uploaded Notes", style: theme.textTheme.bodyMedium),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: subject.progressPercentage / 100.0,
                        minHeight: 6,
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "${subject.progressPercentage.toStringAsFixed(0)}%",
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddSubjectDialog(BuildContext context, SubjectViewModel subVm) {
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
                  final success = await subVm.addSubject(name);
                  if (success && context.mounted) {
                    Navigator.pop(context);
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

  void _showEditSubjectDialog(BuildContext context, SubjectViewModel subVm, Subject subject) {
    final controller = TextEditingController(text: subject.name);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Rename Subject"),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: "Enter subject name",
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
                if (name.isNotEmpty && name != subject.name) {
                  final success = await subVm.editSubject(subject.id, name);
                  if (success && context.mounted) {
                    Navigator.pop(context);
                  }
                }
              },
              child: const Text("Rename"),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteSubject(BuildContext context, SubjectViewModel subVm, Subject subject) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete Subject?"),
          content: Text(
            "Are you sure you want to delete '${subject.name}'?\n\nThis will permanently remove:\n• All chapters\n• All uploaded notes\n• All schedule entries associated with this subject.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                final success = await subVm.deleteSubject(subject.id);
                if (success && context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Deleted ${subject.name}")),
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
}
