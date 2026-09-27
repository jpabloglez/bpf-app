import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/blood_pressure_reading.dart';
import '../models/reading_statistics.dart';

class PdfService {
  static const String disclaimer =
      'Disclaimer: This report is for informational purposes only and is not '
      'a substitute for professional medical advice. Always consult your '
      'healthcare provider about your blood pressure.';

  /// Builds the report and opens the system share sheet.
  static Future<void> generateAndShareReport(
    List<BloodPressureReading> readings,
    ReadingStatistics? statistics,
  ) async {
    final bytes = await buildReport(readings, statistics);
    await Printing.sharePdf(
      bytes: bytes,
      filename:
          'bp_report_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.pdf',
    );
  }

  /// Renders the report to PDF bytes.
  static Future<Uint8List> buildReport(
    List<BloodPressureReading> readings,
    ReadingStatistics? statistics, {
    DateTime? generatedAt,
  }) {
    final pdf = pw.Document(
      title: 'Blood Pressure Report',
      creator: 'BP Tracker',
    );
    final dateFormat = DateFormat.yMd();
    final timeFormat = DateFormat.Hm();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'Blood Pressure Report',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Text(
            'Generated: ${DateFormat.yMMMMd().format(generatedAt ?? DateTime.now())}',
            style: const pw.TextStyle(color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 20),

          // Summary statistics
          if (statistics != null) ...[
            pw.Text(
              'Summary Statistics',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              children: [
                _buildTableRow('Total Readings', '${statistics.totalReadings}'),
                _buildTableRow(
                  'Average BP',
                  '${statistics.avgSystolic.round()}/${statistics.avgDiastolic.round()} mmHg '
                      '(${statistics.averageCategory.label})',
                ),
                _buildTableRow(
                  'Average Heart Rate',
                  '${statistics.avgHeartRate.round()} bpm',
                ),
                if (statistics.highestReading != null)
                  _buildTableRow(
                    'Highest Reading',
                    '${statistics.highestReading!.systolic}/${statistics.highestReading!.diastolic} mmHg',
                  ),
                if (statistics.lowestReading != null)
                  _buildTableRow(
                    'Lowest Reading',
                    '${statistics.lowestReading!.systolic}/${statistics.lowestReading!.diastolic} mmHg',
                  ),
              ],
            ),
            pw.SizedBox(height: 30),
          ],

          // Readings table
          pw.Text(
            'All Readings',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headers: ['Date', 'Time', 'Systolic', 'Diastolic', 'HR', 'Category', 'Notes'],
            data: readings
                .map((r) => [
                      dateFormat.format(r.timestamp),
                      timeFormat.format(r.timestamp),
                      '${r.systolic}',
                      '${r.diastolic}',
                      '${r.heartRate}',
                      r.category,
                      r.notes ?? '',
                    ])
                .toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
            cellStyle: const pw.TextStyle(fontSize: 10),
            cellAlignment: pw.Alignment.centerLeft,
            columnWidths: {
              0: const pw.FlexColumnWidth(1.5),
              1: const pw.FlexColumnWidth(1),
              2: const pw.FlexColumnWidth(1),
              3: const pw.FlexColumnWidth(1),
              4: const pw.FlexColumnWidth(0.8),
              5: const pw.FlexColumnWidth(1.6),
              6: const pw.FlexColumnWidth(2),
            },
          ),

          pw.SizedBox(height: 30),

          pw.Text(
            disclaimer,
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.TableRow _buildTableRow(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(value),
        ),
      ],
    );
  }
}
