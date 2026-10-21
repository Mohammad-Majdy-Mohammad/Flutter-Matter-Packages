# Android setup

A checklist per package. The upstream READMEs inside each package have the full details. This page adds what you need to know when you use these packages from this repo.

## Every app

- **Pick one CHIP controller plugin.** `flutter_matter` and `google_matter_flutter` cannot be in the same APK (duplicate `chip.devicecontroller.*` classes and `libCHIPController.so`).
- **minSdk**: `flutter_matter` needs 21. `google_matter_flutter` and `matter_sharing` need **27**. Set it in `android/app/build.gradle(.kts)`:
  ```kotlin
  defaultConfig {
      minSdk = 27
  }
  ```
- **Network permissions in the main manifest.** Flutter's template adds `INTERNET` only to the debug and profile manifests, so a release build without it cannot reach Matter devices (or the DCL). Add to `android/app/src/main/AndroidManifest.xml`:
  ```xml
  <uses-permission android:name="android.permission.INTERNET" />
  <!-- flutter_matter / google_matter_flutter: mDNS discovery of Matter devices -->
  <uses-permission android:name="android.permission.CHANGE_WIFI_MULTICAST_STATE" />
  ```
  Both controller example apps declare these. `flutter_matter`'s README leaves them out.
- **No extra repositories.** Do not add JitPack. The bundled native SDKs register themselves (see [native/README.md](../native/README.md)). If your `settings.gradle` uses `FAIL_ON_PROJECT_REPOS`, follow the note there.
- **Test on a real phone.** Matter needs BLE and mDNS on a real network. `flutter_matter` also ships only ARM native libraries, so x86 emulators cannot load it.

## flutter_matter

1. Add the Bluetooth / Wi-Fi permissions from the "Android" section of [packages/flutter_matter/README.md](../packages/flutter_matter/README.md) to `android/app/src/main/AndroidManifest.xml`, plus the two network permissions above. `packages/flutter_matter/example/android/app/src/main/AndroidManifest.xml` has the complete working set.
2. Request the runtime permissions (`BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT`, and location on Android 11 and lower) before BLE commissioning. The plugin does not request them for you. Its example app uses `permission_handler`.
3. To scan Matter QR codes, the example uses `mobile_scanner`. Parse the result with `OnboardingPayloadParser().parseQrCode(...)`.
4. Release builds: the plugin ships consumer ProGuard rules (`android/proguard-rules.pro`). Nothing extra to add.

Reference app: `packages/flutter_matter/example`.

## google_matter_flutter

1. In `AndroidManifest.xml`, inside your launcher `<activity>`:
   ```xml
   <intent-filter>
       <action android:name="com.google.android.gms.home.matter.ACTION_COMMISSION_DEVICE" />
       <category android:name="android.intent.category.DEFAULT" />
   </intent-filter>
   ```
   and inside `<application>`:
   ```xml
   <service
       android:name="com.google.google_matter_flutter.google_matter_flutter.AppCommissioningService"
       android:exported="true" />
   ```
2. Add the two network permissions above. The package README does not list any permissions; `packages/google_matter_flutter/example/android/app/src/main/AndroidManifest.xml` shows what the example declares.
3. The phone needs Google Play services with the Home module. Gradle resolves `play-services-home` from Google Maven automatically.
4. With no hardware, test against Google's [Matter Virtual Device](https://developers.home.google.com/matter/tools/virtual-device). The steps are in the package README.

Reference app: `packages/google_matter_flutter/example`.

## matter_sharing

Follow [packages/matter_sharing/SETUP_ANDROID.md](../packages/matter_sharing/SETUP_ANDROID.md):

1. Add the `CommissioningActivity` entry to `AndroidManifest.xml`.
2. In the Google Cloud Console, enable the Google Home API. In the [Google Home Developer Console](https://console.home.google.com), create a Matter integration with your CSA Vendor ID.
3. Before calling `MatterSharing.shareToGoogleHome`, the device must have an open commissioning window. With `flutter_matter`, open one with `ChipDeviceController.openPairingWindowWithPIN(...)`.

The plugin already declares `play-services-home`, so adding it to your app module is optional.

## matter_dcl

Pure Dart. The only Android requirement is the `INTERNET` permission from "Every app" above.
