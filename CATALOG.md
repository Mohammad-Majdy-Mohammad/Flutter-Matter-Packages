# Catalog of Matter libraries for Flutter

Surveyed 2026-10-21. Sources: pub.dev searches for "matter" in combination with commissioning, smart home, protocol, device, controller, iot, sdk, thread, chip, connectedhomeip, homekit, google home and `topic:matter`; reverse-dependency searches; and a web search for Matter Flutter plugins hosted only on GitHub, which turned up none beyond these.

## 1. Collected and ready to use (`packages/`)

| Package | Version | Upstream | pub.dev archive SHA-256 | Platforms | Native pieces it needs |
|---|---|---|---|---|---|
| `flutter_matter` | 0.0.11 (2026-09-08) | [Tan-yi-xiong/flutter_matter](https://github.com/Tan-yi-xiong/flutter_matter) | `92cbab5e…09ab78b3` | Android, iOS | connectedhomeip Android AAR (**bundled**), `ZGMatter.framework` (shipped in the package) |
| `google_matter_flutter` | 0.2.0 (2026-10-14) | [praharshbhatt/google_matter_flutter](https://github.com/praharshbhatt/google_matter_flutter) | `af5c89f0…f6cb6b57` | Android | Matter Android Demo SDK (**bundled**), `play-services-home` 16.0.0 (Google Maven, resolved by Gradle) |
| `matter_sharing` | 0.1.6 (2026-04-27) | [dustinchu/matter_sharing](https://github.com/dustinchu/matter_sharing) | `1eda8050…26040730` | Android, iOS | `play-services-home` 16.0.0 (Google Maven); iOS system `Matter`, `MatterSupport`, `HomeKit`; optional Google Home iOS SDK (sign-in download, see [docs/ios-setup.md](docs/ios-setup.md)) |
| `matter_dcl` | 0.1.0 (2026-10-15) | [firedanceio/matter_dcl](https://github.com/firedanceio/matter_dcl) | `beadcd5f…33bed0b7` | any (pure Dart) | none (calls the public CSA DCL REST API) |

Full checksums are in [tool/fetch_sources.sh](tool/fetch_sources.sh).

### Capabilities at a glance

| | flutter_matter | google_matter_flutter | matter_sharing | matter_dcl |
|---|---|---|---|---|
| Commission over BLE | ✅ (own BLE stack; custom GATT on Android) | ✅ via Play services UI | — | — |
| Commission on-network | ✅ | ✅ via Play services UI | — | — |
| Thread credentials | ✅ | handled by Play services | — | — |
| Read / write attributes | ✅ any cluster | ✅ common clusters, polling | — | — |
| Subscribe to attributes and events | ✅ | ❌ | — | — |
| Invoke commands | ✅ any cluster | ✅ on/off, level, color, lock, covering, thermostat | — | — |
| ICD (Matter 1.2+) | ✅ | ❌ | — | — |
| Unpair | ⚠️ in native code, not exposed in the 0.0.11 Dart API (its README says otherwise) | ❌ | — | — |
| Open a commissioning window (multi-admin) | ✅ `openPairingWindowWithPIN` | ✅ inside `shareDevice` | needs one opened first | — |
| Share to Apple Home | — | — | ✅ iOS | — |
| Share to Google Home or another app | — | ✅ `shareDevice` (Android ShareDevice API) | ✅ Android + iOS | — |
| Setup payload (QR / manual code) parsing | ✅ | — | — | — |
| Vendor / product name lookup | — | — | — | ✅ |

## 2. Native SDKs bundled inside the packages

| Binary | Lives in | Originally from | Why it was scattered |
|---|---|---|---|
| `flutter_matter_android_prefixed-1.0.5.aar`: connectedhomeip `CHIPController`, `CHIPClusters`, `CHIPInteractionModel`, `OnboardingPayload`, `AndroidPlatform`, TLV/JSON jars + `libCHIPController.so` for arm64-v8a, armeabi-v7a | `packages/flutter_matter/android/maven/` | git tag `1.0.5` of [Tan-yi-xiong/flutter_matter_android_prefixed](https://github.com/Tan-yi-xiong/flutter_matter_android_prefixed), served only through JitPack | separate repo + JitPack-only distribution |
| `matter-android-demo-sdk-1.0.aar`: connectedhomeip `CHIPController`, `AndroidPlatform`, `SetupPayloadParser` + `.so` for arm64-v8a, armeabi-v7a, x86, x86_64 | `packages/google_matter_flutter/android/maven/` | Maven Central, `com.google.matter:matter-android-demo-sdk:1.0` | separate Maven artifact |
| `ZGMatter.framework`: connectedhomeip Darwin framework with `ZGMTR` symbol prefix, arm64 iPhoneOS, min iOS 14.0 | `packages/flutter_matter/ios/frameworks/` | already inside the pub.dev package | — |

Sizes, checksums and licenses are listed in [native/README.md](native/README.md).

## 3. Native SDKs that are not bundled

These cannot be redistributed, sit behind a sign-in, or come with the OS. Details and integration steps are in [docs/native-sdks.md](docs/native-sdks.md).

| SDK | Used by | How you get it |
|---|---|---|
| Google Home Mobile SDK, `com.google.android.gms:play-services-home` 16.0.0 | google_matter_flutter, matter_sharing | Automatic: Gradle downloads it from Google Maven (`google()`). Proprietary, not redistributable. |
| Google Home APIs for Android | none of the packages (no Flutter wrapper exists) | Download after signing in to Google Home Developers |
| Google Home APIs for iOS (`GoogleHomeSDK.xcframework`, `GoogleHomeTypes.xcframework`) | matter_sharing (optional, for sharing to Google Home on iOS) | Download after signing in to Google Home Developers, then place it in your app's `ios/Frameworks/` |
| Apple `Matter.framework`, `MatterSupport.framework`, `HomeKit.framework` | matter_sharing, flutter_matter (extension) | Part of iOS 16.1+. Enable the capabilities in Xcode. |
| connectedhomeip (Matter SDK source) | origin of every CHIP binary above | [project-chip/connectedhomeip](https://github.com/project-chip/connectedhomeip). Build it yourself only if you need a newer Matter version than the bundled builds. |

## 4. Surveyed and left out

| Package | Why it is not collected |
|---|---|
| `matter` 1.0.3 (OpenIoTHub) | Placeholder only: the whole library is `int calculate() => 6 * 7`. |
| `flutter_tuya_sdk` 0.1.0, `tuya_flutter_ha_sdk` 0.0.1, `tuya_home_sdk_flutter` 0.3.3 | Wrappers around Tuya's proprietary cloud SDK. They expose Matter only for devices bound to a Tuya account and need Tuya AppKey/Secret and Tuya's native SDKs. `tuya_home_sdk_flutter` uses a commercial license. Tuya's Android SDK also embeds connectedhomeip (`chip.**`), so it clashes with `flutter_matter` / `google_matter_flutter`. Use one only if your product is built on Tuya. |
| `homekit` 1.0.0 | HomeKit Accessory Protocol in Dart, not Matter. |
| `esp_prov`, `flutter_esp_ble_prov`, `esp_rainmaker` | Espressif Wi-Fi/Thread provisioning and RainMaker cloud, not Matter commissioning. |
| `flutter_local_device_discovery` | Generic mDNS/SSDP discovery. It can browse `_matter._tcp`, but it is not a Matter library. |

## Licenses

| Component | License | Note |
|---|---|---|
| flutter_matter (Dart, Kotlin, ObjC sources) | BSD-2-Clause | The LICENSE file is the unfilled BSD-2 template (no copyright holder). Ask the author to fix it if this matters for your distribution. |
| flutter_matter Android native AAR | Apache-2.0 (connectedhomeip) | The wrapper repo has no LICENSE file of its own. |
| ZGMatter.framework | Apache-2.0 (connectedhomeip) | Built by Zengge (`com.zengge.ZGMatter`); no separate license shipped. |
| google_matter_flutter | MIT | |
| matter-android-demo-sdk | Apache-2.0 | "Development and example purposes only." |
| matter_sharing | MIT | |
| matter_dcl | Apache-2.0 | |

## Known issues

- **CHIP clash on Android**: `flutter_matter` and `google_matter_flutter` both contain `chip.devicecontroller.*` and `libCHIPController.so`. Use only one of them per app. The same applies to Tuya's SDK.
- **flutter_matter on iOS** works on devices only, with no simulator slice. Its podspec says iOS 11, but `ZGMatter.framework` needs iOS 14 and the Matter extension needs iOS 16.1.
- **flutter_matter on Android** ships only `arm64-v8a` and `armeabi-v7a` libraries, so it does not run on x86 emulators.
- **google_matter_flutter** reads by polling and has no subscriptions. Its demo SDK is not for production, and its native libraries are only 4 KB page aligned (checked with `readelf`). Google Play rejects that for apps targeting Android 15+, and it fails on 16 KB page size devices. The `flutter_matter` native libraries are 16 KB aligned.
- **matter_sharing on iOS with Google Home** needs CocoaPods plus hooks copied from the example Podfile. Flutter 3.47 defaults to Swift Package Manager, where the Google Home path reports `sdkNotLinked`. See [docs/ios-setup.md](docs/ios-setup.md). Apple Home sharing works with either. The podspec says version 0.1.0 while the package is 0.1.6 (cosmetic).

### Fixed in this repo

- **matter_sharing**: the Swift Package Manager copy of `GoogleHomeSharing.swift` was stale (wrong "cancelled" detection, no `alreadyCommissioned` error). It now matches the CocoaPods copy. See `patches/matter_sharing.patch`.
- **google_matter_flutter** and **matter_sharing** example apps: broken template widget tests replaced with passing smoke tests.
- **flutter_matter** native SDK: no longer depends on JitPack.

### Verified beyond the unit tests

- `flutter_matter`: all 45 native classes its Android code imports exist in the bundled AAR, and its whole Android plugin (38 classes) compiles against it (`tool/check_android_compile.sh`). On iOS, all 53 `ZGMTR*` symbols its Objective-C code uses are exported by or declared in `ZGMatter.framework` (checked with `llvm-nm`). The framework links only standard iOS system libraries.
- `google_matter_flutter`: all 16 native classes it imports exist in the bundled AAR, and its Matter code (70 classes) compiles against it.
