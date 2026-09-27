import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bp_tracker/main.dart';
import 'package:bp_tracker/providers/readings_provider.dart';
import 'package:bp_tracker/widgets/reading_card.dart';

import 'helpers/fake_database_service.dart';

Future<FakeDatabaseService> pumpApp(
  WidgetTester tester, {
  List initial = const [],
  ThemeMode? themeMode,
}) async {
  // Typical phone viewport (411x891 dp).
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 2.625;
  addTearDown(tester.view.reset);

  final db = FakeDatabaseService(initial.cast());
  await tester.pumpWidget(
    BpTrackerApp(createProvider: () => ReadingsProvider(database: db)),
  );
  await tester.pumpAndSettle();
  return db;
}

/// The history card for a reading with the given 'sys/dia' value.
Finder cardFor(String bp) => find.ancestor(
    of: find.text('$bp mmHg'), matching: find.byType(ReadingCard));

Future<void> tapSave(WidgetTester tester) async {
  final save = find.byKey(const Key('save_button'));
  await tester.scrollUntilVisible(save, 200,
      scrollable: find.byType(Scrollable).first);
  await tester.tap(save);
}

void main() {
  setUpAll(() => WidgetController.hitTestWarningShouldBeFatal = true);

  testWidgets('shows empty state on first launch', (tester) async {
    await pumpApp(tester);

    expect(find.text('No readings yet'), findsOneWidget);
    expect(find.text('Add first reading'), findsOneWidget);
    expect(find.text('Add reading'), findsOneWidget); // FAB
  });

  testWidgets('shows latest reading, summary and history', (tester) async {
    final now = DateTime.now();
    await pumpApp(tester, initial: [
      reading(id: 1, systolic: 118, diastolic: 76, timestamp: now),
      reading(
          id: 2,
          systolic: 150,
          diastolic: 95,
          timestamp: now.subtract(const Duration(days: 3)),
          notes: 'After coffee'),
    ]);

    expect(find.text('Latest reading'), findsOneWidget);
    expect(find.text('118/76'), findsWidgets);
    expect(find.text('Today'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('After coffee'), 200);
    expect(find.text('After coffee'), findsOneWidget);
    expect(find.text('High BP Stage 2'), findsWidgets);
    expect(find.text('Based on 2 readings'), findsOneWidget);
  });

  testWidgets('adds a reading through the form', (tester) async {
    final db = await pumpApp(tester);

    await tester.tap(find.text('Add reading'));
    await tester.pumpAndSettle();
    expect(find.text('New reading'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('systolic_field')), '132');
    await tester.enterText(find.byKey(const Key('diastolic_field')), '84');
    await tester.enterText(find.byKey(const Key('heart_rate_field')), '71');
    await tester.pump();
    // Live category preview.
    expect(find.text('High BP Stage 1'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('notes_field')), '  Morning  ');
    await tapSave(tester);
    await tester.pumpAndSettle();

    expect(find.text('New reading'), findsNothing);
    expect(find.text('Reading saved'), findsOneWidget);
    final saved = (await db.getAllReadings()).single;
    expect(saved.systolic, 132);
    expect(saved.diastolic, 84);
    expect(saved.heartRate, 71);
    expect(saved.notes, 'Morning', reason: 'notes are trimmed');
  });

  testWidgets('validates the form', (tester) async {
    final db = await pumpApp(tester);
    await tester.tap(find.text('Add reading'));
    await tester.pumpAndSettle();

    await tapSave(tester);
    await tester.pump();
    expect(find.text('Required'), findsNWidgets(2));
    expect(find.text('Please enter your pulse'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('systolic_field')), '90');
    await tester.enterText(find.byKey(const Key('diastolic_field')), '95');
    await tester.enterText(find.byKey(const Key('heart_rate_field')), '20');
    await tester.pump();
    expect(find.text('Must be below systolic'), findsOneWidget);
    expect(find.text('Enter 30–250'), findsOneWidget);

    await tapSave(tester);
    await tester.pumpAndSettle();
    expect(await db.getAllReadings(), isEmpty);
  });

  testWidgets('warns about hypertensive crisis values', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Add reading'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('systolic_field')), '190');
    await tester.enterText(find.byKey(const Key('diastolic_field')), '100');
    await tester.pump();

    expect(find.text('Hypertensive Crisis'), findsOneWidget);
    expect(find.textContaining('call emergency services'), findsOneWidget);
  });

  testWidgets('edits and deletes a reading', (tester) async {
    final db = await pumpApp(tester, initial: [
      reading(id: 1, systolic: 125, diastolic: 78, timestamp: DateTime.now()),
    ]);

    await tester.tap(cardFor('125/78'));
    await tester.pumpAndSettle();
    expect(find.text('Edit reading'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('systolic_field')), '128');
    await tapSave(tester);
    await tester.pumpAndSettle();
    expect((await db.getReadingById(1))!.systolic, 128);

    await tester.tap(cardFor('128/78'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Delete reading'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(await db.getAllReadings(), isEmpty);
    expect(find.text('No readings yet'), findsOneWidget);
  });

  testWidgets('swipe to delete can be undone', (tester) async {
    final db = await pumpApp(tester, initial: [
      reading(
          id: 5,
          systolic: 131,
          diastolic: 81,
          timestamp: DateTime.now().subtract(const Duration(days: 2))),
      reading(id: 6, systolic: 119, diastolic: 75, timestamp: DateTime.now()),
    ]);

    // 131/81 shows in the history card and the "Highest" summary tile.
    final card = cardFor('131/81');
    await tester.scrollUntilVisible(card, 200);
    await tester.drag(card, const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(card, findsNothing);
    expect(await db.getReadingById(5), isNull);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(card, 200);
    expect(card, findsOneWidget);
    expect(await db.getReadingById(5), isNotNull);
  });

  testWidgets('charts screen renders trends for each range', (tester) async {
    final now = DateTime.now();
    await pumpApp(tester, initial: [
      for (var i = 0; i < 20; i++)
        reading(
          id: i + 1,
          systolic: 115 + i,
          diastolic: 75 + i % 10,
          heartRate: 60 + i,
          timestamp: now.subtract(Duration(days: i * 3)),
        ),
    ]);

    await tester.tap(find.byTooltip('Charts'));
    await tester.pumpAndSettle();

    expect(find.text('Trends'), findsOneWidget);
    expect(find.byKey(const Key('bp_chart')), findsOneWidget);
    expect(find.byKey(const Key('hr_chart')), findsOneWidget);

    for (final label in ['7 days', '90 days', 'All']) {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('bp_chart')), findsOneWidget);
    }
  });

  testWidgets('charts screen handles an empty range', (tester) async {
    await pumpApp(tester, initial: [
      reading(
          id: 1,
          timestamp: DateTime.now().subtract(const Duration(days: 60))),
    ]);

    await tester.tap(find.byTooltip('Charts'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('7 days'));
    await tester.pumpAndSettle();

    expect(find.text('No readings in this period'), findsOneWidget);
    await tester.tap(find.text('Show all readings'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('bp_chart')), findsOneWidget);
  });

  testWidgets('about dialog shows disclaimer and privacy summary',
      (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byTooltip('More options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('About & disclaimer'));
    await tester.pumpAndSettle();

    expect(find.text('Medical disclaimer'), findsOneWidget);
    expect(find.textContaining('stored only on this device'), findsOneWidget);
  });

  testWidgets('renders in dark mode and with large text', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearAllTestValues);

    await pumpApp(tester, initial: [
      reading(
          id: 1,
          systolic: 182,
          diastolic: 110,
          timestamp: DateTime.now(),
          notes: 'Long note ' * 20),
    ]);

    expect(tester.takeException(), isNull);
    expect(Theme.of(tester.element(find.text('Latest reading'))).brightness,
        Brightness.dark);
  });
}
