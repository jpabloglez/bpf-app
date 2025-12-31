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
