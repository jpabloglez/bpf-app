import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/blood_pressure_reading.dart';
import '../models/reading_statistics.dart';
import 'category_chip.dart';

/// Summary of the latest reading plus overall averages and extremes.
class StatisticsCard extends StatelessWidget {
  final ReadingStatistics statistics;

  const StatisticsCard({
    super.key,
    required this.statistics,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final latest = statistics.latestReading;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (latest != null) ...[
              Text(
                'Latest reading',
                style: theme.textTheme.labelLarge?.copyWith(color: muted),
              ),
              const SizedBox(height: 4),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  Text.rich(
                    TextSpan(
                      text: '${latest.systolic}/${latest.diastolic}',
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      children: [
                        TextSpan(
                          text: ' mmHg',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(color: muted),
                        ),
                      ],
                    ),
                  ),
                  CategoryChip(category: latest.bpCategory),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${latest.heartRate} bpm · '
                '${DateFormat.MMMd().format(latest.timestamp)}, '
                '${TimeOfDay.fromDateTime(latest.timestamp).format(context)}',
                style: theme.textTheme.bodyMedium?.copyWith(color: muted),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    label: 'Average BP',
                    value:
                        '${statistics.avgSystolic.round()}/${statistics.avgDiastolic.round()}',
                    unit: 'mmHg',
                    accent: statistics.averageCategory,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatTile(
                    label: 'Average pulse',
                    value: '${statistics.avgHeartRate.round()}',
                    unit: 'bpm',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    label: 'Highest',
                    value: _bp(statistics.highestReading),
                    unit: 'mmHg',
                    accent: statistics.highestReading?.bpCategory,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatTile(
                    label: 'Lowest',
                    value: _bp(statistics.lowestReading),
                    unit: 'mmHg',
                    accent: statistics.lowestReading?.bpCategory,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Based on ${statistics.totalReadings} '
              '${statistics.totalReadings == 1 ? 'reading' : 'readings'}',
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            ),
          ],
        ),
      ),
    );
  }

  static String _bp(BloodPressureReading? r) =>
      r == null ? '—' : '${r.systolic}/${r.diastolic}';
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.unit,
    this.accent,
  });

  final String label;
  final String value;
  final String unit;
  final BpCategory? accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final accentColor = accent?.colorFor(theme.brightness);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (accentColor != null) ...[
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(color: muted),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(unit, style: theme.textTheme.bodySmall?.copyWith(color: muted)),
        ],
      ),
    );
  }
}
