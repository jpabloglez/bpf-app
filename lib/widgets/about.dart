import 'package:flutter/material.dart';

const String medicalDisclaimer =
    'BP Tracker is a personal log. It does not diagnose, treat or prevent any '
    'condition and is not a substitute for professional medical advice. '
    'Categories follow the AHA/ACC adult guideline and may not apply to you. '
    'Always consult your healthcare provider.';

const String privacySummary =
    'Your readings are stored only on this device. BP Tracker has no '
    'accounts, no analytics and no internet access. Data leaves the device '
    'only when you export and share a PDF report yourself.';

void showAppAbout(BuildContext context) {
  final theme = Theme.of(context);
  showAboutDialog(
    context: context,
    applicationName: 'BP Tracker',
    applicationIcon: Icon(
      Icons.monitor_heart_outlined,
      size: 40,
      color: theme.colorScheme.primary,
    ),
    children: [
      const SizedBox(height: 8),
      Text('Medical disclaimer', style: theme.textTheme.titleSmall),
      const SizedBox(height: 4),
      const Text(medicalDisclaimer),
      const SizedBox(height: 16),
      Text('Privacy', style: theme.textTheme.titleSmall),
      const SizedBox(height: 4),
      const Text(privacySummary),
    ],
  );
}
