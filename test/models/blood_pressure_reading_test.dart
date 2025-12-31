import 'package:flutter_test/flutter_test.dart';
import 'package:bp_tracker/models/blood_pressure_reading.dart';

void main() {
  group('BloodPressureReading', () {
    test('should create valid reading', () {
      final reading = BloodPressureReading(
        systolic: 120,
        diastolic: 80,
        heartRate: 70,
        timestamp: DateTime.now(),
      );

      expect(reading.systolic, 120);
      expect(reading.diastolic, 80);
      expect(reading.heartRate, 70);
    });

    test('should calculate correct category for normal BP', () {
      final reading = BloodPressureReading(
        systolic: 115,
        diastolic: 75,
        heartRate: 70,
        timestamp: DateTime.now(),
      );

      expect(reading.category, 'Normal');
    });

    test('should calculate correct category for elevated BP', () {
      final reading = BloodPressureReading(
        systolic: 125,
        diastolic: 75,
        heartRate: 70,
        timestamp: DateTime.now(),
      );

      expect(reading.category, 'Elevated');
    });

    test('should calculate correct category for high BP Stage 1', () {
      final reading = BloodPressureReading(
        systolic: 135,
        diastolic: 85,
        heartRate: 80,
        timestamp: DateTime.now(),
      );

      expect(reading.category, 'High BP Stage 1');
    });

    test('should calculate correct category for high BP Stage 2', () {
      final reading = BloodPressureReading(
        systolic: 145,
        diastolic: 95,
        heartRate: 80,
        timestamp: DateTime.now(),
      );

      expect(reading.category, 'High BP Stage 2');
    });

    test('should calculate correct category for hypertensive crisis', () {
      final reading = BloodPressureReading(
        systolic: 185,
        diastolic: 125,
        heartRate: 90,
        timestamp: DateTime.now(),
      );

      expect(reading.category, 'Hypertensive Crisis');
    });

    test('should convert to map correctly', () {
      final reading = BloodPressureReading(
        id: 1,
        systolic: 120,
        diastolic: 80,
        heartRate: 70,
        timestamp: DateTime(2025, 1, 15, 10, 30),
        notes: 'Morning reading',
      );

      final map = reading.toMap();

      expect(map['id'], 1);
      expect(map['systolic'], 120);
      expect(map['diastolic'], 80);
      expect(map['heart_rate'], 70);
      expect(map['notes'], 'Morning reading');
    });

    test('should create from map correctly', () {
      final map = {
        'id': 1,
        'systolic': 120,
        'diastolic': 80,
        'heart_rate': 70,
        'timestamp': DateTime(2025, 1, 15).millisecondsSinceEpoch,
        'notes': 'Test note',
      };

      final reading = BloodPressureReading.fromMap(map);

      expect(reading.id, 1);
      expect(reading.systolic, 120);
      expect(reading.diastolic, 80);
      expect(reading.heartRate, 70);
      expect(reading.notes, 'Test note');
    });

    test('should throw error for invalid systolic values', () {
      expect(
        () => BloodPressureReading(
          systolic: 300, // Too high
          diastolic: 80,
          heartRate: 70,
          timestamp: DateTime.now(),
        ),
        throwsArgumentError,
      );
    });

    test('should throw error for invalid diastolic values', () {
      expect(
        () => BloodPressureReading(
          systolic: 120,
          diastolic: 200, // Too high
          heartRate: 70,
          timestamp: DateTime.now(),
        ),
        throwsArgumentError,
      );
    });

    test('should throw error when systolic <= diastolic', () {
      expect(
        () => BloodPressureReading(
          systolic: 80,
          diastolic: 120, // Greater than systolic
          heartRate: 70,
          timestamp: DateTime.now(),
        ),
        throwsArgumentError,
      );
    });

    test('copyWith should create new instance with updated fields', () {
      final original = BloodPressureReading(
        id: 1,
        systolic: 120,
        diastolic: 80,
        heartRate: 70,
        timestamp: DateTime(2025, 1, 15),
        notes: 'Original',
      );

      final updated = original.copyWith(
        systolic: 125,
        notes: 'Updated',
      );

      expect(updated.id, 1);
      expect(updated.systolic, 125); // Changed
      expect(updated.diastolic, 80); // Unchanged
      expect(updated.heartRate, 70); // Unchanged
      expect(updated.notes, 'Updated'); // Changed
    });
  });
}
