import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/progress_viewmodel.dart';

class ProgressView extends StatefulWidget {
  const ProgressView({super.key});

  @override
  State<ProgressView> createState() => _ProgressViewState();
}

class _ProgressViewState extends State<ProgressView> {
  final _studentNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProgressViewModel>(context, listen: false).fetchProgressData();
    });
  }

  @override
  void dispose() {
    _studentNameController.dispose();
    super.dispose();
  }

  void _triggerReportAction(BuildContext context, ProgressViewModel vm, bool isPrint) {
    if (_studentNameController.text.trim().isEmpty) {
      // Prompt for name
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Enter Student Name"),
            content: TextField(
              controller: _studentNameController,
              autofocus: true,
              decoration: const InputDecoration(hintText: "Your Name"),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              TextButton(
                onPressed: () {
                  if (_studentNameController.text.trim().isNotEmpty) {
                    Navigator.pop(context);
                    if (isPrint) {
                      vm.printReport(_studentNameController.text.trim());
                    } else {
                      vm.shareReport(_studentNameController.text.trim());
                    }
                  }
                },
                child: const Text("Generate"),
              ),
            ],
          );
        },
      );
    } else {
      if (isPrint) {
        vm.printReport(_studentNameController.text.trim());
      } else {
        vm.shareReport(_studentNameController.text.trim());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final progressVm = Provider.of<ProgressViewModel>(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: progressVm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => progressVm.fetchProgressData(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- STREAK HERO CARD ---
                    _buildStreakHeroCard(theme, progressVm),
                    const SizedBox(height: 16),

                    // --- HOURS STATISTICS CARDS ---
                    _buildHoursMetrics(theme, progressVm),
                    const SizedBox(height: 16),

                    // --- CUSTOM CHARTS SECTION ---
                    _buildVisualChartsSection(theme, progressVm),
                    const SizedBox(height: 16),

                    // --- SUBJECTS PROGRESS TRACKER ---
                    _buildSubjectProgressCard(theme, progressVm),
                    const SizedBox(height: 16),

                    // --- REPORT PDF ACTION BUTTONS ---
                    _buildPdfReportActions(theme, progressVm),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStreakHeroCard(ThemeData theme, ProgressViewModel vm) {
    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "STUDY STREAK",
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "${vm.streakCount} Days",
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Keep studying daily to maintain your streak!",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Icon(
              Icons.local_fire_department,
              size: 72,
              color: Colors.orange[800],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHoursMetrics(ThemeData theme, ProgressViewModel vm) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      childAspectRatio: 1.0,
      children: [
        _buildMetricBox(theme, "Today", "${vm.todayHours.toStringAsFixed(1)}h", theme.colorScheme.primary),
        _buildMetricBox(theme, "This Week", "${vm.weeklyHours.toStringAsFixed(1)}h", Colors.teal),
        _buildMetricBox(theme, "This Month", "${vm.monthlyHours.toStringAsFixed(1)}h", Colors.indigo),
      ],
    );
  }

  Widget _buildMetricBox(ThemeData theme, String label, String value, Color accentColor) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: theme.textTheme.bodySmall),
            const SizedBox(height: 6),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisualChartsSection(ThemeData theme, ProgressViewModel vm) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Activity Breakdown",
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Sessions segment
                Column(
                  children: [
                    SizedBox(
                      height: 100,
                      width: 100,
                      child: CustomPaint(
                        painter: RingChartPainter(
                          completed: vm.completedSessionsCount,
                          pending: vm.pendingSessionsCount,
                          completedColor: theme.colorScheme.primary,
                          pendingColor: theme.colorScheme.surfaceContainerHighest,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Sessions",
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "${vm.completedSessionsCount} of ${vm.completedSessionsCount + vm.pendingSessionsCount}",
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),

                // Chapters segment
                Column(
                  children: [
                    SizedBox(
                      height: 100,
                      width: 100,
                      child: CustomPaint(
                        painter: RingChartPainter(
                          completed: vm.completedChaptersCount,
                          pending: max(0, vm.totalChaptersCount - vm.completedChaptersCount),
                          completedColor: Colors.teal,
                          pendingColor: theme.colorScheme.surfaceContainerHighest,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Chapters",
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "${vm.completedChaptersCount} of ${vm.totalChaptersCount}",
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectProgressCard(ThemeData theme, ProgressViewModel vm) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Subject Progress",
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (vm.subjects.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text("No subjects tracked.", style: TextStyle(fontStyle: FontStyle.italic)),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: vm.subjects.length,
                itemBuilder: (context, index) {
                  final subject = vm.subjects[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(subject.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            Text("${subject.progressPercentage.toStringAsFixed(0)}%"),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: subject.progressPercentage / 100.0,
                            minHeight: 6,
                            backgroundColor: theme.colorScheme.surfaceContainerHighest,
                            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPdfReportActions(ThemeData theme, ProgressViewModel vm) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Progress Reports",
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Generate professional PDF reports documenting your syllabus coverages, hours completion, and timetable lists.",
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _triggerReportAction(context, vm, false),
                    icon: const Icon(Icons.share_outlined),
                    label: const Text("Share PDF"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _triggerReportAction(context, vm, true),
                    icon: const Icon(Icons.print_outlined),
                    label: const Text("Print Report"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Circular segment ring painter for visualizing progress ratios
class RingChartPainter extends CustomPainter {
  final int completed;
  final int pending;
  final Color completedColor;
  final Color pendingColor;

  RingChartPainter({
    required this.completed,
    required this.pending,
    required this.completedColor,
    required this.pendingColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final total = completed + pending;
    const strokeWidth = 10.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final paintBg = Paint()
      ..color = pendingColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, paintBg);

    if (total == 0) return;

    final paintProgress = Paint()
      ..color = completedColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    final sweepAngle = (completed / total) * 2 * pi;
    // Start drawing from top (-pi / 2)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      paintProgress,
    );
  }

  @override
  bool shouldRepaint(covariant RingChartPainter oldDelegate) {
    return oldDelegate.completed != completed ||
        oldDelegate.pending != pending ||
        oldDelegate.completedColor != completedColor ||
        oldDelegate.pendingColor != pendingColor;
  }
}
