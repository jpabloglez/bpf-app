import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:bp_tracker/models/reading_statistics.dart';
import 'package:bp_tracker/services/pdf_service.dart';

import '../helpers/fake_database_service.dart';

void main() {
  test('builds a PDF document for readings', () async {
    final readings = [
      for (var i = 0; i < 80; i++)
        reading(
          id: i,
          systolic: 110 + i % 60,
          diastolic: 70 + i % 30,
          timestamp: DateTime(2025, 1, 1).add(Duration(hours: i * 12)),
          notes: i.isEven ? 'After walk' : null,
        ),
    ];

    final bytes = await PdfService.buildReport(
      readings,
      ReadingStatistics.fromReadings(readings),
      generatedAt: DateTime(2025, 2, 1),
    );

    expect(ascii.decode(bytes.sublist(0, 5)), '%PDF-');
    expect(bytes.length, greaterThan(2000));
  });

  test('builds a PDF without statistics', () async {
    final bytes = await PdfService.buildReport([reading(id: 1)], null);
    expect(ascii.decode(bytes.sublist(0, 5)), '%PDF-');
  });
}
