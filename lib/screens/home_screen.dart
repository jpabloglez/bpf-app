import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/readings_provider.dart';
import '../services/pdf_service.dart';
import '../widgets/about.dart';
import '../widgets/reading_card.dart';
import '../widgets/statistics_card.dart';
import '../models/blood_pressure_reading.dart';
import 'add_reading_screen.dart';
import 'charts_screen.dart';

enum _MenuAction { export, about }

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BP Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.show_chart),
            tooltip: 'Charts',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChartsScreen()),
              );
            },
          ),
          PopupMenuButton<_MenuAction>(
            tooltip: 'More options',
            onSelected: (action) {
              switch (action) {
                case _MenuAction.export:
                  exportReport(context);
                case _MenuAction.about:
                  showAppAbout(context);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _MenuAction.export,
                child: ListTile(
                  leading: Icon(Icons.picture_as_pdf_outlined),
                  title: Text('Export PDF report'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: _MenuAction.about,
                child: ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('About & disclaimer'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<ReadingsProvider>(
        builder: (context, provider, child) {
          if (!provider.hasLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && !provider.hasReadings) {
            return _MessageView(
              icon: Icons.error_outline,
              title: provider.error!,
              action: FilledButton.tonal(
                onPressed: provider.loadReadings,
                child: const Text('Retry'),
              ),
            );
          }

          if (!provider.hasReadings) {
            return _MessageView(
              icon: Icons.monitor_heart_outlined,
              title: 'No readings yet',
              message: 'Log your blood pressure and pulse to start '
                  'tracking trends over time.',
              action: FilledButton.icon(
                onPressed: () => _openEditor(context),
                icon: const Icon(Icons.add),
                label: const Text('Add first reading'),
                style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
              ),
            );
          }

          final entries = _buildEntries(provider.readings);
          final bottomInset = MediaQuery.paddingOf(context).bottom;

          return ListView.builder(
            // Leave room for the FAB and the system navigation bar.
            padding: EdgeInsets.fromLTRB(16, 8, 16, bottomInset + 96),
            itemCount: entries.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return StatisticsCard(statistics: provider.statistics!);
              }
              final entry = entries[index - 1];
              if (entry is DateTime) {
                return _DayHeader(day: entry);
              }
              final reading = entry as BloodPressureReading;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Dismissible(
                  key: ValueKey(reading.id),
                  direction: DismissDirection.endToStart,
                  background: const _DeleteBackground(),
                  onDismissed: (_) => _deleteReading(context, reading),
                  child: ReadingCard(
                    reading: reading,
                    onTap: () => _openEditor(context, reading: reading),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context),
        icon: const Icon(Icons.add),
        label: const Text('Add reading'),
      ),
    );
  }

  /// Interleaves day headers (DateTime) with readings (newest first).
  static List<Object> _buildEntries(List<BloodPressureReading> readings) {
    final entries = <Object>[];
    DateTime? currentDay;
    for (final reading in readings) {
      final t = reading.timestamp;
      final day = DateTime(t.year, t.month, t.day);
      if (day != currentDay) {
        entries.add(day);
        currentDay = day;
      }
      entries.add(reading);
    }
    return entries;
  }

  void _openEditor(BuildContext context, {BloodPressureReading? reading}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddReadingScreen(reading: reading)),
    );
  }

  Future<void> _deleteReading(
    BuildContext context,
    BloodPressureReading reading,
  ) async {
    final provider = context.read<ReadingsProvider>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      await provider.deleteReading(reading.id!);
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Reading deleted'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => provider.addReading(reading).catchError((_) {
              messenger.showSnackBar(
                const SnackBar(content: Text('Could not restore the reading')),
              );
            }),
          ),
        ),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not delete the reading')),
      );
    }
  }
}

/// Exports every reading as a PDF and opens the share sheet.
Future<void> exportReport(BuildContext context) async {
  final provider = context.read<ReadingsProvider>();
  final messenger = ScaffoldMessenger.of(context);
  if (!provider.hasReadings) {
    messenger.showSnackBar(
      const SnackBar(content: Text('Add a reading before exporting')),
    );
    return;
  }
  try {
    await PdfService.generateAndShareReport(
      provider.readings,
      provider.statistics,
    );
  } catch (e) {
    debugPrint('PDF export failed: $e');
    messenger.showSnackBar(
      const SnackBar(content: Text('Could not create the PDF report')),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final String label;
    if (day == today) {
      label = 'Today';
    } else if (day == today.subtract(const Duration(days: 1))) {
      label = 'Yesterday';
    } else if (day.year == today.year) {
      label = DateFormat.MMMEd().format(day);
    } else {
      label = DateFormat.yMMMEd().format(day);
    }

    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Semantics(
        header: true,
        child: Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(Icons.delete_outline, color: colorScheme.onErrorContainer),
    );
  }
}

class _MessageView extends StatelessWidget {
  const _MessageView({
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
