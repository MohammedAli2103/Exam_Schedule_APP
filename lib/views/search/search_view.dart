import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/search_viewmodel.dart';
import '../../models/subject.dart';
import '../../models/chapter.dart';
import '../../models/note.dart';
import '../../models/study_session.dart';
import '../subjects/subject_details_view.dart';

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query, SearchViewModel vm) {
    vm.performGlobalSearch(query);
  }

  @override
  Widget build(BuildContext context) {
    final searchVm = Provider.of<SearchViewModel>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: "Search subjects, chapters, notes, schedules...",
            border: InputBorder.none,
            filled: false,
          ),
          onChanged: (val) => _onSearchChanged(val, searchVm),
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                searchVm.clearSearch();
              },
            ),
        ],
      ),
      body: searchVm.isSearching
          ? const Center(child: CircularProgressIndicator())
          : searchVm.results.isEmpty
              ? _buildEmptyState(theme)
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: searchVm.results.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final result = searchVm.results[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getColorForType(result.type, theme),
                        child: Icon(_getIconForType(result.type), color: Colors.white, size: 20),
                      ),
                      title: Text(result.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(result.subtitle),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                      onTap: () => _handleResultTap(context, result),
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    final isQueryEmpty = _searchController.text.trim().isEmpty;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isQueryEmpty ? Icons.search : Icons.sentiment_dissatisfied,
            size: 64,
            color: theme.colorScheme.secondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            isQueryEmpty ? "Type to search..." : "No results match your search.",
            style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.secondary),
          ),
          const SizedBox(height: 4),
          Text(
            isQueryEmpty
                ? "Search across all subjects, chapters, notes, and study slots."
                : "Try checking your spelling or search for another keyword.",
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  IconData _getIconForType(SearchResultType type) {
    switch (type) {
      case SearchResultType.subject:
        return Icons.bookmark;
      case SearchResultType.chapter:
        return Icons.menu_book;
      case SearchResultType.note:
        return Icons.description;
      case SearchResultType.session:
        return Icons.alarm;
    }
  }

  Color _getColorForType(SearchResultType type, ThemeData theme) {
    switch (type) {
      case SearchResultType.subject:
        return theme.colorScheme.primary;
      case SearchResultType.chapter:
        return Colors.teal;
      case SearchResultType.note:
        return Colors.redAccent;
      case SearchResultType.session:
        return Colors.indigo;
    }
  }

  void _handleResultTap(BuildContext context, SearchResult result) {
    switch (result.type) {
      case SearchResultType.subject:
        final subject = result.originalObject as Subject;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SubjectDetailsView(
              subjectId: subject.id,
              subjectName: subject.name,
            ),
          ),
        );
        break;

      case SearchResultType.chapter:
        final chapter = result.originalObject as Chapter;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SubjectDetailsView(
              subjectId: chapter.subjectId,
              subjectName: "Subject Details",
              initialChapterIdToOpenNotes: chapter.id,
            ),
          ),
        );
        break;

      case SearchResultType.note:
        final note = result.originalObject as Note;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SubjectDetailsView(
              subjectId: note.chapterId, // We map the chapter details view
              subjectName: "Subject Details",
              initialChapterIdToOpenNotes: note.chapterId,
            ),
          ),
        );
        break;

      case SearchResultType.session:
        final session = result.originalObject as StudySession;
        // Show study session quick details dialog
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text("${session.subjectName ?? 'Session'} - ${session.studyType}"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Timing: ${session.startTime.toLocal()} to ${session.endTime.toLocal()}"),
                  const SizedBox(height: 8),
                  Text("Status: ${session.isCompleted ? 'Completed' : 'Pending'}"),
                  if (session.notes != null) ...[
                    const SizedBox(height: 12),
                    const Text("Notes:", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(session.notes!),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close"),
                ),
              ],
            );
          },
        );
        break;
    }
  }
}
