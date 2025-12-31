# Development Setup Guide

This guide walks you through setting up your development environment for building the Blood Pressure Tracker Android app with Flutter.

## Table of Contents
1. [System Requirements](#system-requirements)
2. [Install Flutter SDK](#install-flutter-sdk)
3. [Install Android Studio](#install-android-studio)
4. [Install IDE](#install-ide)
5. [Verify Installation](#verify-installation)
6. [Create Project](#create-project)
7. [Add Dependencies](#add-dependencies)
8. [Project Configuration](#project-configuration)
9. [Troubleshooting](#troubleshooting)

---

## System Requirements

### Minimum Requirements
- **OS**: Linux (Ubuntu 18.04+), macOS (10.14+), or Windows 10/11
- **RAM**: 8GB (16GB recommended for Android Emulator)
- **Disk Space**: 10GB free space
- **Internet**: Required for initial setup and downloads

### Recommended Setup
- **RAM**: 16GB (smooth emulator performance)
- **SSD**: Faster build times and emulator startup
- **Multiple Monitors**: One for code, one for emulator/device

---

## Install Flutter SDK

### Linux / WSL Installation

#### Step 1: Download Flutter

```bash
# Navigate to your development directory
cd ~/development
mkdir -p ~/development
cd ~/development

# Download Flutter SDK (stable channel)
wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.5-stable.tar.xz

# Extract the archive
tar xf flutter_linux_3.24.5-stable.tar.xz
```

#### Step 2: Add Flutter to PATH

```bash
# Add Flutter to your PATH permanently
echo 'export PATH="$PATH:$HOME/development/flutter/bin"' >> ~/.bashrc

# For Zsh users
echo 'export PATH="$PATH:$HOME/development/flutter/bin"' >> ~/.zshrc

# Reload shell configuration
source ~/.bashrc  # or source ~/.zshrc
```

#### Step 3: Verify Flutter Installation

```bash
# Check Flutter version
flutter --version

# Should output something like:
# Flutter 3.24.5 • channel stable
# Dart 3.5.4
```

### macOS Installation

#### Option 1: Direct Download

```bash
cd ~/development
wget https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_3.24.5-stable.zip
unzip flutter_macos_3.24.5-stable.zip

# Add to PATH
echo 'export PATH="$PATH:$HOME/development/flutter/bin"' >> ~/.zshrc
source ~/.zshrc
```

#### Option 2: Using Homebrew (Recommended)

```bash
brew install flutter
```

### Windows Installation

#### Step 1: Download Flutter SDK
1. Visit https://docs.flutter.dev/get-started/install/windows
2. Download Flutter SDK (stable channel)
3. Extract ZIP to `C:\src\flutter`

#### Step 2: Update PATH
1. Search for "Environment Variables" in Windows Search
2. Click "Environment Variables"
3. Under "User variables", find "Path"
4. Click "Edit" → "New"
5. Add: `C:\src\flutter\bin`
6. Click "OK" on all dialogs

#### Step 3: Verify Installation
```cmd
flutter --version
```

---

## Install Android Studio

### Why Android Studio?
Even if you use VS Code for coding, you need Android Studio for:
- Android SDK
- Android Emulator
- Build tools
- SDK management

### Installation Steps

#### Linux

```bash
# Download Android Studio
wget https://redirector.gvt1.com/edgedl/android/studio/ide-zips/2023.1.1.28/android-studio-2023.1.1.28-linux.tar.gz

# Extract
tar -xzf android-studio-2023.1.1.28-linux.tar.gz -C ~/

# Run Android Studio
~/android-studio/bin/studio.sh
```

#### macOS

```bash
# Using Homebrew
brew install --cask android-studio

# Or download from: https://developer.android.com/studio
```

#### Windows

1. Download from https://developer.android.com/studio
2. Run the installer
3. Follow the setup wizard

### Android Studio Setup Wizard

1. **Welcome Screen**: Click "Next"
2. **Install Type**: Choose "Standard"
3. **Select UI Theme**: Choose your preference (Darcula or Light)
4. **SDK Components**: Ensure these are checked:
   - Android SDK
   - Android SDK Platform
   - Android Virtual Device
   - Android SDK Build-Tools
5. **Verify Settings**: Review and click "Finish"
6. **Download Components**: Wait for SDK download (3-5GB)

### Install Android SDK Command-line Tools

1. Open Android Studio
2. Go to: **Tools** → **SDK Manager**
3. Click **SDK Tools** tab
4. Check the following:
   - ✅ Android SDK Command-line Tools
   - ✅ Android SDK Build-Tools
   - ✅ Android SDK Platform-Tools
   - ✅ Android Emulator
   - ✅ Intel x86 Emulator Accelerator (HAXM installer) - for Intel CPUs
5. Click "Apply" and wait for installation

### Accept Android Licenses

```bash
# Accept all Android SDK licenses
flutter doctor --android-licenses

# Type 'y' to accept each license
```

---

## Install IDE

You have two options: **VS Code** (lightweight, recommended for beginners) or **Android Studio** (full-featured).

### Option 1: VS Code (Recommended)

#### Install VS Code

**Linux:**
```bash
# Debian/Ubuntu
sudo snap install --classic code

# Or download from: https://code.visualstudio.com/
```

**macOS:**
```bash
brew install --cask visual-studio-code
```

**Windows:**
Download from https://code.visualstudio.com/

#### Install Flutter Extension

1. Open VS Code
2. Click Extensions icon (left sidebar) or press `Ctrl+Shift+X`
3. Search for "Flutter"
4. Install **Flutter** extension (by Dart Code)
   - This also installs the Dart extension automatically
5. Restart VS Code

#### Configure VS Code

Create `.vscode/settings.json` in your project:

```json
{
  "dart.flutterSdkPath": "/home/jpablo/development/flutter",
  "dart.lineLength": 100,
  "editor.formatOnSave": true,
  "editor.rulers": [100],
  "[dart]": {
    "editor.formatOnSave": true,
    "editor.selectionHighlight": false,
    "editor.suggest.snippetsPreventQuickSuggestions": false,
    "editor.suggestSelection": "first",
    "editor.tabCompletion": "onlySnippets",
    "editor.wordBasedSuggestions": false
  }
}
```

#### Recommended VS Code Extensions

- **Flutter** (Dart Code) - Essential
- **Dart** (Dart Code) - Installed with Flutter extension
- **Error Lens** - Inline error highlighting
- **Pubspec Assist** - Easy dependency management
- **Flutter Widget Snippets** - Code snippets

### Option 2: Android Studio with Flutter Plugin

#### Install Flutter Plugin

1. Open Android Studio
2. Go to **File** → **Settings** (Windows/Linux) or **Android Studio** → **Preferences** (macOS)
3. Select **Plugins**
4. Search for "Flutter"
5. Click "Install" on Flutter plugin
   - This also installs the Dart plugin
6. Restart Android Studio

#### Configure Android Studio

1. **File** → **Settings** → **Languages & Frameworks** → **Flutter**
2. Set **Flutter SDK path**: `/home/jpablo/development/flutter`
3. Click "Apply"

---

## Verify Installation

### Run Flutter Doctor

```bash
flutter doctor -v
```

### Expected Output (All ✓)

```
[✓] Flutter (Channel stable, 3.24.5, on Linux, locale en_US.UTF-8)
[✓] Android toolchain - develop for Android devices (Android SDK version 34.0.0)
[✓] Android Studio (version 2023.1)
[✓] VS Code (version 1.85)
[✓] Connected device (1 available)
[✓] Network resources
```

### Fix Common Issues

#### Missing Android SDK
```bash
# If Flutter can't find Android SDK
flutter config --android-sdk /path/to/android/sdk

# Default locations:
# Linux: ~/Android/Sdk
# macOS: ~/Library/Android/sdk
# Windows: C:\Users\<user>\AppData\Local\Android\Sdk
```

#### Missing Android Licenses
```bash
flutter doctor --android-licenses
```

#### Missing Command-line Tools
Open Android Studio → SDK Manager → SDK Tools → Check "Android SDK Command-line Tools"

---

## Create Project

### Initialize Flutter Project

```bash
# Navigate to your projects directory
cd /home/jpablo/code/mobile

# Create new Flutter project
flutter create bpf

# Navigate into project
cd bpf
```

### Project Structure Created

```
bpf/
├── android/              # Android-specific files
├── ios/                  # iOS-specific files (ignore)
├── lib/
│   └── main.dart         # App entry point
├── test/
│   └── widget_test.dart  # Sample test
├── pubspec.yaml          # Dependencies
├── README.md
└── .gitignore
```

### Verify Project Works

```bash
# Check for connected devices (emulator or physical)
flutter devices

# Run the sample app
flutter run
```

---

## Add Dependencies

### Edit `pubspec.yaml`

Open `pubspec.yaml` and replace the `dependencies` section:

```yaml
name: bp_tracker
description: Blood Pressure Tracking Application
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.5.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

  # UI
  cupertino_icons: ^1.0.6

  # Database
  sqflite: ^2.3.0
  path_provider: ^2.1.2

  # Charts
  fl_chart: ^0.66.0

  # PDF
  pdf: ^3.10.7
  printing: ^5.12.0

  # Utilities
  intl: ^0.19.0
  share_plus: ^7.2.1

  # State Management
  provider: ^6.1.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
  mockito: ^5.4.4
  build_runner: ^2.4.7

flutter:
  uses-material-design: true
```

### Install Dependencies

```bash
# Get dependencies
flutter pub get

# Should output:
# Running "flutter pub get" in bpf...
# Resolving dependencies...
# + fl_chart 0.66.0
# + intl 0.19.0
# + path_provider 2.1.2
# + pdf 3.10.7
# + printing 5.12.0
# + provider 6.1.1
# + share_plus 7.2.1
# + sqflite 2.3.0
# ... (more packages)
# Changed X dependencies!
```

### Verify Dependencies

```bash
# List all packages
flutter pub deps

# Check for outdated packages
flutter pub outdated
```

---

## Project Configuration

### Update Android Configuration

#### Set Minimum SDK Version

Edit `android/app/build.gradle`:

```gradle
android {
    compileSdkVersion 34

    defaultConfig {
        applicationId "com.example.bp_tracker"
        minSdkVersion 24           // Android 7.0+
        targetSdkVersion 34
        versionCode 1
        versionName "1.0.0"
    }
}
```

#### Update App Name

Edit `android/app/src/main/AndroidManifest.xml`:

```xml
<application
    android:label="BP Tracker"
    android:icon="@mipmap/ic_launcher">
```

### Create Folder Structure

```bash
cd lib

# Create directories
mkdir models services providers screens widgets utils

# Verify structure
ls -la
```

### Initialize Git Repository

```bash
# From project root
git init

# Check .gitignore is present
cat .gitignore

# Make initial commit
git add .
git commit -m "Initial commit: Flutter project setup"
```

---

## Development Workflow

### Daily Development Commands

#### Start Development

```bash
# 1. Check devices
flutter devices

# 2. Run app (with hot reload)
flutter run

# Or specify device
flutter run -d emulator-5554
flutter run -d <device-id>
```

#### While App is Running

- Press `r` - Hot reload (instant UI updates)
- Press `R` - Hot restart (full app restart)
- Press `p` - Toggle debug painting
- Press `o` - Toggle platform (Android/iOS UI)
- Press `q` - Quit

#### Build and Analyze

```bash
# Check for issues
flutter analyze

# Run tests
flutter test

# Build APK (release)
flutter build apk --release

# Build App Bundle
flutter build appbundle --release

# Clean build artifacts
flutter clean
```

### Performance Profiling

```bash
# Run in profile mode
flutter run --profile

# Run DevTools
flutter pub global activate devtools
flutter pub global run devtools
```

---

## IDE Shortcuts (VS Code)

| Action | Shortcut |
|--------|----------|
| Quick Fix | `Ctrl + .` |
| Format Document | `Shift + Alt + F` |
| Go to Definition | `F12` |
| Find References | `Shift + F12` |
| Rename Symbol | `F2` |
| Command Palette | `Ctrl + Shift + P` |
| Run without Debugging | `Ctrl + F5` |
| Start Debugging | `F5` |

### Flutter-Specific Commands (Ctrl+Shift+P)

- `Flutter: New Project`
- `Flutter: Hot Reload`
- `Flutter: Hot Restart`
- `Dart: Add Dependency`
- `Flutter: Run Flutter Doctor`

---

## Troubleshooting

### Flutter Doctor Issues

#### Issue: "Android licenses not accepted"
```bash
flutter doctor --android-licenses
```

#### Issue: "cmdline-tools component is missing"
- Open Android Studio
- SDK Manager → SDK Tools
- Check "Android SDK Command-line Tools"
- Click Apply

#### Issue: "Unable to locate Android SDK"
```bash
flutter config --android-sdk ~/Android/Sdk
```

### Build Issues

#### Issue: "Gradle build failed"
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

#### Issue: "SDK version mismatch"
- Update `android/app/build.gradle`:
  - Set `compileSdkVersion 34`
  - Set `targetSdkVersion 34`

#### Issue: "Dependency conflicts"
```bash
# Update dependencies
flutter pub upgrade

# Or force resolve
flutter pub get --no-precompile
```

### Emulator Issues

#### Issue: "No devices found"
```bash
# Check running emulators
adb devices

# Start emulator
emulator -avd Pixel_5_API_30
```

#### Issue: "Emulator is slow"
- Enable Hardware Acceleration:
  - **Windows**: Install HAXM via SDK Manager
  - **Linux**: Enable KVM
    ```bash
    sudo apt install qemu-kvm
    sudo usermod -aG kvm $USER
    ```
  - **macOS**: Should work out of the box

#### Issue: "Emulator won't start"
- Increase RAM allocation (Android Studio → AVD Manager → Edit → Advanced → RAM)
- Close other applications
- Try a different API level

### VS Code Issues

#### Issue: "Dart/Flutter extension not working"
1. Restart VS Code
2. Run: `Ctrl+Shift+P` → "Developer: Reload Window"
3. Check Flutter SDK path in settings

#### Issue: "Hot reload not working"
1. Save file (`Ctrl+S`)
2. Try hot restart (`R` in terminal)
3. Check console for errors

---

## Quick Setup Summary

For experienced developers who want a quick setup:

```bash
# 1. Install Flutter
cd ~/development
wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.5-stable.tar.xz
tar xf flutter_linux_3.24.5-stable.tar.xz
echo 'export PATH="$PATH:$HOME/development/flutter/bin"' >> ~/.bashrc
source ~/.bashrc

# 2. Install Android Studio and SDK
# (Follow GUI installer)

# 3. Accept licenses
flutter doctor --android-licenses

# 4. Create project
flutter create bpf
cd bpf

# 5. Add dependencies (edit pubspec.yaml)
# Then:
flutter pub get

# 6. Run
flutter run
```

---

## Next Steps

Now that your development environment is set up:

1. Read [Testing Guide](03-testing-guide.md) to learn how to test on devices
2. Read [Feature Implementation](05-feature-implementation.md) to start building
3. Explore Flutter tutorials: https://docs.flutter.dev/cookbook

---

**Setup Complete!** Your development environment is ready for building the Blood Pressure Tracker app.

**Next**: Continue to [Testing Guide](03-testing-guide.md) to set up emulators and physical devices.
