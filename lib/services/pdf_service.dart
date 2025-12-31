import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/blood_pressure_reading.dart';
import '../models/reading_statistics.dart';

class PdfService {
  static Future<void> generateAndShareReport(
    List<BloodPressureReading> readings,
    ReadingStatistics? statistics,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          // Header
          pw.Header(
            level: 0,
            child: pw.Text(
              'Blood Pressure Report',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
          ),

          pw.SizedBox(height: 20),

          // Generation date
          pw.Text(
            'Generated: ${DateFormat('MMMM d, y').format(DateTime.now())}',
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
              border: pw.TableBorder.all(),
              children: [
                _buildTableRow('Total Readings', '${statistics.totalReadings}'),
                _buildTableRow(
                  'Average BP',
                  '${statistics.avgSystolic.toStringAsFixed(0)}/${statistics.avgDiastolic.toStringAsFixed(0)} mmHg',
                ),
                _buildTableRow(
                  'Average Heart Rate',
                  '${statistics.avgHeartRate.toStringAsFixed(0)} bpm',
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
          pw.Table.fromTextArray(
            headers: ['Date', 'Time', 'Systolic', 'Diastolic', 'HR', 'Category', 'Notes'],
            data: readings.map((r) => [
              DateFormat('MM/dd/yy').format(r.timestamp),
              DateFormat('HH:mm').format(r.timestamp),
              '${r.systolic}',
              '${r.diastolic}',
              '${r.heartRate}',
              r.category,
              r.notes ?? '',
            ]).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.centerLeft,
            columnWidths: {
              0: const pw.FlexColumnWidth(1.5),
              1: const pw.FlexColumnWidth(1),
              2: const pw.FlexColumnWidth(1),
              3: const pw.FlexColumnWidth(1),
              4: const pw.FlexColumnWidth(0.8),
              5: const pw.FlexColumnWidth(1.5),
              6: const pw.FlexColumnWidth(2),
            },
          ),

          pw.SizedBox(height: 30),

          // Disclaimer
          pw.Text(
            'Disclaimer: This report is for informational purposes only and is not a substitute for professional medical advice. Always consult your healthcare provider about your blood pressure.',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
        ],
      ),
    );

    // Share PDF
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'bp_report_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.pdf',
    );
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
