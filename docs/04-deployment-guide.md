# Deployment Guide

> **Current configuration:** the build now uses `android/app/build.gradle.kts`
> (Kotlin DSL), application ID `io.github.jpabloglez.bptracker`, compile/target
> SDK 36 and upload-key signing from `android/key.properties`. Where the Groovy
> `build.gradle` snippets below differ, follow
> **[PLAY_STORE_RELEASE.md](PLAY_STORE_RELEASE.md)**. This guide is kept for
> background.

This guide covers building, signing, and deploying the Blood Pressure Tracker app to the Google Play Store and alternative distribution methods.

## Table of Contents
1. [Pre-Deployment Checklist](#pre-deployment-checklist)
2. [App Configuration](#app-configuration)
3. [Create App Signing Key](#create-app-signing-key)
4. [Build Release APK](#build-release-apk)
5. [Build App Bundle](#build-app-bundle)
6. [Direct APK Distribution](#direct-apk-distribution)
7. [Google Play Store Deployment](#google-play-store-deployment)
8. [Alternative Distribution](#alternative-distribution)
9. [Post-Release](#post-release)

---

## Pre-Deployment Checklist

### Code Quality

```bash
# 1. Run static analysis
flutter analyze

# Expected: No issues found!

# 2. Run all tests
flutter test

# Expected: All tests passing

# 3. Test coverage
flutter test --coverage

# Expected: >80% coverage
```

### Functionality Checklist

- [ ] App works in release mode: `flutter run --release`
- [ ] All features tested on physical device
- [ ] Tested on Android 7.0 (API 24) minimum
- [ ] Tested on Android 13+ (API 33) latest
- [ ] Tested on different screen sizes
- [ ] No crashes or ANRs (App Not Responding)
- [ ] Smooth performance with large datasets
- [ ] Offline functionality verified

### Content & Assets

- [ ] App icon created (512x512 PNG)
- [ ] Splash screen implemented (optional)
- [ ] All images optimized
- [ ] Privacy policy prepared
- [ ] App description written
- [ ] Screenshots captured (2-8 images)

### Legal & Compliance

- [ ] Privacy policy URL ready
- [ ] GDPR compliance (if targeting EU)
- [ ] No third-party tracking (for this offline app)
- [ ] Open source licenses documented

---

## App Configuration

### Update `pubspec.yaml`

```yaml
name: bp_tracker
description: Blood Pressure Tracking Application
publish_to: 'none'

version: 1.0.0+1  # version+buildNumber
# Update this for each release:
# - 1.0.0+1 (initial release)
# - 1.0.1+2 (bug fix)
# - 1.1.0+3 (new features)
# - 2.0.0+4 (major update)

environment:
  sdk: '>=3.5.0 <4.0.0'
```

### Update Android Metadata

#### `android/app/build.gradle`

```gradle
android {
    namespace "com.example.bp_tracker"
    compileSdkVersion 34

    defaultConfig {
        applicationId "com.yourname.bp_tracker"  // CHANGE THIS (unique identifier)
        minSdkVersion 24                          // Android 7.0+
        targetSdkVersion 34                       // Latest
        versionCode 1                             // Increment for each release
        versionName "1.0.0"                       // Human-readable version

        // Optional: Specify supported densities
        resConfigs "en", "es"  // Add your supported languages
    }

    buildTypes {
        release {
            // Enables code shrinking
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'

            signingConfig signingConfigs.release
        }
    }
}
```

**IMPORTANT**: Change `applicationId` to your unique identifier:
- Format: `com.yourname.appname` or `com.yourdomain.appname`
- Must be unique across all Play Store apps
- Cannot be changed after first publish

#### `android/app/src/main/AndroidManifest.xml`

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application
        android:label="BP Tracker"
        android:icon="@mipmap/ic_launcher"
        android:name="${applicationName}">

        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">

            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
    </application>

    <!-- Permissions (if needed for PDF export) -->
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
        android:maxSdkVersion="28" />
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
        android:maxSdkVersion="32" />
</manifest>
```

### Create App Icon

#### Generate Icons

1. **Create 512x512 icon** in design tool (Figma, Canva, etc.)
2. Use Android Asset Studio: https://romannurik.github.io/AndroidAssetStudio/
3. Upload your icon
4. Download generated assets
5. Replace files in `android/app/src/main/res/`:
   ```
   mipmap-mdpi/ic_launcher.png     (48x48)
   mipmap-hdpi/ic_launcher.png     (72x72)
   mipmap-xhdpi/ic_launcher.png    (96x96)
   mipmap-xxhdpi/ic_launcher.png   (144x144)
   mipmap-xxxhdpi/ic_launcher.png  (192x192)
   ```

#### Or Use flutter_launcher_icons Package

```yaml
# pubspec.yaml
dev_dependencies:
  flutter_launcher_icons: ^0.13.1

flutter_launcher_icons:
  android: true
  ios: false
  image_path: "assets/icon/icon.png"  # Your 512x512 icon
```

```bash
# Generate icons
flutter pub get
flutter pub run flutter_launcher_icons
```

---

## Create App Signing Key

### Why Sign Your App?

Android requires all apps to be digitally signed before installation. Your signing key:
- Identifies you as the developer
- Ensures updates come from you
- Required for Play Store publishing

**CRITICAL**: **DO NOT LOSE YOUR SIGNING KEY!** If lost, you cannot update your app on Play Store.

### Generate Keystore

```bash
# Create directory for keystore
mkdir -p /home/jpablo/code/mobile/bpf/android/app/keystore

# Generate keystore (RSA, 10,000 day validity)
keytool -genkey -v \
  -keystore /home/jpablo/code/mobile/bpf/android/app/keystore/bp-tracker-key.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias bp-tracker

# You'll be prompted for:
# - Keystore password: [CREATE STRONG PASSWORD - SAVE IT!]
# - Key password: [CREATE STRONG PASSWORD - SAVE IT!]
# - First and last name: [Your name or company]
# - Organizational unit: [Optional]
# - Organization: [Your company or "Personal"]
# - City: [Your city]
# - State: [Your state]
# - Country code: [Your 2-letter country code, e.g., US]
```

### Backup Your Keystore

**EXTREMELY IMPORTANT**:

1. **Copy keystore file** to secure location:
   ```bash
   # Copy to encrypted cloud storage, USB drive, etc.
   cp /home/jpablo/code/mobile/bpf/android/app/keystore/bp-tracker-key.jks ~/Backups/
   ```

2. **Save passwords** in password manager (LastPass, 1Password, Bitwarden, etc.)

3. **Store securely**:
   - Encrypted cloud storage (Google Drive with encryption, Dropbox)
   - Multiple USB drives in different locations
   - Password manager with secure notes

**What happens if you lose it?**
- Cannot publish updates to existing Play Store app
- Must publish as entirely new app
- Users must uninstall old app and install new one
- Lose all reviews and downloads

### Configure Signing in Project

#### Create `android/key.properties`

```bash
cat > /home/jpablo/code/mobile/bpf/android/key.properties << EOF
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=bp-tracker
storeFile=/home/jpablo/code/mobile/bpf/android/app/keystore/bp-tracker-key.jks
EOF
```

**Replace** `YOUR_KEYSTORE_PASSWORD` and `YOUR_KEY_PASSWORD` with your actual passwords.

#### Update `.gitignore`

```bash
# Add to .gitignore to prevent committing secrets
echo "android/key.properties" >> .gitignore
echo "android/app/keystore/" >> .gitignore
```

#### Configure `android/app/build.gradle`

Add before `android {` block:

```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    // ... existing config ...

    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }

    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
        }
    }
}
```

---

## Build Release APK

### Standard APK (Universal)

```bash
# Build release APK
flutter build apk --release

# Output location:
# build/app/outputs/flutter-apk/app-release.apk

# File size: ~20-30 MB
```

### Split APKs (Smaller Size)

Build separate APKs for different CPU architectures:

```bash
# Build split APKs
flutter build apk --split-per-abi

# Output files:
# build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk  (~15 MB) - Older 32-bit devices
# build/app/outputs/flutter-apk/app-arm64-v8a-release.apk    (~18 MB) - Modern 64-bit devices
# build/app/outputs/flutter-apk/app-x86_64-release.apk       (~20 MB) - Emulators/x86 devices
```

**When to use split APKs:**
- Uploading multiple APKs to Play Store (automatic delivery to right devices)
- Users prefer smaller downloads
- Play Store handles distribution automatically

**When to use universal APK:**
- Direct distribution (email, website)
- Simpler distribution (one file)
- Users may have any device type

### Verify APK Signature

```bash
# Check APK signature
keytool -printcert -jarfile build/app/outputs/flutter-apk/app-release.apk

# Output should show:
# Owner: CN=Your Name, ...
# Issuer: CN=Your Name, ...
# SHA256: [fingerprint]
```

### Install APK on Device (Testing)

```bash
# Install on connected device
adb install build/app/outputs/flutter-apk/app-release.apk

# Or install split APK
adb install build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

---

## Build App Bundle

### What is an App Bundle?

Android App Bundle (`.aab`) is Google Play's publishing format. Benefits:
- Smaller downloads (Play Store generates optimized APKs)
- Automatic split APKs for different devices
- Required for new apps on Play Store (since August 2021)

### Build App Bundle

```bash
# Build release app bundle
flutter build appbundle --release

# Output location:
# build/app/outputs/bundle/release/app-release.aab

# File size: ~25-30 MB (but users download less)
```

### Verify App Bundle

```bash
# Install bundletool
wget https://github.com/google/bundletool/releases/download/1.15.6/bundletool-all-1.15.6.jar
mv bundletool-all-1.15.6.jar ~/bundletool.jar

# Generate APKs from bundle (for testing)
java -jar ~/bundletool.jar build-apks \
  --bundle=build/app/outputs/bundle/release/app-release.aab \
  --output=app-release.apks \
  --ks=/home/jpablo/code/mobile/bpf/android/app/keystore/bp-tracker-key.jks \
  --ks-key-alias=bp-tracker

# Install on connected device
java -jar ~/bundletool.jar install-apks --apks=app-release.apks
```

---

## Direct APK Distribution

### Use Cases
- Beta testing with friends/family
- Internal company distribution
- Users without Play Store access
- Immediate distribution without Play Store review

### Distribution Methods

#### 1. Email

```bash
# APK is small enough to email directly
# Attach: build/app/outputs/flutter-apk/app-release.apk
```

**User Installation**:
1. Download APK on Android device
2. Go to Settings → Security → Install unknown apps
3. Enable for email app (Gmail, etc.)
4. Tap APK file to install

#### 2. Google Drive / Dropbox

```bash
# Upload APK to cloud storage
# Share link with users
```

#### 3. Direct Download (Web Server)

```bash
# Host APK on your website
# Users download and install
```

**Include QR code** for easy mobile access.

#### 4. USB Transfer

```bash
# Copy APK to phone via USB
adb push build/app/outputs/flutter-apk/app-release.apk /sdcard/Download/

# User installs from Downloads folder
```

### Security Warnings

Users will see "Install unknown apps" warning. Provide clear instructions:

**Installation Instructions for Users:**
```markdown
1. Download the APK file
2. Open Settings on your Android device
3. Go to Security (or Apps & notifications)
4. Enable "Install unknown apps" for your browser/file manager
5. Tap the downloaded APK file
6. Tap "Install"
7. Open BP Tracker from your app drawer
```

---

## Google Play Store Deployment

### Create Developer Account

1. **Visit**: https://play.google.com/console
2. **Sign in** with Google account
3. **Pay one-time fee**: $25 USD
4. **Complete registration**:
   - Developer name
   - Email address
   - Phone number
5. **Account approval**: 2-3 days

### Create New App

1. **Go to Play Console**: https://play.google.com/console
2. Click **Create app**
3. Fill in details:
   - **App name**: BP Tracker
   - **Default language**: English (US)
   - **App or game**: App
   - **Free or paid**: Free
4. **Declarations**:
   - [ ] Read developer program policies
   - [ ] App complies with policies
   - [ ] Understand US export laws
5. Click **Create app**

### Set Up App

#### Dashboard

Complete all required tasks in the dashboard:

1. **App access**
   - Select: "All functionality is available without restrictions"
   - (Or provide test account if login required)

2. **Ads**
   - Select: "No, my app does not contain ads"

3. **Content rating**
   - Click "Start questionnaire"
   - Select category: "Utility, Productivity, Communication, or Other"
   - Answer questions:
     - Violence: None
     - Sexual content: None
     - Language: None
     - Controlled substances: None
     - Health-related: User-generated health data (BP readings)
   - Submit and get rating (likely "Everyone")

4. **Target audience**
   - Select: "18+"
   - (Health apps should be 18+)

5. **News app**
   - Select: "No"

6. **COVID-19 contact tracing**
   - Select: "No"

7. **Data safety**
   - Click "Start"
   - **Data collection**: "Yes" (BP readings stored locally)
   - **Data types collected**: Health and fitness
   - **Data sharing**: "No" (all data local)
   - **Data security**:
     - Encrypted in transit: No (no network)
     - Encrypted at rest: Optional (recommend SQLCipher)
     - Can users request deletion: Yes
   - **Privacy policy URL**: Required!

#### Privacy Policy

Create a simple privacy policy:

**Example Privacy Policy** (`privacy-policy.md`):

```markdown
# Privacy Policy for BP Tracker

Last updated: [Date]

## Data Collection
BP Tracker stores blood pressure readings locally on your device. We do not collect, transmit, or share any of your data.

## Data Storage
All data is stored in your device's private storage and is never transmitted to external servers.

## Data Security
Your data is protected by Android's built-in app sandboxing. Only you have access to your blood pressure readings.

## Data Deletion
You can delete all data by uninstalling the app or using the app's "Clear Data" feature in Android settings.

## Third-Party Services
This app does not use any third-party services, analytics, or tracking.

## Contact
For questions, email: your.email@example.com
```

Host on:
- GitHub Pages
- Personal website
- Google Sites (free)

### Prepare Store Listing

#### Main store listing

1. **App name**: BP Tracker
2. **Short description** (80 characters):
   ```
   Track blood pressure readings with charts and PDF reports
   ```

3. **Full description** (4000 characters):
   ```
   BP Tracker is a simple, private blood pressure tracking app that helps you monitor your cardiovascular health.

   KEY FEATURES:
   • Record blood pressure readings (systolic, diastolic, heart rate)
   • Add notes to each reading
   • View historical readings in easy-to-read list
   • Visualize trends with interactive charts
   • Generate PDF reports to share with your doctor
   • 100% offline - all data stays on your device
   • No ads, no tracking, no account required

   PRIVACY FIRST:
   Your health data never leaves your device. No cloud storage, no servers, no data collection. Your blood pressure readings are for your eyes only.

   EASY TO USE:
   Simple, clean interface designed for daily use. Add readings in seconds, view trends at a glance.

   PERFECT FOR:
   • Monitoring hypertension
   • Tracking medication effectiveness
   • Sharing data with healthcare providers
   • Personal health records

   100% FREE, NO ADS:
   BP Tracker is completely free with no ads, no in-app purchases, and no subscriptions.

   Note: This app is for informational purposes only and is not a substitute for professional medical advice. Always consult your doctor about your blood pressure.
   ```

4. **App icon**: Upload 512x512 PNG
5. **Feature graphic**: 1024x500 PNG (banner image)

#### Screenshots

Upload 2-8 screenshots:
- **Phone screenshots**: Minimum 2
  - Home screen with readings
  - Add reading screen
  - Charts screen
  - PDF export screen
- **7-inch tablet screenshots**: Optional
- **10-inch tablet screenshots**: Optional

**Screenshot Guidelines**:
- Min resolution: 320px
- Max resolution: 3840px
- Aspect ratio: 16:9 to 2:1

**Capture screenshots**:
```bash
# Run on device/emulator
flutter run --release

# Take screenshots via ADB
adb shell screencap -p /sdcard/screenshot.png
adb pull /sdcard/screenshot.png

# Or use device's screenshot feature (Power + Volume Down)
```

### Upload App Bundle

1. **Go to**: Production → Releases
2. Click **Create new release**
3. **App signing by Google Play**: Enroll (recommended)
   - Let Google manage your signing key
   - You keep upload key
   - More secure
4. **Upload app bundle**: Drag `app-release.aab`
5. **Release name**: "1.0.0" (or version number)
6. **Release notes**:
   ```
   Initial release of BP Tracker

   Features:
   - Record blood pressure readings
   - View historical data
   - Visualize trends with charts
   - Export PDF reports
   - 100% offline and private
   ```
7. Click **Save**

### Review and Publish

1. **Review release**:
   - Check all info is correct
   - Verify version number
   - Review store listing
2. **Click "Start rollout to Production"**
3. **Wait for review**: 1-7 days (average 1-3 days)

### Review Process

Google will review your app for:
- Policy compliance
- Malware/security issues
- Functionality
- Metadata accuracy

**Common rejection reasons**:
- Missing privacy policy
- Misleading screenshots
- Incomplete store listing
- Permissions not explained

### Post-Approval

Once approved:
- App goes live within hours
- Users can search and download
- Check listing: `https://play.google.com/store/apps/details?id=com.yourname.bp_tracker`

---

## Alternative Distribution

### Firebase App Distribution

**Best for**: Beta testing, internal distribution

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login
firebase login

# Initialize Firebase
firebase init

# Upload APK
firebase appdistribution:distribute \
  build/app/outputs/flutter-apk/app-release.apk \
  --app YOUR_FIREBASE_APP_ID \
  --groups "testers"
```

**Advantages**:
- Invite testers via email
- Automatic update notifications
- Crash reporting
- Analytics

### Amazon Appstore

**Best for**: Reaching Fire tablet users

1. Create account: https://developer.amazon.com/
2. Upload APK
3. Similar process to Play Store
4. Easier approval process
5. Smaller audience

### F-Droid

**Best for**: Open-source apps

1. Must be 100% open source
2. Submit to F-Droid repository
3. Community builds and distributes
4. Privacy-focused audience

### Samsung Galaxy Store

**Best for**: Reaching Samsung users

1. Create account: https://seller.samsungapps.com/
2. Upload APK
3. Similar to Play Store
4. Samsung device users

---

## Post-Release

### Monitor Metrics

**Play Console Analytics**:
- Installs
- Uninstalls
- Active devices
- Crashes (ANRs)
- User ratings/reviews

### Respond to Reviews

- Reply to user feedback
- Fix reported bugs
- Thank users for positive reviews

### Release Updates

```bash
# 1. Update version in pubspec.yaml
version: 1.0.1+2

# 2. Update version in android/app/build.gradle
versionCode 2
versionName "1.0.1"

# 3. Build new bundle
flutter build appbundle --release

# 4. Upload to Play Console
# Production → Create new release → Upload bundle
```

### Crash Reporting

Integrate Firebase Crashlytics:

```yaml
# pubspec.yaml
dependencies:
  firebase_core: ^2.24.2
  firebase_crashlytics: ^3.4.9
```

### Analytics (Optional)

Consider adding analytics to understand usage:

```yaml
dependencies:
  firebase_analytics: ^10.7.4
```

**Note**: Update privacy policy if adding analytics!

---

## Versioning Best Practices

### Semantic Versioning

Format: `MAJOR.MINOR.PATCH+BUILD`

- **MAJOR**: Incompatible changes (1.0.0 → 2.0.0)
- **MINOR**: New features, backwards compatible (1.0.0 → 1.1.0)
- **PATCH**: Bug fixes (1.0.0 → 1.0.1)
- **BUILD**: Internal build number, always increment (1, 2, 3...)

**Examples**:
- `1.0.0+1` - Initial release
- `1.0.1+2` - Bug fix release
- `1.1.0+3` - Added new feature (reminders)
- `1.1.1+4` - Fixed reminder bug
- `2.0.0+5` - Major redesign

---

## Checklist: Before Each Release

- [ ] Increment version number
- [ ] Update changelog
- [ ] Run all tests (`flutter test`)
- [ ] Test on physical devices
- [ ] Test release build (`flutter run --release`)
- [ ] Update screenshots if UI changed
- [ ] Update store description if features changed
- [ ] Build signed app bundle
- [ ] Test bundle with bundletool
- [ ] Upload to Play Console
- [ ] Write release notes
- [ ] Submit for review

---

## Summary

**Deployment Options**:

1. **Direct APK**: Fastest, best for testing
2. **Play Store**: Largest audience, requires review
3. **Firebase**: Best for beta testing
4. **Alternative Stores**: Smaller audiences, easier approval

**Key Takeaways**:
- **NEVER LOSE YOUR SIGNING KEY** - back it up!
- Test thoroughly before release
- Privacy policy is mandatory
- Play Store review takes 1-7 days
- Respond to user feedback

---

**Ready to Deploy!** Your app is now ready for the world.

**Next**: Monitor analytics, gather feedback, and plan updates!
