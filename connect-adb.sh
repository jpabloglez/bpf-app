#!/bin/bash
# Script to connect WSL to Windows ADB server

# Kill any existing ADB server in WSL
adb kill-server 2>/dev/null

# Windows ADB usually runs on port 5037
# Connect WSL ADB to Windows ADB server
export ADB_SERVER_SOCKET=tcp:127.0.0.1:5037

# Or use Windows ADB directly
# Find Windows ADB path (common locations)
WIN_ADB_PATHS=(
    "/mnt/c/Users/$USER/AppData/Local/Android/Sdk/platform-tools/adb.exe"
    "/mnt/c/Program Files (x86)/Android/android-sdk/platform-tools/adb.exe"
    "/mnt/c/Android/Sdk/platform-tools/adb.exe"
)

for path in "${WIN_ADB_PATHS[@]}"; do
    if [ -f "$path" ]; then
        echo "Found Windows ADB at: $path"
        # Create alias to use Windows ADB
        alias adb="$path"
        "$path" devices
        exit 0
    fi
done

echo "Windows ADB not found. Using WSL ADB..."
adb devices
