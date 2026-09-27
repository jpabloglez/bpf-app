import 'package:bp_tracker/models/blood_pressure_reading.dart';
import 'package:bp_tracker/services/database_service.dart';
import 'package:sqflite/sqflite.dart';

/// In-memory stand-in for [DatabaseService].
class FakeDatabaseService implements DatabaseService {
  FakeDatabaseService([List<BloodPressureReading> initial = const []]) {
    for (final r in initial) {
      _rows[r.id ?? _nextId] = r.id == null ? r.copyWith(id: _nextId) : r;
      _nextId = _rows.keys.fold(0, (a, b) => a > b ? a : b) + 1;
    }
  }

  final Map<int, BloodPressureReading> _rows = {};
  int _nextId = 1;
  bool failNextLoad = false;

  @override
  Future<Database> get database => throw UnimplementedError();

  List<BloodPressureReading> _sorted(Iterable<BloodPressureReading> rows) =>
      rows.toList()..sort((a, b) => b.timestamp.compareTo(a.timestamp));

  @override
  Future<int> insertReading(BloodPressureReading reading) async {
    final id = reading.id ?? _nextId;
    if (_rows.containsKey(id)) throw StateError('duplicate id $id');
    _rows[id] = reading.copyWith(id: id);
    if (id >= _nextId) _nextId = id + 1;
    return id;
  }

  @override
  Future<List<BloodPressureReading>> getAllReadings() async {
    if (failNextLoad) {
      failNextLoad = false;
      throw StateError('disk error');
    }
    return _sorted(_rows.values);
  }

  @override
  Future<List<BloodPressureReading>> getReadingsByDateRange(
      DateTime start, DateTime end) async {
    return _sorted(_rows.values.where(
        (r) => !r.timestamp.isBefore(start) && !r.timestamp.isAfter(end)));
  }

  @override
  Future<BloodPressureReading?> getReadingById(int id) async => _rows[id];

  @override
  Future<int> updateReading(BloodPressureReading reading) async {
    if (!_rows.containsKey(reading.id)) return 0;
    _rows[reading.id!] = reading;
    return 1;
  }

  @override
  Future<int> deleteReading(int id) async => _rows.remove(id) == null ? 0 : 1;

  @override
  Future<int> deleteAllReadings() async {
    final n = _rows.length;
    _rows.clear();
    return n;
  }

  @override
  Future<int> getReadingCount() async => _rows.length;

  @override
  Future<void> close() async {}
}

BloodPressureReading reading({
  int? id,
  int systolic = 120,
  int diastolic = 80,
  int heartRate = 70,
  DateTime? timestamp,
  String? notes,
}) {
  return BloodPressureReading(
    id: id,
    systolic: systolic,
    diastolic: diastolic,
    heartRate: heartRate,
    timestamp: timestamp ?? DateTime.now(),
    notes: notes,
  );
}
