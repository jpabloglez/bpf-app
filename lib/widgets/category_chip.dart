import 'package:flutter/material.dart';
import '../models/blood_pressure_reading.dart';

/// Pill showing a blood pressure category in its indicator color.
class CategoryChip extends StatelessWidget {
  const CategoryChip({super.key, required this.category, this.dense = false});

  final BpCategory category;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final color = category.colorFor(Theme.of(context).brightness);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 12,
        vertical: dense ? 2 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        category.label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
