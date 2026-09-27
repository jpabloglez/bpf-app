# Play Store Release Checklist

The short, authoritative path from this repo to a Google Play upload. The
longer background material lives in [04-deployment-guide.md](04-deployment-guide.md).

| Setting | Value |
|---|---|
| Application ID | `io.github.jpabloglez.bptracker` (permanent once uploaded) |
| minSdk | 24 (Android 7.0) |
| targetSdk / compileSdk | 36 (Android 16), Play's requirement from Aug 31, 2026 |
| Version | `version:` in `pubspec.yaml` (`name+code`) |
| Permissions | none |
| Native libs | 16 KB page aligned (required for targetSdk ≥ 35) |

## 1. Create the upload key (once)

```bash
keytool -genkeypair -v -keystore ~/bp-tracker-upload.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Store the `.jks` file and both passwords in a password manager. With Play App
Signing (the default for new apps) Google holds the real app-signing key. If
the upload key is lost, you can ask Google to reset it, but you can't upload
until they do.

## 2. Point Gradle at it

Create `android/key.properties`. It's gitignored; never commit it.

```properties
storePassword=<keystore password>
keyPassword=<key password>
keyAlias=upload
# Absolute path, or relative to android/app/
storeFile=/home/<you>/bp-tracker-upload.jks
```

Without this file, `flutter build appbundle` **fails on purpose** so a
debug-signed bundle can never reach the Play Console.

## 3. Verify and build

```bash
flutter pub get
flutter analyze            # expect: No issues found!
flutter test               # expect: All tests passed!
flutter build appbundle --release --obfuscate --split-debug-info=build/symbols
```

Upload `build/app/outputs/bundle/release/app-release.aab`. Keep
`build/symbols/` for this version to symbolicate crash stack traces
(`flutter symbolize`).

For every later upload, bump the build number in `pubspec.yaml`
(`1.1.0+2` → `1.1.1+3`). Play rejects a versionCode it has already seen.

## 4. Play Console: one-time setup

**Store listing.** Assets are in [`store/`](../store/):
- App icon: `store/play_store_icon_512.png`
- Feature graphic: `store/feature_graphic_1024x500.png`
- Phone screenshots: at least 2, taken from a device or emulator
- Suggested text: [`store/listing.md`](../store/listing.md)

**Privacy policy.** Required for health apps. Publish
[`PRIVACY_POLICY.md`](../PRIVACY_POLICY.md) at a public URL (for example
GitHub Pages or a public gist) and paste that URL into
*Policy → App content → Privacy policy*.

**App content declarations:**

| Declaration | Answer |
|---|---|
| Health apps | Category: *Health & fitness → personal health tracking (vitals)*. Not a medical device. |
| Data safety → data collected | **None.** Nothing is transmitted off the device. |
| Data safety → data shared | **None.** The user-initiated PDF share is exempt (user action, user-chosen destination). |
| Data safety → encrypted in transit | Not applicable (no network) |
| Data safety → deletion | Users delete readings in the app; uninstalling removes all data |
| Ads | No |
| Target audience | 18+ |
| Content rating | Complete the questionnaire (no objectionable content) |
| Government app / Financial features | No |

**Testing track.** New *personal* developer accounts must run a closed test
with at least 12 testers for 14 days before production access is granted.
Upload the first bundle to *Testing → Closed testing*.

## 5. Pre-launch report

After upload, check *Release → Pre-launch report*. It installs the bundle on
real devices across Android versions and flags crashes, accessibility, and
security issues.
