# Blood Pressure Tracker - Documentation

Welcome to the Blood Pressure Tracker mobile app documentation. This documentation provides comprehensive guidance for developing, testing, and deploying an Android blood pressure tracking application.

## Table of Contents

1. **[Technology Stack](01-technology-stack.md)** - Understand the technologies, libraries, and architecture used in this project
2. **[Development Setup](02-development-setup.md)** - Step-by-step guide to set up your development environment
3. **[Testing Guide](03-testing-guide.md)** - Learn how to test your app on emulators and physical devices
4. **[Deployment Guide](04-deployment-guide.md)** - Instructions for building, signing, and deploying to Play Store or direct distribution
5. **[Feature Implementation](05-feature-implementation.md)** - Detailed implementation guide for core features

## Quick Start

### Prerequisites
- Computer running Linux, macOS, or Windows
- 8GB RAM minimum (16GB recommended)
- 10GB free disk space
- Android device or ability to run emulator

### Getting Started in 5 Steps

1. **Install Flutter SDK** (see [Development Setup](02-development-setup.md))
   ```bash
   # Download and extract Flutter
   # Add Flutter to your PATH
   flutter doctor
   ```

2. **Install Android Studio** with Android SDK (API 30+)
   ```bash
   # Download from https://developer.android.com/studio
   # Accept Android licenses
   flutter doctor --android-licenses
   ```

3. **Create the Project**
   ```bash
   cd /home/jpablo/code/mobile
   flutter create bpf
   cd bpf
   ```

4. **Add Dependencies** (see [Technology Stack](01-technology-stack.md))
   ```bash
   flutter pub add sqflite path_provider fl_chart pdf printing intl share_plus provider
   ```

5. **Run the App**
   ```bash
   # On emulator
   flutter run

   # On physical device (USB debugging enabled)
   flutter devices
   flutter run -d <device-id>
   ```

## Project Overview

### What This App Does
The Blood Pressure Tracker is a mobile application that allows users to:
- Record blood pressure readings (systolic, diastolic, heart rate)
- View historical readings in a list
- Visualize trends with interactive charts
- Export data as PDF reports for doctors
- Store all data locally on the device (privacy-first, no cloud)

### Technology Choice: Flutter
This project uses **Flutter** for several reasons:
- **Beginner-friendly**: Single language (Dart), easier to learn than native Android
- **Fast development**: Hot reload allows instant UI updates
- **Great documentation**: Extensive official docs and community tutorials
- **Future-proof**: Can expand to iOS with minimal effort
- **Rich ecosystem**: Packages for database, charts, PDF generation, etc.

### Target Platform
- **Primary**: Android 7.0+ (API level 24+)
- **Recommended**: Android 10+ (API level 29+) for best experience
- **Future**: iOS support possible with minimal changes

## Documentation Guide

### For Beginners
If you're new to mobile development:
1. Start with [Development Setup](02-development-setup.md) to install everything
2. Read [Technology Stack](01-technology-stack.md) to understand the tools
3. Follow [Feature Implementation](05-feature-implementation.md) to build the app step-by-step
4. Use [Testing Guide](03-testing-guide.md) to test on your device
5. When ready to release, see [Deployment Guide](04-deployment-guide.md)

### For Experienced Developers
If you have mobile development experience:
1. Skim [Technology Stack](01-technology-stack.md) for library choices
2. Quickly set up via [Development Setup](02-development-setup.md#quick-setup)
3. Jump to [Feature Implementation](05-feature-implementation.md) for architecture
4. Review [Deployment Guide](04-deployment-guide.md) for Play Store specifics

## Project Structure

```
bpf/
├── docs/                           # This documentation
├── lib/                            # Flutter application code
│   ├── main.dart                   # App entry point
│   ├── models/                     # Data models
│   ├── services/                   # Business logic (database, PDF)
│   ├── providers/                  # State management
│   ├── screens/                    # UI screens
│   ├── widgets/                    # Reusable UI components
│   └── utils/                      # Helper functions
├── test/                           # Unit and widget tests
├── integration_test/               # End-to-end tests
├── android/                        # Android-specific configuration
├── ios/                            # iOS-specific (unused for now)
└── pubspec.yaml                    # Dependencies and metadata
```

## Key Features to Implement

### Core Features (MVP)
- ✅ Add blood pressure readings
- ✅ View readings in a list
- ✅ Basic charts (line graph)
- ✅ Local SQLite storage
- ✅ Export to PDF

### Future Enhancements (Optional)
- ⬜ Reminders/notifications for measurements
- ⬜ Multiple user profiles
- ⬜ Data backup to file
- ⬜ Advanced analytics (weekly/monthly trends)
- ⬜ Blood pressure categories and warnings
- ⬜ Medication tracking

## Development Timeline

### Beginner Timeline (6-8 weeks, part-time)
- **Week 1**: Environment setup + Flutter basics
- **Week 2**: Database and data models
- **Week 3**: UI screens (add, list, view)
- **Week 4**: Charts and visualization
- **Week 5**: PDF export and sharing
- **Week 6**: Testing and polish
- **Week 7-8**: Release preparation

### Experienced Timeline (2-3 weeks, part-time)
- **Days 1-3**: Setup + core features
- **Days 4-7**: Charts and PDF export
- **Days 8-14**: Testing and release

## Getting Help

### Official Resources
- **Flutter Documentation**: https://docs.flutter.dev/
- **Dart Language Tour**: https://dart.dev/guides/language/language-tour
- **Flutter Codelabs**: https://docs.flutter.dev/codelabs
- **Flutter YouTube**: https://www.youtube.com/flutterdev

### Community Support
- **Stack Overflow**: Tag questions with `flutter` and `dart`
- **r/FlutterDev**: Reddit community for Flutter developers
- **Flutter Community Slack**: Join at https://fluttercommunity.dev/
- **Discord**: Flutter Community Discord server

### Troubleshooting
If you encounter issues:
1. Check [Development Setup](02-development-setup.md#troubleshooting) for common problems
2. Run `flutter doctor -v` to diagnose setup issues
3. Search Stack Overflow for error messages
4. Refer to [Testing Guide](03-testing-guide.md#common-issues) for device-specific problems

## License and Usage

This documentation and sample code are provided as-is for educational purposes. Feel free to use, modify, and distribute for your own projects.

## Next Steps

Ready to start? Head over to **[Development Setup](02-development-setup.md)** to install Flutter and begin building your blood pressure tracking app!

---

**Last Updated**: 2025-12-31
**Flutter Version**: 3.24+
**Target Android API**: 24+ (Android 7.0+)
