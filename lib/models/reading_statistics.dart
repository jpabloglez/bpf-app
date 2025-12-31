import 'blood_pressure_reading.dart';

class ReadingStatistics {
  final double avgSystolic;
  final double avgDiastolic;
  final double avgHeartRate;
  final int totalReadings;
  final BloodPressureReading? highestReading;
  final BloodPressureReading? lowestReading;
  final Map<String, int> categoryDistribution;

  ReadingStatistics({
    required this.avgSystolic,
    required this.avgDiastolic,
    required this.avgHeartRate,
    required this.totalReadings,
    this.highestReading,
    this.lowestReading,
    required this.categoryDistribution,
  });

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

    // Find highest and lowest
    BloodPressureReading highest = readings[0];
    BloodPressureReading lowest = readings[0];

    for (var reading in readings) {
      if (reading.systolic > highest.systolic) highest = reading;
      if (reading.systolic < lowest.systolic) lowest = reading;
    }

    // Category distribution
    final Map<String, int> distribution = {};
    for (var reading in readings) {
      distribution[reading.category] = (distribution[reading.category] ?? 0) + 1;
    }

    return ReadingStatistics(
      avgSystolic: totalSystolic / readings.length,
      avgDiastolic: totalDiastolic / readings.length,
      avgHeartRate: totalHeartRate / readings.length,
      totalReadings: readings.length,
      highestReading: highest,
      lowestReading: lowest,
      categoryDistribution: distribution,
    );
  }
}
