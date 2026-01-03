# Connect Android Device to WSL for Flutter Development

## Quick Guide: 3 Methods

### Method 1: Use Windows ADB from WSL (Easiest) ⭐

This uses the Windows ADB server that's already installed with Android Studio.

**Step 1: Install ADB in WSL**
```bash
sudo apt update
sudo apt install -y android-tools-adb android-tools-fastboot
```

**Step 2: Connect your phone via USB and enable USB debugging** (see below)

**Step 3: Start Windows ADB server** (in Windows PowerShell):
```powershell
# Find your ADB path (usually):
C:\Users\YourUsername\AppData\Local\Android\Sdk\platform-tools\adb.exe start-server
```

**Step 4: Connect WSL to Windows ADB** (in WSL terminal):
```bash
# Use Windows ADB directly
/mnt/c/Users/juanp/AppData/Local/Android/Sdk/platform-tools/adb.exe devices

# Or create an alias for convenience
alias adb="/mnt/c/Users/juanp/AppData/Local/Android/Sdk/platform-tools/adb.exe"
adb devices
```

**Step 5: Run Flutter app**
```bash
flutter run
```

---

### Method 2: USB/IP - Forward USB to WSL (Advanced)

This method forwards the USB device directly to WSL using usbipd.

**Step 1: Install usbipd on Windows** (PowerShell as Administrator):
```powershell
winget install --interactive --exact dorssel.usbipd-win
```

**Step 2: Install USB/IP tools in WSL**:
```bash
sudo apt update
sudo apt install linux-tools-generic hwdata
sudo update-alternatives --install /usr/local/bin/usbip usbip /usr/lib/linux-tools/*-generic/usbip 20
```

**Step 3: List USB devices** (Windows PowerShell as Administrator):
```powershell
usbipd list
```

You'll see something like:
```
BUSID  VID:PID    DEVICE
1-4    18d1:4ee7  Android Device
```

**Step 4: Attach device to WSL** (Windows PowerShell as Administrator):
```powershell
# Replace 1-4 with your BUSID from step 3
usbipd bind --busid 1-4
usbipd attach --wsl --busid 1-4
```

**Step 5: Verify in WSL**:
```bash
lsusb
adb devices
```

**Step 6: Run Flutter app**:
```bash
flutter run
```

**To detach later** (Windows PowerShell):
```powershell
usbipd detach --busid 1-4
```

---

### Method 3: ADB over WiFi (No USB Cable)

**Step 1: Connect phone and computer to same WiFi**

**Step 2: Connect phone via USB first** (one time setup):
```bash
adb tcpip 5555
```

**Step 3: Find your phone's IP address**:
- Android: Settings → About phone → Status → IP address
- Example: `192.168.1.100`

**Step 4: Disconnect USB and connect via WiFi**:
```bash
adb connect 192.168.1.100:5555
adb devices
```

**Step 5: Run Flutter app**:
```bash
flutter run
```

---

## Enable USB Debugging on Android

### Enable Developer Mode
1. Open **Settings** → **About phone**
2. Tap **Build number** 7 times
3. You'll see: "You are now a developer!"

### Enable USB Debugging
1. Go to **Settings** → **Developer options**
2. Toggle **Developer options** to **ON**
3. Enable:
   - ✅ USB debugging
   - ✅ Install via USB (if available)
   - ✅ USB debugging (Security settings) (if available)

### Authorize Computer
1. Plug phone into computer via USB
2. On phone: Allow USB debugging prompt appears
3. Check "Always allow from this computer"
4. Tap **OK**

---

## Verify Connection

```bash
# List connected devices
adb devices

# Expected output:
# List of devices attached
# 1A2B3C4D5E6F    device

# List Flutter devices
flutter devices

# Run app
flutter run
```

---

## Troubleshooting

### "No devices found"
```bash
# Restart ADB server
adb kill-server
adb start-server
adb devices
```

### "Unauthorized" device
- Check phone screen for authorization prompt
- Re-plug USB cable
- Revoke USB debugging authorizations (Developer Options) and try again

### WSL can't see device
- Use Method 1 (Windows ADB) - easiest
- Or use Method 2 (usbipd) - requires more setup

### "offline" device
```bash
adb kill-server
adb start-server
# Unplug and replug USB cable
```

---

## Recommended Workflow

For WSL + Flutter development, **Method 1** is recommended:

1. Install Android Studio on **Windows**
2. Use **Windows ADB** from WSL (via `/mnt/c/...` path)
3. Keep development in WSL for all other tools
4. Flutter will detect devices through Windows ADB

This gives you:
- ✅ Best compatibility
- ✅ No USB forwarding needed
- ✅ Works with Android Studio emulators
- ✅ Simple setup
