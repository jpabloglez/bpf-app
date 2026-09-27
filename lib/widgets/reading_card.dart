import 'package:flutter/material.dart';
import '../models/blood_pressure_reading.dart';
import 'category_chip.dart';

class ReadingCard extends StatelessWidget {
  final BloodPressureReading reading;
  final VoidCallback? onTap;

  const ReadingCard({
    super.key,
    required this.reading,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final category = reading.bpCategory;
    final time = TimeOfDay.fromDateTime(reading.timestamp).format(context);
    final notes = reading.notes;

    return Card(
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Category indicator
              Container(
                width: 6,
                color: category.colorFor(theme.brightness),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Text.rich(
                            TextSpan(
                              text: '${reading.systolic}/${reading.diastolic}',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                              children: [
                                TextSpan(
                                  text: ' mmHg',
                                  style: theme.textTheme.bodySmall
                                      ?.copyWith(color: muted),
                                ),
                              ],
                            ),
                          ),
                          CategoryChip(category: category, dense: true),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 16,
                        runSpacing: 4,
                        children: [
                          _IconLabel(
                            icon: Icons.favorite,
                            label: '${reading.heartRate} bpm',
                          ),
                          _IconLabel(icon: Icons.schedule, label: time),
                        ],
                      ),
                      if (notes != null && notes.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          notes,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: muted,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconLabel extends StatelessWidget {
  const _IconLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(label, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}
