import 'blood_pressure_reading.dart';

class ReadingStatistics {
  final double avgSystolic;
  final double avgDiastolic;
  final double avgHeartRate;
  final int totalReadings;
  final BloodPressureReading? latestReading;
  final BloodPressureReading? highestReading;
  final BloodPressureReading? lowestReading;
  final Map<BpCategory, int> categoryDistribution;

  ReadingStatistics({
    required this.avgSystolic,
    required this.avgDiastolic,
    required this.avgHeartRate,
    required this.totalReadings,
    this.latestReading,
    this.highestReading,
    this.lowestReading,
    required this.categoryDistribution,
  });

  /// Category of the average blood pressure.
  BpCategory get averageCategory =>
      BpCategory.classify(avgSystolic.round(), avgDiastolic.round());

  factory ReadingStatistics.fromReadings(List<BloodPressureReading> readings) {
    if (readings.isEmpty) {
      return ReadingStatistics(
        avgSystolic: 0,
        avgDiastolic: 0,
        avgHeartRate: 0,
        totalReadings: 0,
        categoryDistribution: {},
      );
    }

    // Calculate averages
    final totalSystolic = readings.fold<int>(0, (sum, r) => sum + r.systolic);
    final totalDiastolic = readings.fold<int>(0, (sum, r) => sum + r.diastolic);
    final totalHeartRate = readings.fold<int>(0, (sum, r) => sum + r.heartRate);

    // Find latest, highest and lowest (by systolic, then diastolic)
    var latest = readings[0];
    var highest = readings[0];
    var lowest = readings[0];

    int compareBp(BloodPressureReading a, BloodPressureReading b) {
      final bySystolic = a.systolic.compareTo(b.systolic);
      return bySystolic != 0 ? bySystolic : a.diastolic.compareTo(b.diastolic);
    }

    for (final reading in readings) {
      if (reading.timestamp.isAfter(latest.timestamp)) latest = reading;
      if (compareBp(reading, highest) > 0) highest = reading;
      if (compareBp(reading, lowest) < 0) lowest = reading;
    }

    // Category distribution
    final distribution = <BpCategory, int>{};
    for (final reading in readings) {
      distribution.update(reading.bpCategory, (n) => n + 1, ifAbsent: () => 1);
    }

    return ReadingStatistics(
      avgSystolic: totalSystolic / readings.length,
      avgDiastolic: totalDiastolic / readings.length,
      avgHeartRate: totalHeartRate / readings.length,
      totalReadings: readings.length,
      latestReading: latest,
      highestReading: highest,
      lowestReading: lowest,
      categoryDistribution: distribution,
    );
  }
}
