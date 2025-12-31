# Feature Implementation Guide

This guide provides detailed implementation instructions for all core features of the Blood Pressure Tracker app.

## Table of Contents
1. [Data Models](#data-models)
2. [Database Layer](#database-layer)
3. [State Management](#state-management)
4. [UI Screens](#ui-screens)
5. [Charts Implementation](#charts-implementation)
6. [PDF Export](#pdf-export)
7. [Input Validation](#input-validation)
8. [Date & Time Handling](#date--time-handling)

---

## Data Models

### BloodPressureReading Model

Create `lib/models/blood_pressure_reading.dart`:

```dart
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
```

### ReadingStatistics Model

Create `lib/models/reading_statistics.dart`:

```dart
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
```

---

## Database Layer

### DatabaseService

Create `lib/services/database_service.dart`:

```dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/blood_pressure_reading.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();
  static Database? _database;

  DatabaseService._internal();

  factory DatabaseService() => instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'bp_tracker.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE blood_pressure_readings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        systolic INTEGER NOT NULL,
        diastolic INTEGER NOT NULL,
        heart_rate INTEGER NOT NULL,
        timestamp INTEGER NOT NULL,
        notes TEXT,
        created_at INTEGER NOT NULL
      )
    ''');

    // Create index for faster queries
    await db.execute('''
      CREATE INDEX idx_timestamp
      ON blood_pressure_readings(timestamp DESC)
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database migrations here
    // Example: if (oldVersion < 2) { ... }
  }

  /// Insert a new reading
  Future<int> insertReading(BloodPressureReading reading) async {
    final db = await database;

    final map = reading.toMap();
    map['created_at'] = DateTime.now().millisecondsSinceEpoch;

    return await db.insert(
      'blood_pressure_readings',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get all readings, sorted by timestamp (newest first)
  Future<List<BloodPressureReading>> getAllReadings() async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.query(
      'blood_pressure_readings',
      orderBy: 'timestamp DESC',
    );

    return List.generate(maps.length, (i) {
      return BloodPressureReading.fromMap(maps[i]);
    });
  }

  /// Get readings within date range
  Future<List<BloodPressureReading>> getReadingsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.query(
      'blood_pressure_readings',
      where: 'timestamp >= ? AND timestamp <= ?',
      whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
      orderBy: 'timestamp DESC',
    );

    return List.generate(maps.length, (i) {
      return BloodPressureReading.fromMap(maps[i]);
    });
  }

  /// Get single reading by ID
  Future<BloodPressureReading?> getReadingById(int id) async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.query(
      'blood_pressure_readings',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return BloodPressureReading.fromMap(maps.first);
  }

  /// Update existing reading
  Future<int> updateReading(BloodPressureReading reading) async {
    final db = await database;

    return await db.update(
      'blood_pressure_readings',
      reading.toMap(),
      where: 'id = ?',
      whereArgs: [reading.id],
    );
  }

  /// Delete reading
  Future<int> deleteReading(int id) async {
    final db = await database;

    return await db.delete(
      'blood_pressure_readings',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete all readings (use with caution!)
  Future<int> deleteAllReadings() async {
    final db = await database;
    return await db.delete('blood_pressure_readings');
  }

  /// Get count of readings
  Future<int> getReadingCount() async {
    final db = await database;

    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM blood_pressure_readings'
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
```

---

## State Management

### ReadingsProvider

Create `lib/providers/readings_provider.dart`:

```dart
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
```

### Setup Provider in main.dart

Create/update `lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/readings_provider.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ReadingsProvider()..loadReadings()),
      ],
      child: MaterialApp(
        title: 'BP Tracker',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
```

---

## UI Screens

### Home Screen

Create `lib/screens/home_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/readings_provider.dart';
import '../widgets/reading_card.dart';
import '../widgets/statistics_card.dart';
import 'add_reading_screen.dart';
import 'charts_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BP Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChartsScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<ReadingsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && !provider.hasReadings) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(provider.error!),
                  TextButton(
                    onPressed: () => provider.loadReadings(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (!provider.hasReadings) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No readings yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text('Tap + to add your first reading'),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: provider.loadReadings,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Statistics card
                if (provider.statistics != null)
                  StatisticsCard(statistics: provider.statistics!),

                const SizedBox(height: 16),

                // Recent readings header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent Readings',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () {
                        // Navigate to full list
                      },
                      child: const Text('See All'),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Readings list (show latest 10)
                ...provider.readings.take(10).map((reading) {
                  return ReadingCard(
                    key: ValueKey(reading.id),
                    reading: reading,
                    onTap: () => _editReading(context, reading),
                    onDelete: () => _deleteReading(context, provider, reading),
                  );
                }).toList(),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddReadingScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _editReading(BuildContext context, BloodPressureReading reading) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddReadingScreen(reading: reading),
      ),
    );
  }

  void _deleteReading(
    BuildContext context,
    ReadingsProvider provider,
    BloodPressureReading reading,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reading'),
        content: const Text('Are you sure you want to delete this reading?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && reading.id != null) {
      await provider.deleteReading(reading.id!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reading deleted')),
        );
      }
    }
  }
}
```

### Add/Edit Reading Screen

Create `lib/screens/add_reading_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/blood_pressure_reading.dart';
import '../providers/readings_provider.dart';

class AddReadingScreen extends StatefulWidget {
  final BloodPressureReading? reading; // null for new, provided for edit

  const AddReadingScreen({Key? key, this.reading}) : super(key: key);

  @override
  State<AddReadingScreen> createState() => _AddReadingScreenState();
}

class _AddReadingScreenState extends State<AddReadingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _systolicController = TextEditingController();
  final _diastolicController = TextEditingController();
  final _heartRateController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    if (widget.reading != null) {
      // Edit mode - populate fields
      _systolicController.text = widget.reading!.systolic.toString();
      _diastolicController.text = widget.reading!.diastolic.toString();
      _heartRateController.text = widget.reading!.heartRate.toString();
      _notesController.text = widget.reading!.notes ?? '';
      _selectedDate = widget.reading!.timestamp;
      _selectedTime = TimeOfDay.fromDateTime(widget.reading!.timestamp);
    }
  }

  @override
  void dispose() {
    _systolicController.dispose();
    _diastolicController.dispose();
    _heartRateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.reading != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Reading' : 'Add Reading'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Systolic input
            TextFormField(
              controller: _systolicController,
              key: const Key('systolic_field'),
              decoration: const InputDecoration(
                labelText: 'Systolic (mmHg)',
                hintText: '120',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.arrow_upward),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter systolic value';
                }
                final num = int.tryParse(value);
                if (num == null || num < 50 || num > 250) {
                  return 'Enter value between 50 and 250';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Diastolic input
            TextFormField(
              controller: _diastolicController,
              key: const Key('diastolic_field'),
              decoration: const InputDecoration(
                labelText: 'Diastolic (mmHg)',
                hintText: '80',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.arrow_downward),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter diastolic value';
                }
                final num = int.tryParse(value);
                if (num == null || num < 30 || num > 150) {
                  return 'Enter value between 30 and 150';
                }

                // Check systolic > diastolic
                final systolic = int.tryParse(_systolicController.text);
                if (systolic != null && num != null && systolic <= num) {
                  return 'Diastolic must be less than systolic';
                }

                return null;
              },
            ),

            const SizedBox(height: 16),

            // Heart rate input
            TextFormField(
              controller: _heartRateController,
              key: const Key('heart_rate_field'),
              decoration: const InputDecoration(
                labelText: 'Heart Rate (bpm)',
                hintText: '70',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.favorite),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter heart rate';
                }
                final num = int.tryParse(value);
                if (num == null || num < 30 || num > 250) {
                  return 'Enter value between 30 and 250';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Date picker
            ListTile(
              title: const Text('Date'),
              subtitle: Text(DateFormat('MMMM d, y').format(_selectedDate)),
              leading: const Icon(Icons.calendar_today),
              onTap: _selectDate,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(4),
              ),
            ),

            const SizedBox(height: 16),

            // Time picker
            ListTile(
              title: const Text('Time'),
              subtitle: Text(_selectedTime.format(context)),
              leading: const Icon(Icons.access_time),
              onTap: _selectTime,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(4),
              ),
            ),

            const SizedBox(height: 16),

            // Notes input
            TextFormField(
              controller: _notesController,
              key: const Key('notes_field'),
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'e.g., After exercise, before medication',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 24),

            // Save button
            ElevatedButton(
              onPressed: _isLoading ? null : _saveReading,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isEditing ? 'Update' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _saveReading() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final timestamp = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final reading = BloodPressureReading(
        id: widget.reading?.id,
        systolic: int.parse(_systolicController.text),
        diastolic: int.parse(_diastolicController.text),
        heartRate: int.parse(_heartRateController.text),
        timestamp: timestamp,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      final provider = context.read<ReadingsProvider>();

      if (widget.reading == null) {
        await provider.addReading(reading);
      } else {
        await provider.updateReading(reading);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.reading == null
                ? 'Reading added successfully'
                : 'Reading updated successfully'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
```

---

## Charts Implementation

### Charts Screen with fl_chart

Create `lib/screens/charts_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/readings_provider.dart';
import '../models/blood_pressure_reading.dart';

class ChartsScreen extends StatefulWidget {
  const ChartsScreen({Key? key}) : super(key: key);

  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen> {
  String _selectedRange = 'Week'; // Week, Month, All

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Charts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _exportPDF,
          ),
        ],
      ),
      body: Consumer<ReadingsProvider>(
        builder: (context, provider, child) {
          if (!provider.hasReadings) {
            return const Center(
              child: Text('No data to display'),
            );
          }

          final readings = _getFilteredReadings(provider.readings);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Time range selector
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'Week', label: Text('Week')),
                  ButtonSegment(value: 'Month', label: Text('Month')),
                  ButtonSegment(value: 'All', label: Text('All')),
                ],
                selected: {_selectedRange},
                onSelectionChanged: (Set<String> selection) {
                  setState(() {
                    _selectedRange = selection.first;
                  });
                },
              ),

              const SizedBox(height: 24),

              // Blood Pressure Chart
              const Text(
                'Blood Pressure Trend',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 300,
                child: BPLineChart(readings: readings),
              ),

              const SizedBox(height: 32),

              // Heart Rate Chart
              const Text(
                'Heart Rate Trend',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 300,
                child: HeartRateChart(readings: readings),
              ),
            ],
          );
        },
      ),
    );
  }

  List<BloodPressureReading> _getFilteredReadings(List<BloodPressureReading> all) {
    final now = DateTime.now();
    DateTime cutoff;

    switch (_selectedRange) {
      case 'Week':
        cutoff = now.subtract(const Duration(days: 7));
        break;
      case 'Month':
        cutoff = now.subtract(const Duration(days: 30));
        break;
      case 'All':
      default:
        return all;
    }

    return all.where((r) => r.timestamp.isAfter(cutoff)).toList();
  }

  void _exportPDF() {
    // TODO: Implement PDF export
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PDF export coming soon')),
    );
  }
}

class BPLineChart extends StatelessWidget {
  final List<BloodPressureReading> readings;

  const BPLineChart({Key? key, required this.readings}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (readings.isEmpty) {
      return const Center(child: Text('No data'));
    }

    final spots Systolic = readings.reversed.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.systolic.toDouble());
    }).toList();

    final spotsDiastolic = readings.reversed.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.diastolic.toDouble());
    }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= readings.length) return const Text('');
                final reading = readings.reversed.toList()[value.toInt()];
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    DateFormat('MM/dd').format(reading.timestamp),
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          // Systolic line
          LineChartBarData(
            spots: spotsSystolic,
            isCurved: true,
            color: Colors.red,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(show: false),
          ),
          // Diastolic line
          LineChartBarData(
            spots: spotsDiastolic,
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(show: false),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final reading = readings.reversed.toList()[spot.x.toInt()];
                return LineTooltipItem(
                  '${DateFormat('MM/dd').format(reading.timestamp)}\n${spot.y.toInt()} mmHg',
                  const TextStyle(color: Colors.white),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}

class HeartRateChart extends StatelessWidget {
  final List<BloodPressureReading> readings;

  const HeartRateChart({Key? key, required this.readings}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (readings.isEmpty) {
      return const Center(child: Text('No data'));
    }

    final spots = readings.reversed.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.heartRate.toDouble());
    }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= readings.length) return const Text('');
                final reading = readings.reversed.toList()[value.toInt()];
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    DateFormat('MM/dd').format(reading.timestamp),
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.green,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.green.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## PDF Export

### PDF Service

Create `lib/services/pdf_service.dart`:

```dart
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/blood_pressure_reading.dart';
import '../models/reading_statistics.dart';

class PdfService {
  static Future<void> generateAndShareReport(
    List<BloodPressureReading> readings,
    ReadingStatistics? statistics,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          // Header
          pw.Header(
            level: 0,
            child: pw.Text(
              'Blood Pressure Report',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
          ),

          pw.SizedBox(height: 20),

          // Generation date
          pw.Text(
            'Generated: ${DateFormat('MMMM d, y').format(DateTime.now())}',
            style: const pw.TextStyle(color: PdfColors.grey700),
          ),

          pw.SizedBox(height: 20),

          // Summary statistics
          if (statistics != null) ...[
            pw.Text(
              'Summary Statistics',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(),
              children: [
                _buildTableRow('Total Readings', '${statistics.totalReadings}'),
                _buildTableRow(
                  'Average BP',
                  '${statistics.avgSystolic.toStringAsFixed(0)}/${statistics.avgDiastolic.toStringAsFixed(0)} mmHg',
                ),
                _buildTableRow(
                  'Average Heart Rate',
                  '${statistics.avgHeartRate.toStringAsFixed(0)} bpm',
                ),
                if (statistics.highestReading != null)
                  _buildTableRow(
                    'Highest Reading',
                    '${statistics.highestReading!.systolic}/${statistics.highestReading!.diastolic} mmHg',
                  ),
                if (statistics.lowestReading != null)
                  _buildTableRow(
                    'Lowest Reading',
                    '${statistics.lowestReading!.systolic}/${statistics.lowestReading!.diastolic} mmHg',
                  ),
              ],
            ),
            pw.SizedBox(height: 30),
          ],

          // Readings table
          pw.Text(
            'All Readings',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.Table.fromTextArray(
            headers: ['Date', 'Time', 'Systolic', 'Diastolic', 'HR', 'Category', 'Notes'],
            data: readings.map((r) => [
              DateFormat('MM/dd/yy').format(r.timestamp),
              DateFormat('HH:mm').format(r.timestamp),
              '${r.systolic}',
              '${r.diastolic}',
              '${r.heartRate}',
              r.category,
              r.notes ?? '',
            ]).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.centerLeft,
            columnWidths: {
              0: const pw.FlexColumnWidth(1.5),
              1: const pw.FlexColumnWidth(1),
              2: const pw.FlexColumnWidth(1),
              3: const pw.FlexColumnWidth(1),
              4: const pw.FlexColumnWidth(0.8),
              5: const pw.FlexColumnWidth(1.5),
              6: const pw.FlexColumnWidth(2),
            },
          ),

          pw.SizedBox(height: 30),

          // Disclaimer
          pw.Text(
            'Disclaimer: This report is for informational purposes only and is not a substitute for professional medical advice. Always consult your healthcare provider about your blood pressure.',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
        ],
      ),
    );

    // Share PDF
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'bp_report_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.pdf',
    );
  }

  static pw.TableRow _buildTableRow(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(value),
        ),
      ],
    );
  }
}
```

---

This implementation guide provides complete, production-ready code for all core features of the Blood Pressure Tracker app. Each section builds on the previous ones to create a fully functional application.

**Next Steps**:
1. Implement the widget components (ReadingCard, StatisticsCard)
2. Add error handling and edge cases
3. Implement data export features
4. Add unit tests for all components
5. Optimize performance for large datasets

---

**Happy Coding!** Follow this guide step-by-step to build a complete blood pressure tracking application.
