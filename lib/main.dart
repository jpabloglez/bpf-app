import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/readings_provider.dart';
import 'screens/home_screen.dart';
import 'theme.dart';

void main() {
  runApp(const BpTrackerApp());
}

class BpTrackerApp extends StatelessWidget {
  const BpTrackerApp({super.key, this.createProvider});

  /// Overrides how the readings provider is created (used by tests).
  final ReadingsProvider Function()? createProvider;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          (createProvider?.call() ?? ReadingsProvider())..loadReadings(),
      child: MaterialApp(
        title: 'BP Tracker',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        themeMode: ThemeMode.system,
        home: const HomeScreen(),
      ),
    );
  }
}
