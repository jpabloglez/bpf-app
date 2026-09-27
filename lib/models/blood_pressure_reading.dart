import 'package:flutter/material.dart';

/// Blood pressure categories as defined by the American Heart Association /
/// American College of Cardiology guideline.
enum BpCategory {
  normal('Normal'),
  elevated('Elevated'),
  stage1('High BP Stage 1'),
  stage2('High BP Stage 2'),
  crisis('Hypertensive Crisis');

  const BpCategory(this.label);

  final String label;

  /// Classifies a reading. The highest category matched by either value wins.
  static BpCategory classify(int systolic, int diastolic) {
    if (systolic > 180 || diastolic > 120) return BpCategory.crisis;
    if (systolic >= 140 || diastolic >= 90) return BpCategory.stage2;
    if (systolic >= 130 || diastolic >= 80) return BpCategory.stage1;
    if (systolic >= 120) return BpCategory.elevated;
    return BpCategory.normal;
  }

  /// Indicator color; tuned to stay legible on light and dark surfaces.
  Color colorFor(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    switch (this) {
      case BpCategory.normal:
        return dark ? const Color(0xFF81C784) : const Color(0xFF2E7D32);
      case BpCategory.elevated:
        return dark ? const Color(0xFFFFD54F) : const Color(0xFF8D6E00);
      case BpCategory.stage1:
        return dark ? const Color(0xFFFFB74D) : const Color(0xFFE65100);
      case BpCategory.stage2:
        return dark ? const Color(0xFFE57373) : const Color(0xFFC62828);
      case BpCategory.crisis:
        return dark ? const Color(0xFFFF8A80) : const Color(0xFF8E0000);
    }
  }
}

class BloodPressureReading {
  static const int minSystolic = 50;
  static const int maxSystolic = 250;
  static const int minDiastolic = 30;
  static const int maxDiastolic = 150;
  static const int minHeartRate = 30;
  static const int maxHeartRate = 250;
  static const int maxNotesLength = 500;

  final int? id;
  final int systolic; // mmHg
  final int diastolic; // mmHg
  final int heartRate; // bpm
  final DateTime timestamp; // When measurement was taken
  final String? notes; // Optional user notes

  BloodPressureReading({
    this.id,
    required this.systolic,
    required this.diastolic,
    required this.heartRate,
    required this.timestamp,
    this.notes,
  }) {
    if (systolic < minSystolic || systolic > maxSystolic) {
      throw ArgumentError(
          'Systolic must be between $minSystolic and $maxSystolic mmHg');
    }
    if (diastolic < minDiastolic || diastolic > maxDiastolic) {
      throw ArgumentError(
          'Diastolic must be between $minDiastolic and $maxDiastolic mmHg');
    }
    if (heartRate < minHeartRate || heartRate > maxHeartRate) {
      throw ArgumentError(
          'Heart rate must be between $minHeartRate and $maxHeartRate bpm');
    }
    if (systolic <= diastolic) {
      throw ArgumentError('Systolic must be greater than diastolic');
    }
    if (notes != null && notes!.length > maxNotesLength) {
      throw ArgumentError('Notes must be at most $maxNotesLength characters');
    }
  }

  BpCategory get bpCategory => BpCategory.classify(systolic, diastolic);

  /// Human-readable category label.
  String get category => bpCategory.label;

  /// Convert to Map for SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'systolic': systolic,
      'diastolic': diastolic,
      'heart_rate': heartRate,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'notes': notes,
    };
  }

  /// Create from Map (SQLite result)
  factory BloodPressureReading.fromMap(Map<String, dynamic> map) {
    return BloodPressureReading(
      id: map['id'] as int?,
      systolic: map['systolic'] as int,
      diastolic: map['diastolic'] as int,
      heartRate: map['heart_rate'] as int,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      notes: map['notes'] as String?,
    );
  }

  /// Create copy with modified fields
  BloodPressureReading copyWith({
    int? id,
    int? systolic,
    int? diastolic,
    int? heartRate,
    DateTime? timestamp,
    String? notes,
  }) {
    return BloodPressureReading(
      id: id ?? this.id,
      systolic: systolic ?? this.systolic,
      diastolic: diastolic ?? this.diastolic,
      heartRate: heartRate ?? this.heartRate,
      timestamp: timestamp ?? this.timestamp,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() {
    return 'BloodPressureReading(id: $id, BP: $systolic/$diastolic, HR: $heartRate, time: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BloodPressureReading &&
        other.id == id &&
        other.systolic == systolic &&
        other.diastolic == diastolic &&
        other.heartRate == heartRate &&
        other.timestamp == timestamp &&
        other.notes == notes;
  }

  @override
  int get hashCode {
    return Object.hash(id, systolic, diastolic, heartRate, timestamp, notes);
  }
}
