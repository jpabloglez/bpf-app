import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bp_tracker/models/blood_pressure_reading.dart';

void main() {
  BloodPressureReading make(int systolic, int diastolic,
          {int heartRate = 70, String? notes}) =>
      BloodPressureReading(
        systolic: systolic,
        diastolic: diastolic,
        heartRate: heartRate,
        timestamp: DateTime(2025, 1, 15),
        notes: notes,
      );

  group('BpCategory.classify', () {
    // (systolic, diastolic, expected)
    const cases = [
      (115, 75, BpCategory.normal),
      (119, 79, BpCategory.normal),
      (120, 79, BpCategory.elevated),
      (129, 70, BpCategory.elevated),
      (125, 80, BpCategory.stage1), // diastolic alone raises the category
      (130, 70, BpCategory.stage1),
      (139, 89, BpCategory.stage1),
      (135, 85, BpCategory.stage1),
      (140, 70, BpCategory.stage2),
      (150, 70, BpCategory.stage2), // isolated systolic hypertension
      (118, 92, BpCategory.stage2), // isolated diastolic hypertension
      (145, 95, BpCategory.stage2),
      (180, 120, BpCategory.stage2), // boundary: crisis is strictly above
      (181, 100, BpCategory.crisis),
      (200, 85, BpCategory.crisis),
      (170, 121, BpCategory.crisis),
      (185, 125, BpCategory.crisis),
    ];

    for (final (s, d, expected) in cases) {
      test('$s/$d is ${expected.label}', () {
        expect(BpCategory.classify(s, d), expected);
        expect(make(s, d).bpCategory, expected);
        expect(make(s, d).category, expected.label);
      });
    }
  });

  group('BpCategory colors', () {
    test('differ between light and dark themes', () {
      for (final c in BpCategory.values) {
        expect(c.colorFor(Brightness.light),
            isNot(c.colorFor(Brightness.dark)));
      }
    });
  });

  group('BloodPressureReading', () {
    test('should create valid reading', () {
      final reading = make(120, 80);
      expect(reading.systolic, 120);
      expect(reading.diastolic, 80);
      expect(reading.heartRate, 70);
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
      expect(map['timestamp'],
          DateTime(2025, 1, 15, 10, 30).millisecondsSinceEpoch);
      expect(map['notes'], 'Morning reading');
    });

    test('round-trips through a map', () {
      final original = BloodPressureReading(
        id: 7,
        systolic: 131,
        diastolic: 84,
        heartRate: 66,
        timestamp: DateTime(2025, 3, 2, 7, 45),
        notes: 'Café ☕',
      );
      expect(BloodPressureReading.fromMap(original.toMap()), original);
    });

    test('accepts inclusive range limits', () {
      expect(() => make(250, 150, heartRate: 250), returnsNormally);
      expect(() => make(50, 30, heartRate: 30), returnsNormally);
    });

    const invalid = {
      'systolic too high': (251, 80, 70),
      'systolic too low': (49, 30, 70),
      'diastolic too high': (240, 151, 70),
      'diastolic too low': (120, 29, 70),
      'heart rate too high': (120, 80, 251),
      'heart rate too low': (120, 80, 29),
      'systolic equal to diastolic': (100, 100, 70),
      'systolic below diastolic': (80, 120, 70),
    };
    invalid.forEach((name, v) {
      test('throws when $name', () {
        expect(() => make(v.$1, v.$2, heartRate: v.$3), throwsArgumentError);
      });
    });

    test('limits notes length', () {
      final max = BloodPressureReading.maxNotesLength;
      expect(() => make(120, 80, notes: 'a' * max), returnsNormally);
      expect(() => make(120, 80, notes: 'a' * (max + 1)), throwsArgumentError);
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

      final updated = original.copyWith(systolic: 125, notes: 'Updated');

      expect(updated.id, 1);
      expect(updated.systolic, 125);
      expect(updated.diastolic, 80);
      expect(updated.heartRate, 70);
      expect(updated.notes, 'Updated');
      expect(updated, isNot(original));
    });

    test('copyWith still validates', () {
      expect(() => make(120, 80).copyWith(diastolic: 130), throwsArgumentError);
    });
  });
}
