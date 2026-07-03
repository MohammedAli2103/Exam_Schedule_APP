import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/subject.dart';
import '../models/study_session.dart';

class PdfService {
  static final PdfService instance = PdfService._internal();
  PdfService._internal();

  /// Generates the PDF document as bytes.
  Future<Uint8List> generateReportPdf({
    required String studentName,
    required List<Subject> subjects,
    required List<StudySession> sessions,
    required double totalHoursCompleted,
    required double totalHoursRemaining,
    required int completedSessionsCount,
    required int pendingSessionsCount,
    required int completedChaptersCount,
    required int totalChaptersCount,
  }) async {
    final pdf = pw.Document();

    final now = DateTime.now();
    final dateStr = DateFormat('MMMM d, yyyy').format(now);
    final progressPercentage = totalChaptersCount > 0
        ? (completedChaptersCount / totalChaptersCount) * 100
        : 0.0;

    // Define colors matching M3 accents
    final primaryColor = PdfColor.fromHex('#6750A4');
    final secondaryColor = PdfColor.fromHex('#625B71');
    final dividerColor = PdfColor.fromHex('#CAC4D0');
    final successColor = PdfColor.fromHex('#2E7D32');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // --- HEADER ---
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      "Exam Preparation Report",
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text("Student: $studentName",
                        style: const pw.TextStyle(fontSize: 14)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text("Date: $dateStr",
                        style: const pw.TextStyle(fontSize: 12)),
                    pw.Text("Generated via ExamPrep App",
                        style: pw.TextStyle(
                            fontSize: 10,
                            fontStyle: pw.FontStyle.italic,
                            color: secondaryColor)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 12),
            pw.Divider(color: dividerColor, thickness: 1),
            pw.SizedBox(height: 16),

            // --- SUMMARY CARDS ---
            pw.Text(
              "Study Analytics Summary",
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: primaryColor,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryBox("Overall Progress", "${progressPercentage.toStringAsFixed(1)}%", successColor),
                _buildSummaryBox("Completed Hours", "${totalHoursCompleted.toStringAsFixed(1)} hrs", primaryColor),
                _buildSummaryBox("Remaining Hours", "${totalHoursRemaining.toStringAsFixed(1)} hrs", secondaryColor),
              ],
            ),
            pw.SizedBox(height: 12),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryBox("Completed Chapters", "$completedChaptersCount / $totalChaptersCount", primaryColor),
                _buildSummaryBox("Completed Sessions", "$completedSessionsCount", successColor),
                _buildSummaryBox("Pending Sessions", "$pendingSessionsCount", secondaryColor),
              ],
            ),
            pw.SizedBox(height: 24),

            // --- SUBJECTS TABLE ---
            pw.Text(
              "Subject-wise Progress",
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: primaryColor,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: dividerColor, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(1.5),
                2: const pw.FlexColumnWidth(1.5),
                3: const pw.FlexColumnWidth(1.5),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColor.fromHex('#EADDFF')),
                  children: [
                    _buildTableCell("Subject Name", isHeader: true),
                    _buildTableCell("Chapters", isHeader: true),
                    _buildTableCell("Notes count", isHeader: true),
                    _buildTableCell("Progress %", isHeader: true),
                  ],
                ),
                ...subjects.map(
                  (sub) => pw.TableRow(
                    children: [
                      _buildTableCell(sub.name),
                      _buildTableCell(sub.chapterCount.toString()),
                      _buildTableCell(sub.notesCount.toString()),
                      _buildTableCell("${sub.progressPercentage.toStringAsFixed(1)}%"),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 24),

            // --- SCHEDULE TIMETABLE ---
            pw.Text(
              "Timetable / Scheduled Sessions",
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: primaryColor,
              ),
            ),
            pw.SizedBox(height: 8),
            if (sessions.isEmpty)
              pw.Text("No sessions scheduled yet.",
                  style: const pw.TextStyle(fontStyle: pw.FontStyle.italic))
            else
              pw.Table(
                border: pw.TableBorder.all(color: dividerColor, width: 0.5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2),
                  1: const pw.FlexColumnWidth(2.5),
                  2: const pw.FlexColumnWidth(2),
                  3: const pw.FlexColumnWidth(3),
                  4: const pw.FlexColumnWidth(1.5),
                },
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColor.fromHex('#EADDFF')),
                    children: [
                      _buildTableCell("Time Slot", isHeader: true),
                      _buildTableCell("Subject", isHeader: true),
                      _buildTableCell("Type", isHeader: true),
                      _buildTableCell("Chapters Covered", isHeader: true),
                      _buildTableCell("Status", isHeader: true),
                    ],
                  ),
                  ...sessions.map(
                    (session) {
                      final timeStr =
                          "${DateFormat('MM/dd').format(session.startTime)} ${DateFormat('h:mm a').format(session.startTime)}-${DateFormat('h:mm a').format(session.endTime)}";
                      final chaptersList = session.chapters.map((c) => c.name).join(', ');
                      return pw.TableRow(
                        children: [
                          _buildTableCell(timeStr),
                          _buildTableCell(session.subjectName ?? 'Unknown'),
                          _buildTableCell(session.studyType),
                          _buildTableCell(chaptersList.isEmpty ? 'None' : chaptersList),
                          _buildTableCell(session.isCompleted ? 'Completed' : 'Pending'),
                        ],
                      );
                    },
                  ),
                ],
              ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static pw.Widget _buildSummaryBox(String label, String value, PdfColor color) {
    return pw.Container(
      width: 150,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color, width: 1),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  /// Print the PDF report directly.
  Future<void> printReport(Uint8List pdfBytes) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Exam_Preparation_Report.pdf',
    );
  }

  /// Share the PDF report through native OS share.
  Future<void> shareReport(Uint8List pdfBytes) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/Exam_Preparation_Report.pdf');
    await file.writeAsBytes(pdfBytes);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'My Exam Preparation Progress Report',
    );
  }
}
