import 'package:flutter_test/flutter_test.dart';
import 'package:bp_tracker/providers/readings_provider.dart';

import '../helpers/fake_database_service.dart';

void main() {
  test('loads readings and statistics', () async {
    final provider = ReadingsProvider(
      database: FakeDatabaseService([
        reading(id: 1, systolic: 120, timestamp: DateTime(2025, 1, 1)),
        reading(id: 2, systolic: 140, timestamp: DateTime(2025, 1, 2)),
      ]),
    );
    expect(provider.hasLoaded, isFalse);

    await provider.loadReadings();

    expect(provider.hasLoaded, isTrue);
    expect(provider.isLoading, isFalse);
    expect(provider.error, isNull);
    expect(provider.readings.map((r) => r.id), [2, 1]);
    expect(provider.statistics!.avgSystolic, 130);
  });

  test('exposed list cannot be mutated', () async {
    final provider =
        ReadingsProvider(database: FakeDatabaseService([reading(id: 1)]));
    await provider.loadReadings();
    expect(() => provider.readings.clear(), throwsUnsupportedError);
  });

  test('add, update and delete keep state in sync', () async {
    final provider = ReadingsProvider(database: FakeDatabaseService());
    await provider.loadReadings();
    expect(provider.hasReadings, isFalse);
    expect(provider.statistics, isNull);

    await provider.addReading(reading(systolic: 125));
    expect(provider.readings.single.id, isNotNull);

    final saved = provider.readings.single;
    await provider.updateReading(saved.copyWith(systolic: 135));
    expect(provider.readings.single.systolic, 135);

    await provider.deleteReading(saved.id!);
    expect(provider.hasReadings, isFalse);
    expect(provider.statistics, isNull);
  });

  test('load failure sets a user-facing error without leaking details',
      () async {
    final db = FakeDatabaseService()..failNextLoad = true;
    final provider = ReadingsProvider(database: db);

    await provider.loadReadings();

    expect(provider.error, isNotNull);
    expect(provider.error, isNot(contains('disk error')));
    expect(provider.hasLoaded, isTrue);

    await provider.loadReadings();
    expect(provider.error, isNull);
  });

  test('delete removes the reading before the database call completes',
      () async {
    final provider = ReadingsProvider(
        database: FakeDatabaseService([reading(id: 1), reading(id: 2)]));
    await provider.loadReadings();

    final pending = provider.deleteReading(1);
    // Synchronously gone, as a dismissed Dismissible requires.
    expect(provider.readings.map((r) => r.id), [2]);
    await pending;
    expect(provider.readings.map((r) => r.id), [2]);
  });

  test('failed delete restores the reading and rethrows', () async {
    final provider = ReadingsProvider(
        database: _FailingDeleteDb([reading(id: 1, systolic: 133)]));
    await provider.loadReadings();

    await expectLater(provider.deleteReading(1), throwsStateError);
    expect(provider.readings.single.systolic, 133);
    expect(provider.statistics, isNotNull);
  });

  test('notifies listeners on changes', () async {
    final provider = ReadingsProvider(database: FakeDatabaseService());
    var notifications = 0;
    provider.addListener(() => notifications++);

    await provider.loadReadings();
    expect(notifications, greaterThan(0));
  });
}

class _FailingDeleteDb extends FakeDatabaseService {
  _FailingDeleteDb(super.initial);

  @override
  Future<int> deleteReading(int id) async => throw StateError('locked');
}
