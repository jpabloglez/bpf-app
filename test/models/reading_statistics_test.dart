import 'package:flutter_test/flutter_test.dart';
import 'package:bp_tracker/models/blood_pressure_reading.dart';
import 'package:bp_tracker/models/reading_statistics.dart';

import '../helpers/fake_database_service.dart';

void main() {
  test('empty list gives zeroed statistics', () {
    final stats = ReadingStatistics.fromReadings([]);
    expect(stats.totalReadings, 0);
    expect(stats.avgSystolic, 0);
    expect(stats.latestReading, isNull);
    expect(stats.highestReading, isNull);
    expect(stats.categoryDistribution, isEmpty);
  });

  test('computes averages, extremes, latest and distribution', () {
    final a = reading(
        id: 1, systolic: 118, diastolic: 76, heartRate: 60,
        timestamp: DateTime(2025, 1, 1));
    final b = reading(
        id: 2, systolic: 142, diastolic: 92, heartRate: 80,
        timestamp: DateTime(2025, 1, 3));
    final c = reading(
        id: 3, systolic: 142, diastolic: 95, heartRate: 70,
        timestamp: DateTime(2025, 1, 2));

    final stats = ReadingStatistics.fromReadings([a, b, c]);

    expect(stats.totalReadings, 3);
    expect(stats.avgSystolic, closeTo(134, 0.001));
    expect(stats.avgDiastolic, closeTo(87.667, 0.001));
    expect(stats.avgHeartRate, closeTo(70, 0.001));
    expect(stats.latestReading, b);
    expect(stats.highestReading, c, reason: 'ties broken by diastolic');
    expect(stats.lowestReading, a);
    expect(stats.categoryDistribution, {
      BpCategory.normal: 1,
      BpCategory.stage2: 2,
    });
    expect(stats.averageCategory, BpCategory.stage1);
  });
}
