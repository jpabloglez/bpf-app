#!/bin/bash
# Setup script to configure ADB for WSL

echo "🔧 Setting up ADB for WSL..."
echo ""

# Check if Windows ADB exists
WIN_ADB="/mnt/c/Users/juanp/AppData/Local/Android/Sdk/platform-tools/adb.exe"

if [ -f "$WIN_ADB" ]; then
    echo "✅ Found Windows ADB at: $WIN_ADB"
    echo ""
    echo "Adding alias to ~/.bashrc..."

    # Add alias if not already present
    if ! grep -q "alias adb=" ~/.bashrc 2>/dev/null; then
        echo "" >> ~/.bashrc
        echo "# Android ADB alias for WSL" >> ~/.bashrc
        echo "alias adb='$WIN_ADB'" >> ~/.bashrc
        echo "✅ Alias added to ~/.bashrc"
    else
        echo "ℹ️  Alias already exists in ~/.bashrc"
    fi

    echo ""
    echo "To use immediately, run:"
    echo "  source ~/.bashrc"
    echo ""
    echo "Or just run this now:"
    echo "  alias adb='$WIN_ADB'"
    echo ""

    # Test connection
    echo "Testing ADB connection..."
    "$WIN_ADB" devices

else
    echo "❌ Windows ADB not found at expected location"
    echo ""
    echo "Please install Android Studio on Windows or specify ADB path manually:"
    echo "  Common locations:"
    echo "    - C:\\Users\\USERNAME\\AppData\\Local\\Android\\Sdk\\platform-tools\\adb.exe"
    echo "    - C:\\Android\\Sdk\\platform-tools\\adb.exe"
    echo ""
    echo "Then create alias:"
    echo "  alias adb='/mnt/c/path/to/adb.exe'"
fi

echo ""
echo "📱 Next steps:"
echo "1. Enable USB Debugging on your Android phone (see DEVICE_SETUP.md)"
echo "2. Connect phone via USB"
echo "3. Run: adb devices"
echo "4. Accept prompt on phone"
echo "5. Run: flutter devices"
echo "6. Run: flutter run"
