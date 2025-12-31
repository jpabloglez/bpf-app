import 'package:flutter/material.dart';

class BloodPressureReading {
  final int? id;
  final int systolic;       // mmHg (90-250 typical range)
  final int diastolic;      // mmHg (60-150 typical range)
  final int heartRate;      // bpm (40-220 typical range)
  final DateTime timestamp; // When measurement was taken
  final String? notes;      // Optional user notes

  BloodPressureReading({
    this.id,
    required this.systolic,
    required this.diastolic,
    required this.heartRate,
    required this.timestamp,
    this.notes,
  }) {
    // Validation
    if (systolic < 50 || systolic > 250) {
      throw ArgumentError('Systolic must be between 50 and 250 mmHg');
    }
    if (diastolic < 30 || diastolic > 150) {
      throw ArgumentError('Diastolic must be between 30 and 150 mmHg');
    }
    if (heartRate < 30 || heartRate > 250) {
      throw ArgumentError('Heart rate must be between 30 and 250 bpm');
    }
    if (systolic <= diastolic) {
      throw ArgumentError('Systolic must be greater than diastolic');
    }
  }

  /// Blood pressure category based on AHA guidelines
  String get category {
    if (systolic < 120 && diastolic < 80) {
      return 'Normal';
    } else if (systolic < 130 && diastolic < 80) {
      return 'Elevated';
    } else if (systolic < 140 || diastolic < 90) {
      return 'High BP Stage 1';
    } else if (systolic < 180 || diastolic < 120) {
      return 'High BP Stage 2';
    } else {
      return 'Hypertensive Crisis';
    }
  }

  /// Color for category indicator
  Color get categoryColor {
    switch (category) {
      case 'Normal':
        return Colors.green;
      case 'Elevated':
        return Colors.yellow[700]!;
      case 'High BP Stage 1':
        return Colors.orange;
      case 'High BP Stage 2':
        return Colors.red;
      case 'Hypertensive Crisis':
        return Colors.red[900]!;
      default:
        return Colors.grey;
    }
  }

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
