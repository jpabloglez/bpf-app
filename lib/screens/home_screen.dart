import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/readings_provider.dart';
import '../widgets/reading_card.dart';
import '../widgets/statistics_card.dart';
import '../models/blood_pressure_reading.dart';
import 'add_reading_screen.dart';
import 'charts_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BP Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChartsScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<ReadingsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && !provider.hasReadings) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(provider.error!),
                  TextButton(
                    onPressed: () => provider.loadReadings(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (!provider.hasReadings) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No readings yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text('Tap + to add your first reading'),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: provider.loadReadings,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Statistics card
                if (provider.statistics != null)
                  StatisticsCard(statistics: provider.statistics!),

                const SizedBox(height: 16),

                // Recent readings header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent Readings',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    if (provider.readings.length > 10)
                      TextButton(
                        onPressed: () {
                          // Navigate to full list (future enhancement)
                        },
                        child: const Text('See All'),
                      ),
                  ],
                ),

                const SizedBox(height: 8),

                // Readings list (show latest 10)
                ...provider.readings.take(10).map((reading) {
                  return ReadingCard(
                    key: ValueKey(reading.id),
                    reading: reading,
                    onTap: () => _editReading(context, reading),
                    onDelete: () => _deleteReading(context, provider, reading),
                  );
                }).toList(),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddReadingScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _editReading(BuildContext context, BloodPressureReading reading) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddReadingScreen(reading: reading),
      ),
    );
  }

  void _deleteReading(
    BuildContext context,
    ReadingsProvider provider,
    BloodPressureReading reading,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reading'),
        content: const Text('Are you sure you want to delete this reading?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && reading.id != null) {
      await provider.deleteReading(reading.id!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reading deleted')),
        );
      }
    }
  }
}
