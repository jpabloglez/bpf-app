# Technology Stack

This document explains the technology choices, libraries, and architecture for the Blood Pressure Tracker Android application.

## Table of Contents
1. [Core Framework: Flutter](#core-framework-flutter)
2. [Dependencies Overview](#dependencies-overview)
3. [Database: SQLite](#database-sqlite)
4. [Charts: fl_chart](#charts-fl_chart)
5. [PDF Generation](#pdf-generation)
6. [State Management: Provider](#state-management-provider)
7. [Architecture Overview](#architecture-overview)
8. [Alternatives Considered](#alternatives-considered)

---

## Core Framework: Flutter

### What is Flutter?
Flutter is Google's UI toolkit for building natively compiled applications for mobile, web, and desktop from a single codebase. For this project, we use Flutter to target Android devices.

### Why Flutter for This Project?

#### Advantages for Beginners
1. **Single Language**: Only need to learn Dart (no Kotlin + Java + XML)
2. **Hot Reload**: See UI changes instantly (within seconds)
3. **Widget-Based UI**: Intuitive, composable UI components
4. **Excellent Documentation**: Comprehensive official docs with examples
5. **Rich Package Ecosystem**: Libraries for database, charts, PDF, etc.

#### Technical Benefits
1. **Fast Performance**: Compiles to native ARM code
2. **Consistent UI**: Same appearance across all Android versions
3. **Smaller Development Team**: One codebase instead of native Android + iOS
4. **Future-Proof**: Can expand to iOS/Web with minimal changes

#### Trade-offs
- **APK Size**: 20-30MB (larger than native Android's 5-10MB)
- **Platform Features**: Slightly delayed access to newest Android features
- **Learning Curve**: New framework to learn (but easier than native Android)

### Flutter Version
- **Minimum**: Flutter 3.24+
- **Dart**: 3.5+
- **Channel**: Stable (recommended for production apps)

---

## Dependencies Overview

### Production Dependencies (`dependencies:`)

```yaml
dependencies:
  flutter:
    sdk: flutter

  # Database
  sqflite: ^2.3.0              # SQLite database for Flutter
  path_provider: ^2.1.2        # Access to filesystem paths

  # UI / Charts
  fl_chart: ^0.66.0            # Beautiful, customizable charts

  # PDF Export
  pdf: ^3.10.7                 # PDF document generation
  printing: ^5.12.0            # Print/share/preview PDFs

  # Utilities
  intl: ^0.19.0                # Internationalization (date formatting)
  share_plus: ^7.2.1           # Share files via native share sheet

  # State Management
  provider: ^6.1.1             # Recommended state management solution
```

### Development Dependencies (`dev_dependencies:`)

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter

  # Testing
  mockito: ^5.4.4              # Mock objects for testing
  build_runner: ^2.4.7         # Code generation for mocks

  # Linting
  flutter_lints: ^3.0.0        # Recommended lints for Flutter
```

---

## Database: SQLite

### Library: `sqflite`
SQLite is a self-contained, file-based SQL database. The `sqflite` package provides Flutter bindings for SQLite.

### Why SQLite?
1. **Local Storage**: All data stays on device (privacy-first)
2. **No Server Needed**: No backend costs or complexity
3. **Mature**: Industry-standard, battle-tested database
4. **Performant**: Handles thousands of readings efficiently
5. **SQL Support**: Familiar query language

### Database Schema

```sql
CREATE TABLE blood_pressure_readings (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  systolic INTEGER NOT NULL,
  diastolic INTEGER NOT NULL,
  heart_rate INTEGER NOT NULL,
  timestamp INTEGER NOT NULL,  -- Unix timestamp (milliseconds)
  notes TEXT,
  created_at INTEGER NOT NULL  -- When record was created
);

CREATE INDEX idx_timestamp ON blood_pressure_readings(timestamp DESC);
```

### Data Model

```dart
class BloodPressureReading {
  final int? id;
  final int systolic;       // 90-200 mmHg typical range
  final int diastolic;      // 60-130 mmHg typical range
  final int heartRate;      // 40-200 bpm typical range
  final DateTime timestamp; // When measurement was taken
  final String? notes;      // Optional user notes

  // Computed property: blood pressure category
  String get category {
    if (systolic < 120 && diastolic < 80) return 'Normal';
    if (systolic < 130 && diastolic < 80) return 'Elevated';
    if (systolic < 140 || diastolic < 90) return 'High BP Stage 1';
    if (systolic < 180 || diastolic < 120) return 'High BP Stage 2';
    return 'Hypertensive Crisis';
  }
}
```

### Alternative Considered: Drift (Moor)
**Drift** is a type-safe database library built on top of SQLite.
- **Pros**: Better type safety, reactive queries, compile-time SQL checking
- **Cons**: Steeper learning curve, more boilerplate for simple apps
- **Decision**: Use `sqflite` for simplicity; migrate to Drift if app grows complex

---

## Charts: fl_chart

### Library: `fl_chart` ^0.66.0
A powerful and highly customizable chart library for Flutter.

### Why fl_chart?
1. **Most Popular**: Largest community, most Stack Overflow answers
2. **Rich Examples**: Extensive gallery of chart types
3. **Customizable**: Full control over appearance
4. **Good Documentation**: Clear API docs and tutorials
5. **Active Maintenance**: Regular updates and bug fixes

### Chart Types Used

#### Line Chart (Primary)
```dart
LineChart(
  LineChartData(
    lineBarsData: [
      LineChartBarData(
        spots: readings.map((r) => FlSpot(x, r.systolic)).toList(),
        colors: [Colors.red],
        dotData: FlDotData(show: true),
      ),
      LineChartBarData(
        spots: readings.map((r) => FlSpot(x, r.diastolic)).toList(),
        colors: [Colors.blue],
        dotData: FlDotData(show: true),
      ),
    ],
    // ... axis configuration
  ),
)
```

### Features to Implement
- **Systolic/Diastolic Trend**: Two lines on same chart
- **Heart Rate Chart**: Separate line chart
- **Time Ranges**: Daily, weekly, monthly views
- **Interactive**: Tap dots to see exact values
- **Reference Lines**: Show normal BP ranges

### Alternative Considered: Syncfusion Flutter Charts
- **Pros**: More polished, professional appearance
- **Cons**: Free tier has limitations, larger package size
- **Decision**: Use `fl_chart` for open-source, unrestricted usage

---

## PDF Generation

### Libraries
1. **`pdf` ^3.10.7**: Core PDF creation library
2. **`printing` ^5.12.0**: Preview, print, and share PDFs

### Why This Combination?
- **pdf**: Comprehensive PDF building (tables, images, charts, text)
- **printing**: Native sharing via Android's share sheet
- **Together**: Complete PDF workflow (create → preview → share)

### PDF Report Structure

```dart
// Simplified example
Future<pw.Document> generateReport(List<BloodPressureReading> readings) async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      build: (context) => pw.Column(
        children: [
          pw.Header(level: 0, text: 'Blood Pressure Report'),
          pw.Text('Generated: ${DateTime.now()}'),
          pw.SizedBox(height: 20),

          // Summary statistics
          pw.Table(
            children: [
              pw.TableRow(children: [
                pw.Text('Average Systolic'),
                pw.Text('${calculateAvg(readings, 'systolic')} mmHg'),
              ]),
              // ... more rows
            ],
          ),

          // Readings table
          pw.Table.fromTextArray(
            headers: ['Date', 'Systolic', 'Diastolic', 'HR', 'Notes'],
            data: readings.map((r) => [
              formatDate(r.timestamp),
              '${r.systolic}',
              '${r.diastolic}',
              '${r.heartRate}',
              r.notes ?? '',
            ]).toList(),
          ),

          // Chart image (optional)
          pw.Image(chartAsImage),
        ],
      ),
    ),
  );

  return pdf;
}
```

### Sharing PDFs

```dart
// Share via Android's native share sheet
await Printing.sharePdf(
  bytes: await pdf.save(),
  filename: 'bp_report_${DateTime.now().toIso8601String()}.pdf',
);
```

---

## State Management: Provider

### Library: `provider` ^6.1.1
Provider is Flutter's recommended state management solution for simple to medium apps.

### Why Provider?
1. **Official Recommendation**: Endorsed by Flutter team
2. **Beginner-Friendly**: Easiest state management pattern to learn
3. **Scalable**: Works for small to medium apps
4. **Well-Documented**: Extensive docs and examples
5. **InheritedWidget Wrapper**: Uses Flutter's built-in mechanism

### Architecture Pattern

```dart
// Provider class
class ReadingsProvider extends ChangeNotifier {
  final DatabaseService _db;
  List<BloodPressureReading> _readings = [];

  List<BloodPressureReading> get readings => _readings;

  Future<void> loadReadings() async {
    _readings = await _db.getAllReadings();
    notifyListeners();  // Notify UI to rebuild
  }

  Future<void> addReading(BloodPressureReading reading) async {
    await _db.insertReading(reading);
    await loadReadings();  // Refresh list
  }

  Future<void> deleteReading(int id) async {
    await _db.deleteReading(id);
    await loadReadings();
  }
}

// In UI
class ReadingsListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ReadingsProvider>(
      builder: (context, provider, child) {
        return ListView.builder(
          itemCount: provider.readings.length,
          itemBuilder: (context, index) {
            return ReadingCard(reading: provider.readings[index]);
          },
        );
      },
    );
  }
}
```

### Alternative Considered: Riverpod
- **Pros**: More modern, compile-time safety, better testing
- **Cons**: Slightly more complex for beginners
- **Decision**: Use Provider for simplicity; migrate to Riverpod if needed

---

## Architecture Overview

### Clean Architecture (Simplified)

```
┌─────────────────────────────────────────┐
│            UI Layer                     │
│  (Screens, Widgets)                     │
│  - home_screen.dart                     │
│  - add_reading_screen.dart              │
│  - charts_screen.dart                   │
└─────────────────────────────────────────┘
                  ↓ ↑
┌─────────────────────────────────────────┐
│        State Management                 │
│  (Providers)                            │
│  - readings_provider.dart               │
│  - theme_provider.dart                  │
└─────────────────────────────────────────┘
                  ↓ ↑
┌─────────────────────────────────────────┐
│         Business Logic                  │
│  (Services)                             │
│  - database_service.dart                │
│  - pdf_service.dart                     │
│  - export_service.dart                  │
└─────────────────────────────────────────┘
                  ↓ ↑
┌─────────────────────────────────────────┐
│           Data Layer                    │
│  (Models, Local Storage)                │
│  - blood_pressure_reading.dart          │
│  - SQLite database                      │
└─────────────────────────────────────────┘
```

### Folder Structure

```
lib/
├── main.dart                      # App initialization, routing
├── models/                        # Data models (pure Dart classes)
│   ├── blood_pressure_reading.dart
│   └── reading_statistics.dart
├── services/                      # Business logic, no UI
│   ├── database_service.dart      # SQLite CRUD operations
│   ├── pdf_service.dart           # PDF generation
│   └── export_service.dart        # File export utilities
├── providers/                     # State management
│   ├── readings_provider.dart     # Manages BP readings state
│   └── theme_provider.dart        # App theme (dark/light mode)
├── screens/                       # Full-screen pages
│   ├── home_screen.dart           # Dashboard with overview
│   ├── add_reading_screen.dart    # Form to add new reading
│   ├── readings_list_screen.dart  # List all readings
│   ├── charts_screen.dart         # Visualizations
│   └── settings_screen.dart       # App settings
├── widgets/                       # Reusable UI components
│   ├── reading_card.dart          # Display single reading
│   ├── bp_chart.dart              # Chart widget
│   ├── statistics_card.dart       # Stats display
│   └── custom_app_bar.dart        # Reusable app bar
└── utils/                         # Helper functions
    ├── constants.dart             # App constants
    ├── validators.dart            # Input validation
    └── date_helpers.dart          # Date formatting
```

### Data Flow Example

```
User Action (Add Reading)
        ↓
AddReadingScreen
        ↓
ReadingsProvider.addReading()
        ↓
DatabaseService.insertReading()
        ↓
SQLite Database
        ↓
DatabaseService returns success
        ↓
ReadingsProvider.loadReadings()
        ↓
notifyListeners()
        ↓
UI rebuilds with new data
```

---

## Alternatives Considered

### 1. Native Android (Kotlin + Jetpack Compose)

**Pros**:
- Smaller APK size (5-10MB vs 20-30MB)
- Full access to all Android features immediately
- Better performance for complex animations
- More Android-specific jobs/resources

**Cons**:
- Steeper learning curve (Kotlin + Compose + Android SDK + Gradle)
- More boilerplate code
- Longer development time
- Cannot expand to iOS without rewriting

**Decision**: Flutter chosen for beginner-friendliness and faster development.

### 2. React Native

**Pros**:
- Large community and ecosystem
- JavaScript (more developers know it)
- Hot reload like Flutter

**Cons**:
- Performance issues for complex UIs
- Relies on native bridges (can be slow)
- Less consistent across platforms
- React knowledge required

**Decision**: Flutter has better performance and consistency.

### 3. Ionic / Cordova

**Pros**:
- Web technologies (HTML/CSS/JavaScript)
- Easiest for web developers

**Cons**:
- WebView-based (slower performance)
- Feels less native
- Limited offline capabilities

**Decision**: Not suitable for data-heavy apps with charts.

---

## Technology Compatibility Matrix

| Component | Technology | Version | Android API |
|-----------|-----------|---------|-------------|
| Framework | Flutter | 3.24+ | 24+ (Android 7.0+) |
| Language | Dart | 3.5+ | N/A |
| Database | SQLite (sqflite) | 2.3.0+ | 24+ |
| Charts | fl_chart | 0.66.0+ | 24+ |
| PDF | pdf + printing | 3.10.7+ / 5.12.0+ | 24+ |
| State | Provider | 6.1.1+ | 24+ |

**Minimum Android Version**: Android 7.0 (API 24) - Released 2016, covers 99%+ of devices
**Recommended Android Version**: Android 10+ (API 29) - Best compatibility

---

## Performance Considerations

### App Size
- **Initial APK**: ~25-30MB (Flutter runtime included)
- **Installed Size**: ~35-40MB
- **Database**: ~1KB per reading (1000 readings = 1MB)

### Memory Usage
- **Idle**: ~50-80MB RAM
- **Active**: ~100-150MB RAM
- **Large dataset (1000+ readings)**: ~150-200MB RAM

### Battery Impact
- **Minimal**: No background services, no network calls
- **Offline-first**: All operations are local

### Startup Time
- **Cold start**: 1-2 seconds
- **Hot start**: <0.5 seconds

---

## Security Considerations

### Data Privacy
1. **No Network**: App never connects to internet
2. **Local Storage**: All data in device's private storage
3. **No Analytics**: No tracking or telemetry
4. **Permissions**: Only storage permission for PDF export

### Data Protection
1. **SQLite Encryption**: Optional (can add `sqflite_sqlcipher`)
2. **File Permissions**: Android sandboxing protects app data
3. **No Cloud**: No risk of data breaches from servers

### Recommendations
- Consider adding PIN/biometric lock for sensitive health data
- Implement data export for user control
- Clear privacy policy stating "no data collection"

---

## Summary

**Stack Choice: Flutter + Dart**

**Key Libraries**:
- **Database**: sqflite (SQLite)
- **Charts**: fl_chart
- **PDF**: pdf + printing
- **State**: Provider

**Architecture**: Simplified Clean Architecture with Provider for state management

**Why This Stack**: Optimized for beginner-friendliness, fast development, and offline-first local storage while still being scalable and maintainable for future enhancements.

---

**Next**: Proceed to [Development Setup](02-development-setup.md) to install these technologies and set up your development environment.
