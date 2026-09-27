import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/blood_pressure_reading.dart';

class DatabaseService {
  static const String _table = 'blood_pressure_readings';
  static const String _fileName = 'bp_tracker.db';

  static final DatabaseService instance = DatabaseService._internal();

  final DatabaseFactory? _factory;
  final String? _path;
  Future<Database>? _database;

  DatabaseService._internal()
      : _factory = null,
        _path = null;

  factory DatabaseService() => instance;

  /// Creates a service backed by a custom [factory] and [path], e.g. an
  /// in-memory FFI database in tests.
  DatabaseService.withFactory(DatabaseFactory factory, String path)
      : _factory = factory,
        _path = path;

  /// Opens the database once; concurrent callers share the same future.
  Future<Database> get database => _database ??= _initDatabase();

  Future<Database> _initDatabase() async {
    final options = OpenDatabaseOptions(
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );

    if (_factory != null) {
      return _factory.openDatabase(_path!, options: options);
    }

    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _fileName);
    return databaseFactory.openDatabase(path, options: options);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_table (
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
      ON $_table(timestamp DESC)
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database migrations here
    // Example: if (oldVersion < 2) { ... }
  }

  /// Insert a new reading and return its id.
  Future<int> insertReading(BloodPressureReading reading) async {
    final db = await database;

    final map = reading.toMap();
    map['created_at'] = DateTime.now().millisecondsSinceEpoch;

    return db.insert(_table, map);
  }

  /// Get all readings, sorted by timestamp (newest first)
  Future<List<BloodPressureReading>> getAllReadings() async {
    final db = await database;
    final maps = await db.query(_table, orderBy: 'timestamp DESC');
    return maps.map(BloodPressureReading.fromMap).toList();
  }

  /// Get readings within date range
  Future<List<BloodPressureReading>> getReadingsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await database;

    final maps = await db.query(
      _table,
      where: 'timestamp >= ? AND timestamp <= ?',
      whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
      orderBy: 'timestamp DESC',
    );

    return maps.map(BloodPressureReading.fromMap).toList();
  }

  /// Get single reading by ID
  Future<BloodPressureReading?> getReadingById(int id) async {
    final db = await database;

    final maps = await db.query(
      _table,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return BloodPressureReading.fromMap(maps.first);
  }

  /// Update existing reading
  Future<int> updateReading(BloodPressureReading reading) async {
    if (reading.id == null) {
      throw ArgumentError('Cannot update a reading without an id');
    }
    final db = await database;

    final map = reading.toMap()..remove('id');
    return db.update(
      _table,
      map,
      where: 'id = ?',
      whereArgs: [reading.id],
    );
  }

  /// Delete reading
  Future<int> deleteReading(int id) async {
    final db = await database;
    return db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  /// Delete all readings (use with caution!)
  Future<int> deleteAllReadings() async {
    final db = await database;
    return db.delete(_table);
  }

  /// Get count of readings
  Future<int> getReadingCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM $_table');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Close database
  Future<void> close() async {
    final pending = _database;
    if (pending == null) return;
    _database = null;
    await (await pending).close();
  }
}
