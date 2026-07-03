import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../viewmodels/subject_viewmodel.dart';
import '../../models/chapter.dart';
import '../../models/note.dart';

class SubjectDetailsView extends StatefulWidget {
  final String subjectId;
  final String subjectName;
  final String? initialChapterIdToOpenNotes;

  const SubjectDetailsView({
    super.key,
    required this.subjectId,
    required this.subjectName,
    this.initialChapterIdToOpenNotes,
  });

  @override
  State<SubjectDetailsView> createState() => _SubjectDetailsViewState();
}

class _SubjectDetailsViewState extends State<SubjectDetailsView> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final subVm = Provider.of<SubjectViewModel>(context, listen: false);
      await subVm.fetchChapters(widget.subjectId);

      if (!mounted) return;

      // Auto-trigger notes view if redirected from Home Page
      if (widget.initialChapterIdToOpenNotes != null) {
        final chapter = subVm.chapters.firstWhere(
          (c) => c.id == widget.initialChapterIdToOpenNotes,
          orElse: () => subVm.chapters.first,
        );
        _showChapterActions(context, subVm, chapter);
      }
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
      appBar: AppBar(
        title: Text(widget.subjectName),
      ),
      body: Column(
        children: [
          // --- SEARCH CHAPTERS ---
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => subVm.searchChapters(val),
              decoration: InputDecoration(
                hintText: "Search chapters...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          subVm.searchChapters('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              ),
            ),
          ),

          // --- CHAPTERS LIST ---
          Expanded(
            child: subVm.isDetailsLoading
                ? const Center(child: CircularProgressIndicator())
                : subVm.chapters.isEmpty
                    ? _buildEmptyState(theme)
                    : RefreshIndicator(
                        onRefresh: () => subVm.fetchChapters(widget.subjectId),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          itemCount: subVm.chapters.length,
                          itemBuilder: (context, index) {
                            final chapter = subVm.chapters[index];
                            return _buildChapterCard(context, theme, subVm, chapter);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddChapterDialog(context, subVm),
        icon: const Icon(Icons.add),
        label: const Text("Add Chapter"),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bookmark_outline, size: 64, color: theme.colorScheme.secondary.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            "No chapters inside this subject.",
            style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.secondary),
          ),
          const SizedBox(height: 8),
          const Text("Add chapters or modules to structure your studying."),
        ],
      ),
    );
  }

  Widget _buildChapterCard(
    BuildContext context,
    ThemeData theme,
    SubjectViewModel subVm,
    Chapter chapter,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showChapterActions(context, subVm, chapter),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              Checkbox(
                value: chapter.isCompleted,
                onChanged: (bool? val) {
                  if (val != null) {
                    subVm.toggleChapterCompletion(chapter.id, val);
                  }
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chapter.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        decoration: chapter.isCompleted ? TextDecoration.lineThrough : null,
                        color: chapter.isCompleted
                            ? theme.colorScheme.onSurface.withValues(alpha: 0.6)
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${chapter.notesCount} notes",
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.more_vert),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddChapterDialog(BuildContext context, SubjectViewModel subVm) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("New Chapter / Module"),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: "Chapter name (e.g. Chapter 1: Introduction)"),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            TextButton(
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  final success = await subVm.addChapter(widget.subjectId, name);
                  if (success && context.mounted) Navigator.pop(context);
                }
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  // Chapter Actions Bottom Sheet
  void _showChapterActions(BuildContext context, SubjectViewModel subVm, Chapter chapter) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                top: 16.0,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    chapter.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  
                  // Open Notes Action
                  ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: const Text("Open Notes"),
                    onTap: () {
                      Navigator.pop(context);
                      _showNotesManager(context, subVm, chapter);
                    },
                  ),

                  // Upload Notes Action
                  ListTile(
                    leading: const Icon(Icons.upload_file_outlined),
                    title: const Text("Upload Notes"),
                    onTap: () async {
                      Navigator.pop(context);
                      await _pickAndUploadNote(context, subVm, chapter);
                    },
                  ),

                  // Rename Chapter Action
                  ListTile(
                    leading: const Icon(Icons.edit_outlined),
                    title: const Text("Rename Chapter"),
                    onTap: () {
                      Navigator.pop(context);
                      _showRenameChapterDialog(context, subVm, chapter);
                    },
                  ),

                  // Delete Chapter Action
                  ListTile(
                    leading: const Icon(Icons.delete_outline, color: Colors.red),
                    title: const Text("Delete Chapter", style: TextStyle(color: Colors.red)),
                    onTap: () {
                      Navigator.pop(context);
                      _confirmDeleteChapter(context, subVm, chapter);
                    },
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text("Cancel", textAlign: TextAlign.center),
                    onTap: () => Navigator.pop(context),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Pick file and upload to storage & database
  Future<void> _pickAndUploadNote(
    BuildContext context,
    SubjectViewModel subVm,
    Chapter chapter,
  ) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'txt', 'jpg', 'png'],
    );

    if (result == null || result.files.single.path == null) return;

    final file = File(result.files.single.path!);
    final fileName = result.files.single.name;

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Uploading $fileName...")),
      );
    }

    final success = await subVm.uploadNote(
      file: file,
      chapterId: chapter.id,
      chapterName: chapter.name,
      subjectName: widget.subjectName,
      fileName: fileName,
    );

    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Notes uploaded successfully!"), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(subVm.errorMessage ?? "Upload failed"), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showNotesManager(BuildContext context, SubjectViewModel subVm, Chapter chapter) {
    subVm.fetchNotes(chapter.id);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Consumer<SubjectViewModel>(
          builder: (context, vm, child) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      "Notes: ${chapter.name}",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: vm.isNotesLoading
                          ? const Center(child: CircularProgressIndicator())
                          : vm.notes.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.description, size: 48, color: Colors.grey),
                                      const SizedBox(height: 12),
                                      const Text("No notes uploaded.", style: TextStyle(color: Colors.grey)),
                                      const SizedBox(height: 16),
                                      ElevatedButton.icon(
                                        onPressed: () async {
                                          Navigator.pop(context);
                                          await _pickAndUploadNote(context, subVm, chapter);
                                        },
                                        icon: const Icon(Icons.upload_file),
                                        label: const Text("Upload Notes"),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: vm.notes.length,
                                  itemBuilder: (context, index) {
                                    final note = vm.notes[index];
                                    return ListTile(
                                      leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                                      title: Text(note.name),
                                      subtitle: Text(
                                        note.fileSize != null
                                            ? "${(note.fileSize! / 1024).toStringAsFixed(1)} KB"
                                            : "Size unknown",
                                      ),
                                      trailing: PopupMenuButton<String>(
                                        onSelected: (val) {
                                          if (val == 'rename') {
                                            _showRenameNoteDialog(context, vm, note);
                                          } else if (val == 'delete') {
                                            _confirmDeleteNote(context, vm, note);
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          const PopupMenuItem(value: 'rename', child: Text('Rename')),
                                          const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                                        ],
                                      ),
                                      onTap: () {
                                        // Open note file link using deep linking or system launcher
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text("Opening file: ${note.fileUrl}")),
                                        );
                                      },
                                    );
                                  },
                                ),
                    ),
                    const Divider(),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Close"),
                          ),
                        ),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              Navigator.pop(context);
                              await _pickAndUploadNote(context, subVm, chapter);
                            },
                            icon: const Icon(Icons.upload),
                            label: const Text("Upload"),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showRenameChapterDialog(BuildContext context, SubjectViewModel subVm, Chapter chapter) {
    final controller = TextEditingController(text: chapter.name);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Rename Chapter"),
          content: TextField(controller: controller, autofocus: true),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            TextButton(
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isNotEmpty && name != chapter.name) {
                  final success = await subVm.renameChapter(chapter.id, name);
                  if (success && context.mounted) Navigator.pop(context);
                }
              },
              child: const Text("Rename"),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteChapter(BuildContext context, SubjectViewModel subVm, Chapter chapter) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete Chapter?"),
          content: Text(
            "Are you sure you want to delete '${chapter.name}'?\n\nThis will permanently delete:\n• All uploaded notes inside this chapter\n• All schedule references mappings to this chapter.",
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            TextButton(
              onPressed: () async {
                final success = await subVm.deleteChapter(chapter.id);
                if (success && context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Deleted ${chapter.name}")),
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

  void _showRenameNoteDialog(BuildContext context, SubjectViewModel subVm, Note note) {
    final controller = TextEditingController(text: note.name);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Rename Note File"),
          content: TextField(controller: controller, autofocus: true),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            TextButton(
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isNotEmpty && name != note.name) {
                  final success = await subVm.renameNote(note.id, name);
                  if (success && context.mounted) Navigator.pop(context);
                }
              },
              child: const Text("Rename"),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteNote(BuildContext context, SubjectViewModel subVm, Note note) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete Note?"),
          content: Text("Are you sure you want to delete '${note.name}' from storage?"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            TextButton(
              onPressed: () async {
                final success = await subVm.deleteNote(note);
                if (success && context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Note deleted.")),
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
