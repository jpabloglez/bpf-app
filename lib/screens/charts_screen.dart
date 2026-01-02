import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/readings_provider.dart';
import '../models/blood_pressure_reading.dart';
import '../services/pdf_service.dart';

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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bar_chart, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No data to display'),
                  SizedBox(height: 8),
                  Text('Add some readings to see charts'),
                ],
              ),
            );
          }

          final readings = _getFilteredReadings(provider.readings);

          if (readings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No data for selected range'),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedRange = 'All';
                      });
                    },
                    child: const Text('View All'),
                  ),
                ],
              ),
            );
          }

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
          ),
        ),
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

  void _exportPDF() async {
    final provider = context.read<ReadingsProvider>();

    try {
      await PdfService.generateAndShareReport(
        provider.readings,
        provider.statistics,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

    final spotsSystolic = readings.reversed.toList().asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.systolic.toDouble());
    }).toList();

    final spotsDiastolic = readings.reversed.toList().asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.diastolic.toDouble());
    }).toList();

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true, drawVerticalLine: false),
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
          leftTitles: const AxisTitles(
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
                final color = spot.barIndex == 0 ? Colors.red : Colors.blue;
                return LineTooltipItem(
                  '${DateFormat('MM/dd').format(reading.timestamp)}\n${spot.y.toInt()} mmHg',
                  TextStyle(color: color, fontWeight: FontWeight.bold),
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

    final spots = readings.reversed.toList().asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.heartRate.toDouble());
    }).toList();

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true, drawVerticalLine: false),
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
          leftTitles: const AxisTitles(
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
