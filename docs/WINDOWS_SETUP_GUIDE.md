# Flutter Development on Windows 11 - Complete Setup Guide

This guide will help you set up Flutter and Android development tools directly on Windows 11, avoiding all WSL compatibility issues.

## Prerequisites Check

You already have:
- ✅ Android Studio installed at: `C:\Program Files\Android\Android Studio`
- ✅ Android SDK at: `C:\Users\juanp\AppData\Local\Android\Sdk`
- ✅ Android device connected (Xiaomi 2109119DG)
- ✅ ADB working: `adb-f9aa968f-OwLkQA._adb-tls-connect._tcp`

## Step 1: Install Flutter on Windows

### Download Flutter

1. Open your web browser and go to: https://docs.flutter.dev/get-started/install/windows
2. Download the latest Flutter SDK (or use direct link):
   - https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.24.5-stable.zip

3. Extract the zip file to: `C:\src\flutter`
   - **Important**: Do NOT extract to `C:\Program Files` (requires elevated permissions)
   - Recommended: `C:\src\flutter` or `C:\flutter`

### Add Flutter to PATH

1. Press `Win + X` and select "System"
2. Click "Advanced system settings" on the right
3. Click "Environment Variables" button
4. Under "User variables", find "Path" and click "Edit"
5. Click "New" and add: `C:\src\flutter\bin`
6. Click "OK" on all dialogs

### Verify Installation

1. Open **PowerShell** (not WSL):
   - Press `Win + X`
   - Select "Windows PowerShell" or "Terminal"

2. Run:
```powershell
flutter --version
```

Expected output:
```
Flutter 3.24.5 • channel stable
```

3. Run Flutter doctor:
```powershell
flutter doctor
```

This will show what's configured and what needs attention.

## Step 2: Configure Android SDK

### Set Environment Variables

1. Press `Win + X` and select "System"
2. Click "Advanced system settings"
3. Click "Environment Variables"
4. Under "User variables", click "New":
   - Variable name: `ANDROID_HOME`
   - Variable value: `C:\Users\juanp\AppData\Local\Android\Sdk`
5. Click "OK"

6. Edit "Path" variable again and add these entries:
   - `%ANDROID_HOME%\platform-tools`
   - `%ANDROID_HOME%\cmdline-tools\latest\bin`
   - `%ANDROID_HOME%\emulator`

7. Click "OK" on all dialogs

### Verify ADB Access

1. Close and reopen PowerShell (to load new PATH)
2. Run:
```powershell
adb --version
```

Expected output:
```
Android Debug Bridge version 1.0.XX
```

3. Check connected devices:
```powershell
adb devices
```

Expected output:
```
List of devices attached
adb-f9aa968f-OwLkQA._adb-tls-connect._tcp    device
```

## Step 3: Install Android SDK Command Line Tools (if needed)

If `flutter doctor` shows cmdline-tools missing:

1. Open Android Studio
2. Go to: File → Settings → Appearance & Behavior → System Settings → Android SDK
3. Click "SDK Tools" tab
4. Check: "Android SDK Command-line Tools (latest)"
5. Click "Apply" and wait for installation

## Step 4: Accept Android Licenses

Open PowerShell and run:
```powershell
flutter doctor --android-licenses
```

Press `y` and Enter for all license prompts.

## Step 5: Access Your Project from Windows

Your project is in WSL at: `/home/jpablo/code/mobile/bpf`

**Option A: Access via WSL path (Recommended)**
```powershell
cd \\wsl$\Ubuntu\home\jpablo\code\mobile\bpf
```

**Option B: Copy project to Windows**
```powershell
# Create folder
mkdir C:\Users\juanp\code\mobile\bpf

# Copy from WSL (in PowerShell)
xcopy \\wsl$\Ubuntu\home\jpablo\code\mobile\bpf C:\Users\juanp\code\mobile\bpf /E /I

# Navigate to it
cd C:\Users\juanp\code\mobile\bpf
```

## Step 6: Verify Flutter Setup

In PowerShell, navigate to your project:
```powershell
cd \\wsl$\Ubuntu\home\jpablo\code\mobile\bpf
# OR
cd C:\Users\juanp\code\mobile\bpf
```

Run:
```powershell
flutter doctor -v
```

Expected output should show:
```
[✓] Flutter (Channel stable, 3.24.5, on Microsoft Windows...)
[✓] Android toolchain - develop for Android devices (Android SDK version XX)
[✓] Connected device (1 available)
    • adb-f9aa968f-OwLkQA._adb-tls-connect._tcp (mobile)
```

## Step 7: Get Dependencies

In your project directory:
```powershell
flutter pub get
```

## Step 8: Check Devices

```powershell
flutter devices
```

Expected output:
```
1 connected device:

adb-f9aa968f-OwLkQA._adb-tls-connect._tcp (mobile) • adb-f9aa968f-OwLkQA._adb-tls-connect._tcp • android-arm64 • Android XX (API XX)
```

## Step 9: Run Your App!

### Option A: Run directly
```powershell
flutter run
```

Flutter will:
1. Build the app
2. Install it on your connected device
3. Launch it
4. Enable hot reload (press `r` to reload, `R` to restart)

### Option B: Build and install APK manually
```powershell
# Build debug APK
flutter build apk --debug

# Install on device
adb install build\app\outputs\flutter-apk\app-debug.apk
```

### Option C: Build release APK
```powershell
# For testing (signed with debug key)
flutter build apk --release

# Install
adb install build\app\outputs\flutter-apk\app-release.apk
```

## Step 10: Development Workflow

### Edit Code
- Use VS Code with Remote-WSL extension to edit files in WSL
- OR copy project to Windows and edit there
- OR use VS Code directly on Windows path: `\\wsl$\Ubuntu\home\jpablo\code\mobile\bpf`

### Run/Test on Device
- Always run `flutter run` from **Windows PowerShell**
- Keep PowerShell window open for hot reload
- Make code changes and press `r` in PowerShell to hot reload

### Common Commands
```powershell
# Run app
flutter run

# Run with verbose output
flutter run -v

# Run specific device (if multiple connected)
flutter run -d adb-f9aa968f-OwLkQA._adb-tls-connect._tcp

# Clean build files
flutter clean

# Rebuild
flutter pub get
flutter run

# Build APK
flutter build apk --debug
flutter build apk --release

# Install APK
adb install -r build\app\outputs\flutter-apk\app-debug.apk
```

## Troubleshooting

### "Flutter not recognized"
- Make sure you added `C:\src\flutter\bin` to PATH
- Restart PowerShell after changing PATH
- Verify with: `echo $env:PATH`

### "ANDROID_HOME not set"
- Set environment variable as shown in Step 2
- Restart PowerShell
- Verify with: `echo $env:ANDROID_HOME`

### Device not detected
```powershell
# Restart ADB server
adb kill-server
adb start-server
adb devices

# Check on phone for authorization dialog
# Settings → Developer Options → Revoke USB debugging authorizations
# Then reconnect and approve again
```

### "Gradle build failed"
```powershell
# Clear build cache
flutter clean
cd android
.\gradlew clean
cd ..
flutter pub get
flutter run
```

### VS Code setup (optional)
1. Install Flutter extension in VS Code
2. Open project: `\\wsl$\Ubuntu\home\jpablo\code\mobile\bpf`
3. Press F5 to run (VS Code will use Windows Flutter)

## Summary of What You'll Do

1. **Download Flutter for Windows** from flutter.dev
2. **Extract to** `C:\src\flutter`
3. **Add to PATH**: `C:\src\flutter\bin`
4. **Set ANDROID_HOME**: `C:\Users\juanp\AppData\Local\Android\Sdk`
5. **Open PowerShell** and navigate to project
6. **Run**: `flutter doctor --android-licenses` (accept all)
7. **Run**: `flutter pub get`
8. **Run**: `flutter run`
9. **Watch your app launch** on your Xiaomi phone!

## Next Steps After Setup

Once `flutter run` works:
- Your app will hot reload when you save files
- Make changes in VS Code (WSL or Windows)
- Press `r` in PowerShell terminal to reload
- Press `R` to full restart
- Press `q` to quit

Your code is complete and ready to run - this is just about getting the Flutter tooling working on Windows instead of WSL!
