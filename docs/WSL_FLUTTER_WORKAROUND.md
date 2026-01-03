# Flutter WSL Device Detection Workaround

## The Problem

You're experiencing a known bug in Flutter when running in WSL (Windows Subsystem for Linux):
- Your Android device is **connected and visible** to ADB: `adb-f9aa968f-OwLkQA._adb-tls-connect._tcp` (Xiaomi 2109119DG)
- Windows ADB can see the device perfectly
- Flutter in WSL **crashes** with: `FormatException: Missing extension byte (at offset 7)`
- This is a Flutter/WSL compatibility issue, **not a problem with your app code**

## Solutions

### Option 1: Use Windows Flutter Installation (Recommended)

This is the **most reliable** solution for WSL users.

**Step 1: Install Flutter on Windows**

Download and install Flutter for Windows:
```powershell
# In Windows PowerShell (not WSL)
# Download from: https://flutter.dev/docs/get-started/install/windows

# Or use chocolatey:
choco install flutter

# Or use scoop:
scoop install flutter
```

**Step 2: Add Flutter to Windows PATH**
- Add `C:\src\flutter\bin` to your Windows PATH environment variable
- Restart your terminal

**Step 3: Run Flutter doctor (Windows)**
```powershell
# In Windows PowerShell
flutter doctor
```

**Step 4: Run your app from Windows**
```powershell
# Navigate to your project (WSL path is accessible from Windows)
cd \\wsl$\Ubuntu\home\jpablo\code\mobile\bpf

# Or if you cloned to Windows:
cd C:\Users\juanp\code\mobile\bpf

# Check devices
flutter devices

# Run app
flutter run
```

**Step 5: Edit code in WSL, run from Windows**
- Keep your code in WSL: `/home/jpablo/code/mobile/bpf`
- Access from Windows: `\\wsl$\Ubuntu\home\jpablo\code\mobile\bpf`
- Edit with VS Code in WSL
- Run Flutter commands from Windows PowerShell

---

### Option 2: Use Android Emulator

Create an emulator through Android Studio (avoids USB device issues).

**Step 1: Open Android Studio (Windows)**

**Step 2: Create AVD (Android Virtual Device)**
- Open: Tools → Device Manager
- Click: Create Device
- Select: Phone → Pixel 5 (or any modern device)
- Select System Image: API 34 (Android 14) or API 33 (Android 13)
- Click: Finish

**Step 3: Start Emulator**
- Click the ▶ play button next to your AVD
- Wait for emulator to boot completely

**Step 4: Verify from WSL**
```bash
/mnt/c/Users/juanp/AppData/Local/Android/Sdk/platform-tools/adb.exe devices
```

Expected output:
```
List of devices attached
emulator-5554    device
```

**Step 5: Run Flutter from WSL**
```bash
ANDROID_HOME=/mnt/c/Users/juanp/AppData/Local/Android/Sdk flutter run
```

---

### Option 3: Build APK and Install Manually

If you just want to test on your physical device without fixing Flutter detection:

**Step 1: Build APK**
```bash
cd /home/jpablo/code/mobile/bpf
flutter build apk --debug
```

**Step 2: Install on device**
```bash
/mnt/c/Users/juanp/AppData/Local/Android/Sdk/platform-tools/adb.exe install build/app/outputs/flutter-apk/app-debug.apk
```

**Step 3: Launch app manually on phone**
- Find "BP Tracker" in app drawer
- Tap to launch

**To update after code changes:**
```bash
flutter build apk --debug
/mnt/c/Users/juanp/AppData/Local/Android/Sdk/platform-tools/adb.exe install -r build/app/outputs/flutter-apk/app-debug.apk
```

---

## Recommended Workflow

For **active development** (Option 1 is best):

1. **Code in WSL**: Use VS Code with Remote-WSL extension
   - Full Linux development environment
   - Fast file operations
   - Git works natively

2. **Run Flutter from Windows**: Use Windows PowerShell
   - Reliable device detection
   - Hot reload works perfectly
   - No WSL compatibility issues

3. **Access project from both**:
   - WSL path: `/home/jpablo/code/mobile/bpf`
   - Windows path: `\\wsl$\Ubuntu\home\jpablo\code\mobile\bpf`

For **occasional testing** (Option 3 is simplest):
- Build APK in WSL when ready to test
- Install manually on device
- Quick and reliable

For **emulator testing** (Option 2):
- Best for rapid iteration
- No physical device needed
- Works well with WSL Flutter

---

## Why This Happens

The Flutter WSL bug occurs when:
1. Flutter tries to parse device information from `adb devices -l`
2. Some device names contain non-UTF-8 characters or mDNS names (like `._adb-tls-connect._tcp`)
3. Flutter's UTF-8 decoder crashes on these characters in WSL environment
4. The same code works fine on native Windows/Linux/macOS

**Your device name**: `adb-f9aa968f-OwLkQA._adb-tls-connect._tcp` (wireless ADB connection with mDNS)

This is a Flutter issue tracked on GitHub but not yet fixed in stable releases.

---

## Quick Test: Verify Your Device

Your device details (via Windows ADB):
```
Device ID: adb-f9aa968f-OwLkQA._adb-tls-connect._tcp
Model: 2109119DG (Xiaomi)
Product: lisa_eea
Status: Connected ✓
```

Test from Windows PowerShell:
```powershell
C:\Users\juanp\AppData\Local\Android\Sdk\platform-tools\adb.exe devices

# Should show:
# List of devices attached
# adb-f9aa968f-OwLkQA._adb-tls-connect._tcp    device
```

---

## Next Steps

**Choose your preferred option above and:**

1. If using **Option 1** (Windows Flutter):
   - Install Flutter on Windows
   - Run: `flutter doctor`
   - Run: `flutter run` from Windows PowerShell

2. If using **Option 2** (Emulator):
   - Create AVD in Android Studio
   - Start emulator
   - Run: `flutter run` from WSL

3. If using **Option 3** (Manual APK):
   - Run: `flutter build apk --debug`
   - Run: `adb install build/app/outputs/flutter-apk/app-debug.apk`
   - Launch app on phone

All your code is complete and ready - this is purely a Flutter tooling issue in WSL, not a code problem.
