import 'package:flutter_test/flutter_test.dart';
import 'package:bp_tracker/models/blood_pressure_reading.dart';
import 'package:bp_tracker/services/database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../helpers/fake_database_service.dart';

void main() {
  late DatabaseService db;

  setUpAll(sqfliteFfiInit);

  setUp(() {
    db = DatabaseService.withFactory(
        databaseFactoryFfiNoIsolate, inMemoryDatabasePath);
  });

  tearDown(() => db.close());

  test('insert assigns ids and getAll returns newest first', () async {
    final id1 = await db.insertReading(
        reading(systolic: 121, timestamp: DateTime(2025, 1, 1)));
    final id2 = await db.insertReading(
        reading(systolic: 122, timestamp: DateTime(2025, 1, 3)));
    await db.insertReading(
        reading(systolic: 123, timestamp: DateTime(2025, 1, 2)));

    expect(id2, greaterThan(id1));
    final all = await db.getAllReadings();
    expect(all.map((r) => r.systolic), [122, 123, 121]);
    expect(await db.getReadingCount(), 3);
  });

  test('stores notes with SQL metacharacters verbatim', () async {
    const notes = "Robert'); DROP TABLE blood_pressure_readings;--";
    final id = await db.insertReading(reading(notes: notes));
    expect((await db.getReadingById(id))!.notes, notes);
    expect(await db.getReadingCount(), 1);
  });

  test('update changes only the targeted row', () async {
    final id = await db.insertReading(reading(systolic: 120));
    final other = await db.insertReading(reading(systolic: 130));

    final original = (await db.getReadingById(id))!;
    expect(await db.updateReading(original.copyWith(systolic: 140)), 1);

    expect((await db.getReadingById(id))!.systolic, 140);
    expect((await db.getReadingById(other))!.systolic, 130);
  });

  test('update without id is rejected', () async {
    expect(() => db.updateReading(reading()), throwsArgumentError);
  });

  test('insert with an existing id fails instead of overwriting', () async {
    final id = await db.insertReading(reading(systolic: 120));
    await expectLater(
      db.insertReading(reading(id: id, systolic: 150)),
      throwsA(isA<DatabaseException>()),
    );
    expect((await db.getReadingById(id))!.systolic, 120);
  });

  test('re-inserting a deleted reading restores it (undo)', () async {
    final id = await db.insertReading(reading(notes: 'keep me'));
    final saved = (await db.getReadingById(id))!;
    expect(await db.deleteReading(id), 1);
    expect(await db.getReadingById(id), isNull);

    await db.insertReading(saved);
    expect(await db.getReadingById(id), saved);
  });

  test('date range is inclusive', () async {
    for (final day in [1, 2, 3, 4]) {
      await db.insertReading(reading(timestamp: DateTime(2025, 1, day)));
    }
    final range = await db.getReadingsByDateRange(
        DateTime(2025, 1, 2), DateTime(2025, 1, 3));
    expect(range.map((r) => r.timestamp.day), [3, 2]);
  });

  test('deleteAll empties the table', () async {
    await db.insertReading(reading());
    await db.insertReading(reading());
    expect(await db.deleteAllReadings(), 2);
    expect(await db.getAllReadings(), isEmpty);
  });

  test('concurrent first access opens a single database', () async {
    final results = await Future.wait([db.database, db.database]);
    expect(identical(results[0], results[1]), isTrue);
  });

  test('round-trips every field', () async {
    final r = BloodPressureReading(
      systolic: 133,
      diastolic: 87,
      heartRate: 64,
      timestamp: DateTime(2025, 6, 1, 21, 15),
      notes: 'Evening',
    );
    final id = await db.insertReading(r);
    expect(await db.getReadingById(id), r.copyWith(id: id));
  });
}
