import 'package:flutter/foundation.dart';
import '../models/blood_pressure_reading.dart';
import '../models/reading_statistics.dart';
import '../services/database_service.dart';

class ReadingsProvider extends ChangeNotifier {
  ReadingsProvider({DatabaseService? database})
      : _db = database ?? DatabaseService.instance;

  final DatabaseService _db;

  List<BloodPressureReading> _readings = const [];
  ReadingStatistics? _statistics;
  bool _isLoading = false;
  bool _hasLoaded = false;
  String? _error;

  // Getters
  List<BloodPressureReading> get readings => _readings;
  ReadingStatistics? get statistics => _statistics;
  bool get isLoading => _isLoading;

  /// True once the first load has completed (successfully or not).
  bool get hasLoaded => _hasLoaded;
  String? get error => _error;
  bool get hasReadings => _readings.isNotEmpty;

  /// Load all readings from database
  Future<void> loadReadings() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _setReadings(await _db.getAllReadings());
    } catch (e) {
      debugPrint('Failed to load readings: $e');
      _error = 'Could not load your readings.';
    } finally {
      _isLoading = false;
      _hasLoaded = true;
      notifyListeners();
    }
  }

  /// Add new reading. Throws if it cannot be saved.
  Future<void> addReading(BloodPressureReading reading) async {
    await _db.insertReading(reading);
    await loadReadings(); // Reload to get the new reading with ID
  }

  /// Update existing reading. Throws if it cannot be saved.
  Future<void> updateReading(BloodPressureReading reading) async {
    await _db.updateReading(reading);
    await loadReadings();
  }

  /// Delete reading. Removed from the list immediately (a dismissed list
  /// item must disappear synchronously); restored and rethrown on failure.
  Future<void> deleteReading(int id) async {
    final previous = _readings;
    _setReadings(previous.where((r) => r.id != id).toList());
    notifyListeners();

    try {
      await _db.deleteReading(id);
    } catch (_) {
      _setReadings(previous);
      notifyListeners();
      rethrow;
    }
  }

  /// Get readings for specific date range
  Future<List<BloodPressureReading>> getReadingsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    return _db.getReadingsByDateRange(start, end);
  }

  void _setReadings(List<BloodPressureReading> readings) {
    _readings = List.unmodifiable(readings);
    _statistics =
        readings.isEmpty ? null : ReadingStatistics.fromReadings(readings);
  }
}
