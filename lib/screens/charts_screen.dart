import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/readings_provider.dart';
import '../models/reading_statistics.dart';
import '../widgets/category_chip.dart';
import 'home_screen.dart' show exportReport;

enum ChartRange {
  week('7 days', 7),
  month('30 days', 30),
  quarter('90 days', 90),
  all('All', null);

  const ChartRange(this.label, this.days);

  final String label;
  final int? days;
}

class ChartsScreen extends StatefulWidget {
  const ChartsScreen({super.key});

  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen> {
  ChartRange _range = ChartRange.month;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trends'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Export PDF report',
            onPressed: () => exportReport(context),
          ),
        ],
      ),
      body: Consumer<ReadingsProvider>(
        builder: (context, provider, child) {
          if (!provider.hasReadings) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.show_chart,
                        size: 64, color: theme.colorScheme.primary),
                    const SizedBox(height: 16),
                    Text('No data to display',
                        style: theme.textTheme.titleLarge),
                    const SizedBox(height: 8),
                    const Text('Add some readings to see your trends.'),
                  ],
                ),
              ),
            );
          }

          final now = DateTime.now();
          final cutoff = _range.days == null
              ? null
              : now.subtract(Duration(days: _range.days!));
          // Oldest first for plotting.
          final readings = provider.readings.reversed
              .where((r) => cutoff == null || r.timestamp.isAfter(cutoff))
              .toList();

          return ListView(
            padding: EdgeInsets.fromLTRB(16, 8, 16, bottomInset + 24),
            children: [
              SegmentedButton<ChartRange>(
                segments: [
                  for (final range in ChartRange.values)
                    ButtonSegment(value: range, label: Text(range.label)),
                ],
                selected: {_range},
                showSelectedIcon: false,
                onSelectionChanged: (selection) {
                  setState(() => _range = selection.first);
                },
              ),
              const SizedBox(height: 16),
              if (readings.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Column(
                    children: [
                      const Text('No readings in this period'),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () =>
                            setState(() => _range = ChartRange.all),
                        child: const Text('Show all readings'),
                      ),
                    ],
                  ),
                )
              else ...[
                _RangeSummary(
                    statistics: ReadingStatistics.fromReadings(readings)),
                const SizedBox(height: 16),
                _ChartCard(
                  title: 'Blood pressure',
                  legend: [
                    _LegendItem('Systolic', _systolicColor(theme)),
                    _LegendItem('Diastolic', _diastolicColor(theme)),
                  ],
                  chart: TrendChart(
                    key: const Key('bp_chart'),
                    unit: 'mmHg',
                    start: cutoff,
                    end: cutoff == null ? null : now,
                    referenceLines: const [120, 80],
                    series: [
                      TrendSeries(
                        color: _systolicColor(theme),
                        points: [
                          for (final r in readings)
                            (r.timestamp, r.systolic.toDouble())
                        ],
                      ),
                      TrendSeries(
                        color: _diastolicColor(theme),
                        points: [
                          for (final r in readings)
                            (r.timestamp, r.diastolic.toDouble())
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _ChartCard(
                  title: 'Pulse',
                  legend: [_LegendItem('Heart rate', _pulseColor(theme))],
                  chart: TrendChart(
                    key: const Key('hr_chart'),
                    unit: 'bpm',
                    start: cutoff,
                    end: cutoff == null ? null : now,
                    series: [
                      TrendSeries(
                        color: _pulseColor(theme),
                        fill: true,
                        points: [
                          for (final r in readings)
                            (r.timestamp, r.heartRate.toDouble())
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Dashed lines mark 120/80 mmHg.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  static Color _systolicColor(ThemeData theme) =>
      theme.brightness == Brightness.dark
          ? const Color(0xFFFF8A80)
          : const Color(0xFFC62828);

  static Color _diastolicColor(ThemeData theme) =>
      theme.brightness == Brightness.dark
          ? const Color(0xFF82B1FF)
          : const Color(0xFF1565C0);

  static Color _pulseColor(ThemeData theme) => theme.colorScheme.primary;
}

class _RangeSummary extends StatelessWidget {
  const _RangeSummary({required this.statistics});

  final ReadingStatistics statistics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Average',
                      style: theme.textTheme.labelLarge?.copyWith(color: muted)),
                  const SizedBox(height: 4),
                  Text(
                    '${statistics.avgSystolic.round()}/${statistics.avgDiastolic.round()} mmHg',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    '${statistics.avgHeartRate.round()} bpm · '
                    '${statistics.totalReadings} '
                    '${statistics.totalReadings == 1 ? 'reading' : 'readings'}',
                    style: theme.textTheme.bodySmall?.copyWith(color: muted),
                  ),
                ],
              ),
            ),
            CategoryChip(category: statistics.averageCategory),
          ],
        ),
      ),
    );
  }
}

class _LegendItem {
  const _LegendItem(this.label, this.color);
  final String label;
  final Color color;
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.legend,
    required this.chart,
  });

  final String title;
  final List<_LegendItem> legend;
  final Widget chart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Wrap(
                spacing: 16,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(title, style: theme.textTheme.titleMedium),
                  for (final item in legend)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 3,
                          color: item.color,
                        ),
                        const SizedBox(width: 6),
                        Text(item.label, style: theme.textTheme.bodySmall),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(height: 240, child: chart),
          ],
        ),
      ),
    );
  }
}

class TrendSeries {
  const TrendSeries({
    required this.color,
    required this.points,
    this.fill = false,
  });

  final Color color;
  final List<(DateTime, double)> points;
  final bool fill;
}

/// Line chart over real time: gaps between readings are drawn to scale.
class TrendChart extends StatelessWidget {
  const TrendChart({
    super.key,
    required this.series,
    required this.unit,
    this.start,
    this.end,
    this.referenceLines = const [],
  });

  final List<TrendSeries> series;
  final String unit;

  /// Fixed x-axis bounds; derived from the data when null.
  final DateTime? start;
  final DateTime? end;
  final List<double> referenceLines;

  static const double _msPerDay = 24 * 60 * 60 * 1000;

  static double _x(DateTime t) => t.millisecondsSinceEpoch / _msPerDay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final allPoints = series.expand((s) => s.points).toList();
    if (allPoints.isEmpty) {
      return const Center(child: Text('No data'));
    }

    final xs = allPoints.map((p) => _x(p.$1));
    final ys = [...allPoints.map((p) => p.$2), ...referenceLines];
    var minX = start != null ? _x(start!) : xs.reduce(math.min);
    var maxX = end != null ? _x(end!) : xs.reduce(math.max);
    if (maxX - minX < 1) {
      // A single day of data: widen so points aren't on the edge.
      final mid = (minX + maxX) / 2;
      minX = mid - 0.5;
      maxX = mid + 0.5;
    }
    final minY = ((ys.reduce(math.min) - 10) / 10).floor() * 10.0;
    final maxY = ((ys.reduce(math.max) + 10) / 10).ceil() * 10.0;
    final yInterval = (maxY - minY) > 100 ? 40.0 : 20.0;
    final xInterval = (maxX - minX) / 3;
    final span = maxX - minX;
    final dateFormat = span > 300
        ? DateFormat.yMMM()
        : span <= 1.5
            ? DateFormat.Hm()
            : DateFormat.MMMd();

    return LineChart(
      LineChartData(
        minX: minX,
        maxX: maxX,
        minY: minY,
        maxY: maxY,
        clipData: const FlClipData.all(),
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: yInterval,
          getDrawingHorizontalLine: (_) => FlLine(
            color: theme.colorScheme.outlineVariant,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            for (final y in referenceLines)
              HorizontalLine(
                y: y,
                color: muted.withValues(alpha: 0.6),
                strokeWidth: 1,
                dashArray: [6, 4],
              ),
          ],
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              interval: yInterval,
              minIncluded: false,
              maxIncluded: false,
              getTitlesWidget: (value, meta) => SideTitleWidget(
                meta: meta,
                child: Text(
                  value.toInt().toString(),
                  style: theme.textTheme.labelSmall?.copyWith(color: muted),
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: xInterval,
              getTitlesWidget: (value, meta) {
                final date = DateTime.fromMillisecondsSinceEpoch(
                    (value * _msPerDay).round());
                return SideTitleWidget(
                  meta: meta,
                  fitInside: SideTitleFitInsideData.fromTitleMeta(meta),
                  child: Text(
                    dateFormat.format(date),
                    style: theme.textTheme.labelSmall?.copyWith(color: muted),
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          for (final s in series)
            LineChartBarData(
              spots: [for (final p in s.points) FlSpot(_x(p.$1), p.$2)],
              color: s.color,
              barWidth: 2.5,
              isCurved: false,
              dotData: FlDotData(
                show: s.points.length <= 60,
                getDotPainter: (spot, percent, bar, index) =>
                    FlDotCirclePainter(
                  radius: 3,
                  color: s.color,
                  strokeWidth: 0,
                ),
              ),
              belowBarData: BarAreaData(
                show: s.fill,
                color: s.color.withValues(alpha: 0.12),
              ),
            ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => theme.colorScheme.inverseSurface,
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipItems: (touchedSpots) {
              return [
                for (final (i, spot) in touchedSpots.indexed)
                  LineTooltipItem(
                    i == 0
                        ? '${DateFormat.MMMd().add_Hm().format(DateTime.fromMillisecondsSinceEpoch((spot.x * _msPerDay).round()))}\n'
                        : '',
                    theme.textTheme.labelSmall!.copyWith(
                      color: theme.colorScheme.onInverseSurface,
                    ),
                    children: [
                      TextSpan(
                        text: '${spot.y.toInt()} $unit',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
              ];
            },
          ),
        ),
      ),
    );
  }
}
