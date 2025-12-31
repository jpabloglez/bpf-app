# Testing Guide

This guide covers all aspects of testing the Blood Pressure Tracker app, from unit tests to deployment on physical devices.

## Table of Contents
1. [Testing Overview](#testing-overview)
2. [Unit Testing](#unit-testing)
3. [Widget Testing](#widget-testing)
4. [Integration Testing](#integration-testing)
5. [Testing on Emulators](#testing-on-emulators)
6. [Testing on Physical Devices](#testing-on-physical-devices)
7. [Manual Testing Checklist](#manual-testing-checklist)
8. [Performance Testing](#performance-testing)
9. [Common Issues](#common-issues)

---

## Testing Overview

### Testing Pyramid

```
        /\
       /  \
      / UI \          ← Few (Slow, Expensive)
     /------\
    /  Inte- \        ← Some (Medium Speed)
   /   gration\
  /-------------\
 /  Unit Tests  \     ← Many (Fast, Cheap)
/-----------------\
```

### Test Types

| Type | Purpose | Speed | When to Run |
|------|---------|-------|-------------|
| **Unit** | Test individual functions/classes | Fast (<1s) | Every save (automated) |
| **Widget** | Test UI components | Medium (1-5s) | Before commit |
| **Integration** | Test full user flows | Slow (10-30s) | Before release |
| **Manual** | Test on real devices | Variable | Before each release |

---

## Unit Testing

### Setup

Dependencies are already in `pubspec.yaml`:

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ^5.4.4
  build_runner: ^2.4.7
```

### Writing Unit Tests

#### Example: Test BloodPressureReading Model

Create `test/models/blood_pressure_reading_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:bp_tracker/models/blood_pressure_reading.dart';

void main() {
  group('BloodPressureReading', () {
    test('should create valid reading', () {
      final reading = BloodPressureReading(
        systolic: 120,
        diastolic: 80,
        heartRate: 70,
        timestamp: DateTime.now(),
      );

      expect(reading.systolic, 120);
      expect(reading.diastolic, 80);
      expect(reading.heartRate, 70);
    });

    test('should calculate correct category for normal BP', () {
      final reading = BloodPressureReading(
        systolic: 115,
        diastolic: 75,
        heartRate: 70,
        timestamp: DateTime.now(),
      );

      expect(reading.category, 'Normal');
    });

    test('should calculate correct category for high BP', () {
      final reading = BloodPressureReading(
        systolic: 145,
        diastolic: 95,
        heartRate: 80,
        timestamp: DateTime.now(),
      );

      expect(reading.category, 'High BP Stage 1');
    });

    test('should convert to map correctly', () {
      final reading = BloodPressureReading(
        id: 1,
        systolic: 120,
        diastolic: 80,
        heartRate: 70,
        timestamp: DateTime(2025, 1, 15, 10, 30),
        notes: 'Morning reading',
      );

      final map = reading.toMap();

      expect(map['id'], 1);
      expect(map['systolic'], 120);
      expect(map['diastolic'], 80);
      expect(map['heart_rate'], 70);
      expect(map['notes'], 'Morning reading');
    });

    test('should create from map correctly', () {
      final map = {
        'id': 1,
        'systolic': 120,
        'diastolic': 80,
        'heart_rate': 70,
        'timestamp': DateTime(2025, 1, 15).millisecondsSinceEpoch,
        'notes': 'Test note',
      };

      final reading = BloodPressureReading.fromMap(map);

      expect(reading.id, 1);
      expect(reading.systolic, 120);
      expect(reading.diastolic, 80);
      expect(reading.heartRate, 70);
      expect(reading.notes, 'Test note');
    });
  });

  group('Input Validation', () {
    test('should reject invalid systolic values', () {
      expect(
        () => BloodPressureReading(
          systolic: 300,  // Too high
          diastolic: 80,
          heartRate: 70,
          timestamp: DateTime.now(),
        ),
        throwsAssertionError,
      );
    });

    test('should reject invalid diastolic values', () {
      expect(
        () => BloodPressureReading(
          systolic: 120,
          diastolic: 200,  // Too high
          heartRate: 70,
          timestamp: DateTime.now(),
        ),
        throwsAssertionError,
      );
    });
  });
}
```

#### Example: Test DatabaseService (with Mocks)

Create `test/services/database_service_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:sqflite/sqflite.dart';
import 'package:bp_tracker/services/database_service.dart';
import 'package:bp_tracker/models/blood_pressure_reading.dart';

// Generate mocks
@GenerateMocks([Database])
import 'database_service_test.mocks.dart';

void main() {
  late MockDatabase mockDatabase;
  late DatabaseService databaseService;

  setUp(() {
    mockDatabase = MockDatabase();
    databaseService = DatabaseService(database: mockDatabase);
  });

  group('DatabaseService', () {
    test('insertReading should insert into database', () async {
      final reading = BloodPressureReading(
        systolic: 120,
        diastolic: 80,
        heartRate: 70,
        timestamp: DateTime.now(),
      );

      when(mockDatabase.insert(
        'blood_pressure_readings',
        reading.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      )).thenAnswer((_) async => 1);

      final id = await databaseService.insertReading(reading);

      expect(id, 1);
      verify(mockDatabase.insert(
        'blood_pressure_readings',
        reading.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      )).called(1);
    });

    test('getAllReadings should return list of readings', () async {
      final mockData = [
        {
          'id': 1,
          'systolic': 120,
          'diastolic': 80,
          'heart_rate': 70,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      ];

      when(mockDatabase.query(
        'blood_pressure_readings',
        orderBy: 'timestamp DESC',
      )).thenAnswer((_) async => mockData);

      final readings = await databaseService.getAllReadings();

      expect(readings.length, 1);
      expect(readings[0].systolic, 120);
    });
  });
}
```

#### Generate Mocks

```bash
# Generate mock classes
flutter pub run build_runner build
```

### Running Unit Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/models/blood_pressure_reading_test.dart

# Run tests with coverage
flutter test --coverage

# View coverage report
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Test Coverage Goals

- **Models**: 100% coverage
- **Services**: 90%+ coverage
- **Utilities**: 90%+ coverage
- **Overall**: 80%+ coverage

---

## Widget Testing

### Purpose
Test individual widgets in isolation.

### Example: Test ReadingCard Widget

Create `test/widgets/reading_card_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bp_tracker/widgets/reading_card.dart';
import 'package:bp_tracker/models/blood_pressure_reading.dart';

void main() {
  testWidgets('ReadingCard displays reading data correctly', (WidgetTester tester) async {
    final reading = BloodPressureReading(
      id: 1,
      systolic: 120,
      diastolic: 80,
      heartRate: 70,
      timestamp: DateTime(2025, 1, 15, 10, 30),
      notes: 'Morning reading',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReadingCard(reading: reading),
        ),
      ),
    );

    // Verify text is displayed
    expect(find.text('120/80'), findsOneWidget);
    expect(find.text('70'), findsOneWidget);
    expect(find.text('Morning reading'), findsOneWidget);

    // Verify category indicator
    expect(find.text('Normal'), findsOneWidget);
  });

  testWidgets('ReadingCard shows delete button on swipe', (WidgetTester tester) async {
    final reading = BloodPressureReading(
      systolic: 120,
      diastolic: 80,
      heartRate: 70,
      timestamp: DateTime.now(),
    );

    bool deletePressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReadingCard(
            reading: reading,
            onDelete: () => deletePressed = true,
          ),
        ),
      ),
    );

    // Swipe to reveal delete
    await tester.drag(find.byType(ReadingCard), const Offset(-300, 0));
    await tester.pumpAndSettle();

    // Tap delete button
    await tester.tap(find.byIcon(Icons.delete));
    await tester.pumpAndSettle();

    expect(deletePressed, true);
  });
}
```

### Running Widget Tests

```bash
flutter test test/widgets/
```

---

## Integration Testing

### Setup

Create `integration_test/app_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:bp_tracker/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Blood Pressure Tracker App Integration Tests', () {
    testWidgets('Complete user flow: add reading and view in list', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Verify home screen loads
      expect(find.text('BP Tracker'), findsOneWidget);

      // Tap "Add Reading" button
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Enter reading data
      await tester.enterText(find.byKey(const Key('systolic_field')), '125');
      await tester.enterText(find.byKey(const Key('diastolic_field')), '82');
      await tester.enterText(find.byKey(const Key('heart_rate_field')), '75');
      await tester.enterText(find.byKey(const Key('notes_field')), 'Test reading');

      // Save reading
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify returned to home screen
      expect(find.text('BP Tracker'), findsOneWidget);

      // Verify reading appears in list
      expect(find.text('125/82'), findsOneWidget);
      expect(find.text('75'), findsOneWidget);
    });

    testWidgets('Generate and share PDF report', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to charts screen
      await tester.tap(find.byIcon(Icons.bar_chart));
      await tester.pumpAndSettle();

      // Tap export button
      await tester.tap(find.byIcon(Icons.picture_as_pdf));
      await tester.pumpAndSettle();

      // Verify PDF preview appears
      expect(find.text('PDF Preview'), findsOneWidget);

      // Tap share button
      await tester.tap(find.text('Share'));
      await tester.pumpAndSettle();
    });
  });
}
```

### Running Integration Tests

```bash
# On connected device/emulator
flutter test integration_test/app_test.dart

# With verbose output
flutter test integration_test/app_test.dart --verbose
```

---

## Testing on Emulators

### Create Android Virtual Device (AVD)

#### Using Android Studio

1. **Open AVD Manager**:
   - Click **Tools** → **Device Manager**
   - Or click AVD Manager icon in toolbar

2. **Create Virtual Device**:
   - Click **Create Device**
   - Choose **Phone** → **Pixel 5** (recommended)
   - Click **Next**

3. **Select System Image**:
   - Click **Download** next to **API Level 30** (Android 11) or **API Level 33** (Android 13)
   - Wait for download
   - Select the downloaded image
   - Click **Next**

4. **Configure AVD**:
   - **AVD Name**: Pixel_5_API_30
   - **Startup orientation**: Portrait
   - Click **Show Advanced Settings**:
     - **RAM**: 2048 MB (or 4096 MB if you have 16GB+ RAM)
     - **Internal Storage**: 2048 MB
     - **SD Card**: 512 MB
   - Click **Finish**

5. **Start Emulator**:
   - Click **Play** button (▶️) next to your AVD
   - Wait for emulator to boot (30-60 seconds first time)

#### Using Command Line

```bash
# List available emulators
emulator -list-avds

# Start emulator
emulator -avd Pixel_5_API_30

# Start with GPU acceleration
emulator -avd Pixel_5_API_30 -gpu host
```

### Run App on Emulator

```bash
# List devices (should show emulator)
flutter devices

# Example output:
# emulator-5554 • sdk_gphone64_arm64 • android-arm64 • Android 13 (API 33) (emulator)

# Run on emulator
flutter run

# Or specify device
flutter run -d emulator-5554
```

### Emulator Performance Tips

1. **Enable Hardware Acceleration**:
   - **Linux**: Install KVM
     ```bash
     sudo apt install qemu-kvm
     sudo usermod -aG kvm $USER
     # Log out and back in
     ```
   - **Windows**: Install HAXM via SDK Manager
   - **macOS**: Works automatically with Hypervisor framework

2. **Increase RAM**: AVD Manager → Edit → Advanced → RAM (4GB recommended)

3. **Use x86_64 Images**: Faster than ARM on Intel/AMD CPUs

4. **Close Unnecessary Apps**: Emulator needs resources

### Test Multiple Android Versions

Recommended test matrix:

| Android Version | API Level | Market Share | Priority |
|-----------------|-----------|--------------|----------|
| Android 7.0 | 24 | 5% | Low (minimum supported) |
| Android 10 | 29 | 15% | Medium |
| Android 11 | 30 | 20% | High |
| Android 13 | 33 | 30% | High (latest) |

Create AVDs for API 30 and 33 at minimum.

---

## Testing on Physical Devices

### Enable Developer Mode on Android Phone

#### Step 1: Enable Developer Options

1. Open **Settings** on your Android device
2. Scroll down to **About phone** (or **About device**)
3. Find **Build number**
4. Tap **Build number** 7 times quickly
5. You'll see a message: "You are now a developer!"

#### Step 2: Enable USB Debugging

1. Go back to **Settings**
2. Find **Developer options** (usually near the bottom)
3. Toggle **Developer options** to **ON**
4. Scroll down and enable:
   - ✅ **USB debugging**
   - ✅ **Install via USB** (if available)
   - ✅ **USB debugging (Security settings)** (if available)

### Connect Device to Computer

#### Linux

```bash
# Install ADB if not already installed
sudo apt install android-tools-adb android-tools-fastboot

# Check device connection
adb devices

# Expected output:
# List of devices attached
# 1A2B3C4D5E6F    unauthorized  (first time)

# On phone: Accept "Allow USB debugging" prompt

# Check again
adb devices

# Expected output:
# List of devices attached
# 1A2B3C4D5E6F    device  (authorized!)
```

#### macOS

```bash
# ADB is included with Android Studio
# Or install via Homebrew
brew install android-platform-tools

# Check connection
adb devices
```

#### Windows

1. Install USB drivers (usually automatic via Windows Update)
2. Or download from device manufacturer
3. Check connection:
   ```cmd
   adb devices
   ```

### Troubleshooting Device Connection

#### Issue: "Device not showing"

```bash
# Kill and restart ADB server
adb kill-server
adb start-server

# Check again
adb devices
```

#### Issue: "Unauthorized" status

- Check phone screen for authorization prompt
- Tap "Always allow from this computer"
- Tap "OK"

#### Issue: "No permissions" (Linux)

```bash
# Create udev rules file
sudo nano /etc/udev/rules.d/51-android.rules

# Add line (replace XXXX with vendor ID from `lsusb`):
SUBSYSTEM=="usb", ATTR{idVendor}=="XXXX", MODE="0666", GROUP="plugdev"

# Reload udev rules
sudo udevadm control --reload-rules
sudo udevadm trigger

# Reconnect device
```

### Run App on Physical Device

```bash
# List devices
flutter devices

# Example output:
# sdk_gphone64_arm64 (mobile) • emulator-5554 • android-arm64 • Android 13 (API 33) (emulator)
# SM G991B (mobile) • 1A2B3C4D5E6F • android-arm64 • Android 13 (API 33)

# Run on physical device
flutter run -d 1A2B3C4D5E6F

# Or just run (Flutter will ask which device if multiple)
flutter run
```

### Test Release Build on Device

```bash
# Build and install release APK
flutter build apk --release
adb install build/app/outputs/flutter-apk/app-release.apk

# Or run directly in release mode
flutter run --release
```

### View Logs from Device

```bash
# View Flutter logs
flutter logs

# View all Android logs
adb logcat

# Filter for your app
adb logcat | grep "bp_tracker"

# Clear logs and start fresh
adb logcat -c
adb logcat
```

---

## Manual Testing Checklist

### Pre-Release Testing Checklist

#### Functionality Tests

- [ ] **Add Reading**
  - [ ] Enter valid values (120/80, HR 70)
  - [ ] Add notes
  - [ ] Save successfully
  - [ ] Verify appears in list immediately

- [ ] **Input Validation**
  - [ ] Try systolic > 250 (should show error)
  - [ ] Try diastolic > 150 (should show error)
  - [ ] Try heart rate > 220 (should show error)
  - [ ] Try empty fields (should require input)
  - [ ] Try systolic < diastolic (should warn)

- [ ] **View Readings**
  - [ ] List shows all readings
  - [ ] Sorted by date (newest first)
  - [ ] Date/time formatted correctly
  - [ ] Category indicator shows (Normal, Elevated, etc.)

- [ ] **Edit Reading**
  - [ ] Tap reading to edit
  - [ ] Modify values
  - [ ] Save changes
  - [ ] Verify updated in list

- [ ] **Delete Reading**
  - [ ] Swipe to delete (or delete button)
  - [ ] Confirmation dialog appears
  - [ ] Confirm deletion
  - [ ] Verify removed from list

- [ ] **Charts**
  - [ ] Line chart displays correctly
  - [ ] Systolic and diastolic lines visible
  - [ ] X-axis shows dates
  - [ ] Y-axis shows pressure values
  - [ ] Tap data point shows details
  - [ ] Switch time ranges (week, month, all)

- [ ] **Statistics**
  - [ ] Average BP calculated correctly
  - [ ] Highest/lowest readings shown
  - [ ] Category distribution accurate

- [ ] **PDF Export**
  - [ ] Generate PDF with readings
  - [ ] PDF preview shows correctly
  - [ ] Chart included in PDF (if implemented)
  - [ ] Share via email/messaging works
  - [ ] PDF opens in external viewer

#### UI/UX Tests

- [ ] **Navigation**
  - [ ] Bottom navigation works
  - [ ] Back button works
  - [ ] App bar title correct on each screen

- [ ] **Responsiveness**
  - [ ] Portrait mode works
  - [ ] Landscape mode works (or disabled if intended)
  - [ ] UI doesn't overflow on small screens
  - [ ] UI looks good on large screens/tablets

- [ ] **Loading States**
  - [ ] Loading indicators show for long operations
  - [ ] No frozen UI during database operations

- [ ] **Empty States**
  - [ ] "No readings yet" message when database empty
  - [ ] Helpful guidance on how to add first reading

- [ ] **Error Handling**
  - [ ] Error messages are user-friendly
  - [ ] Errors don't crash the app
  - [ ] Network errors handled (if applicable)

#### Performance Tests

- [ ] **With Small Dataset (10 readings)**
  - [ ] App loads instantly
  - [ ] Charts render quickly
  - [ ] Smooth scrolling

- [ ] **With Medium Dataset (100 readings)**
  - [ ] List scrolls smoothly
  - [ ] Charts update quickly
  - [ ] PDF generation < 3 seconds

- [ ] **With Large Dataset (1000+ readings)**
  - [ ] No lag when opening app
  - [ ] List virtualization works (only visible items rendered)
  - [ ] Chart shows reasonable time period (not all 1000 points)
  - [ ] PDF generation completes successfully

#### Device-Specific Tests

- [ ] **Android 7.0 (API 24)** - Minimum supported version
- [ ] **Android 10 (API 29)** - Common version
- [ ] **Android 13+ (API 33+)** - Latest version with new permissions

- [ ] **Different Screen Sizes**
  - [ ] Small phone (4.5" screen)
  - [ ] Standard phone (6" screen)
  - [ ] Large phone (6.5"+ screen)
  - [ ] Tablet (7"+ screen)

#### Offline/Storage Tests

- [ ] **Airplane Mode**
  - [ ] App works completely offline
  - [ ] No network errors
  - [ ] All features function normally

- [ ] **Storage**
  - [ ] Data persists after app close
  - [ ] Data persists after phone restart
  - [ ] Multiple app restarts don't corrupt data

---

## Performance Testing

### Performance Metrics

#### Startup Time
```bash
# Measure cold start time
adb shell am force-stop com.example.bp_tracker
flutter run --release

# Should be < 2 seconds on modern devices
```

#### Memory Usage

```bash
# Monitor memory
adb shell dumpsys meminfo com.example.bp_tracker

# Target:
# - Idle: < 100 MB
# - Active: < 200 MB
```

#### Frame Rate

```bash
# Run with performance overlay
flutter run --release --profile

# Press 'P' to show performance overlay
# Target: 60 FPS (16ms per frame)
```

### Profiling with DevTools

```bash
# Start DevTools
flutter pub global activate devtools
flutter pub global run devtools

# Run app in profile mode
flutter run --profile

# Open DevTools URL in browser
# Analyze:
# - CPU usage
# - Memory allocation
# - UI jank
# - Frame rendering time
```

---

## Common Issues

### Issue: "App crashes on startup"

**Debug**:
```bash
# View crash logs
adb logcat | grep -i "error\|exception"

# Check specific errors
flutter run --verbose
```

### Issue: "Hot reload not working"

**Solution**:
```bash
# Try hot restart instead
# Press 'R' in terminal

# Or full rebuild
flutter run
```

### Issue: "Database not persisting"

**Debug**:
```bash
# Check database file location
adb shell
run-as com.example.bp_tracker
cd databases
ls -la

# Verify database exists
```

### Issue: "Charts not rendering"

**Check**:
- Widget tree for errors (`flutter run --verbose`)
- Data is not empty
- Chart configuration is correct

---

## Continuous Testing

### Pre-Commit Checks

```bash
# Create pre-commit hook (.git/hooks/pre-commit)
#!/bin/bash
flutter analyze
flutter test
```

### Automated Testing

```bash
# Run tests in CI/CD
flutter test --coverage
flutter build apk --release
```

---

## Next Steps

After thorough testing:

1. Read [Deployment Guide](04-deployment-guide.md) for releasing the app
2. Set up automated testing in CI/CD
3. Collect beta tester feedback

---

**Testing Complete!** Your app is ready for deployment when all tests pass.

**Next**: Continue to [Deployment Guide](04-deployment-guide.md) to build and release your app.
