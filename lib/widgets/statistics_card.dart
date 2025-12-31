import 'package:flutter/material.dart';
import '../models/reading_statistics.dart';

class StatisticsCard extends StatelessWidget {
  final ReadingStatistics statistics;

  const StatisticsCard({
    Key? key,
    required this.statistics,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistics Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Average BP
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Average BP',
                    '${statistics.avgSystolic.toStringAsFixed(0)}/${statistics.avgDiastolic.toStringAsFixed(0)}',
                    'mmHg',
                    Icons.analytics,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Average HR',
                    statistics.avgHeartRate.toStringAsFixed(0),
                    'bpm',
                    Icons.favorite,
                    Colors.red,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Highest and Lowest
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Highest',
                    statistics.highestReading != null
                        ? '${statistics.highestReading!.systolic}/${statistics.highestReading!.diastolic}'
                        : 'N/A',
                    'mmHg',
                    Icons.arrow_upward,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Lowest',
                    statistics.lowestReading != null
                        ? '${statistics.lowestReading!.systolic}/${statistics.lowestReading!.diastolic}'
                        : 'N/A',
                    'mmHg',
                    Icons.arrow_downward,
                    Colors.green,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Total readings
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.data_usage, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Total Readings: ${statistics.totalReadings}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    String unit,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            unit,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
