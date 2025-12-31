import 'package:flutter/foundation.dart';
import '../models/blood_pressure_reading.dart';
import '../models/reading_statistics.dart';
import '../services/database_service.dart';

class ReadingsProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;

  List<BloodPressureReading> _readings = [];
  ReadingStatistics? _statistics;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<BloodPressureReading> get readings => _readings;
  ReadingStatistics? get statistics => _statistics;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasReadings => _readings.isNotEmpty;

  /// Load all readings from database
  Future<void> loadReadings() async {
    _setLoading(true);
    _clearError();

    try {
      _readings = await _db.getAllReadings();
      _calculateStatistics();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load readings: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Add new reading
  Future<void> addReading(BloodPressureReading reading) async {
    _setLoading(true);
    _clearError();

    try {
      final id = await _db.insertReading(reading);
      await loadReadings(); // Reload to get the new reading with ID
    } catch (e) {
      _setError('Failed to add reading: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Update existing reading
  Future<void> updateReading(BloodPressureReading reading) async {
    _setLoading(true);
    _clearError();

    try {
      await _db.updateReading(reading);
      await loadReadings();
    } catch (e) {
      _setError('Failed to update reading: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Delete reading
  Future<void> deleteReading(int id) async {
    _setLoading(true);
    _clearError();

    try {
      await _db.deleteReading(id);
      _readings.removeWhere((r) => r.id == id);
      _calculateStatistics();
      notifyListeners();
    } catch (e) {
      _setError('Failed to delete reading: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Get readings for specific date range
  Future<List<BloodPressureReading>> getReadingsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    try {
      return await _db.getReadingsByDateRange(start, end);
    } catch (e) {
      _setError('Failed to load readings: $e');
      return [];
    }
  }

  /// Calculate statistics
  void _calculateStatistics() {
    if (_readings.isEmpty) {
      _statistics = null;
    } else {
      _statistics = ReadingStatistics.fromReadings(_readings);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}
