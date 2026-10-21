# Flutter Matter Packages

This repo collects every working Matter library published for Flutter/Dart on pub.dev in one place (surveyed 2026-10-21). [Matter](https://csa-iot.org/all-solutions/matter/) is the smart-home protocol. Each library comes with the native SDK pieces it needs, and all of them are pinned, checksummed and checked by `tool/verify.sh`.

Each library is a self-contained package under `packages/`. Native Matter SDK binaries that upstream scattered across JitPack, Maven Central and separate git repos are bundled inside the package that uses them. Add a package to your app and Gradle finds its native SDK: no JitPack, no extra repositories, no manual downloads. The one exception is Google's sign-in-gated Home SDK for iOS, covered in [docs/ios-setup.md](docs/ios-setup.md).

| Package | What it does | Android | iOS | Native SDK inside | License |
|---|---|---|---|---|---|
| [`flutter_matter`](packages/flutter_matter) 0.0.11 | Full Matter controller: BLE + on-network commissioning, Thread/Wi-Fi credentials, read/write/subscribe/invoke any cluster, TLV, ICD, open commissioning windows | ✅ minSdk 21 | ✅ device only; commissioning needs iOS 16.1+ | connectedhomeip Android AAR (bundled, was JitPack-only) + `ZGMatter.framework` | BSD-2-Clause (template text, see [CATALOG](CATALOG.md#licenses)) |
| [`google_matter_flutter`](packages/google_matter_flutter) 0.2.0 | Commissioning through Google Play services, then capability-based control (on/off, level, color, lock, covering, thermostat, sensors) | ✅ minSdk 27 | ❌ | Google's Matter Android Demo SDK (bundled) + Play services Home | MIT |
| [`matter_sharing`](packages/matter_sharing) 0.1.6 | Share a device you already control into Apple Home and Google Home | ✅ minSdk 27 | ✅ iOS 16.1+ | Play services Home; Apple Matter/MatterSupport/HomeKit (system) | MIT |
| [`matter_dcl`](packages/matter_dcl) 0.1.0 | Look up vendor and product names in the CSA Distributed Compliance Ledger | pure Dart | pure Dart | none | Apache-2.0 |

[CATALOG.md](CATALOG.md) lists everything that was surveyed. That includes the native SDKs, the Google and Apple SDKs that cannot be bundled, and the libraries that were rejected and why.

## Which one do I use?

- **Your own app is the Matter controller** (commission, then control devices directly, on Android and iOS): `flutter_matter`.
- **Android only, and you want the system commissioning UI** from Google Play services: `google_matter_flutter`.
- **Let users add your device to Apple Home / Google Home** as well: `matter_sharing`, alongside either controller.
- **Show a device's brand and model name** from its Vendor/Product IDs: `matter_dcl`. It works with any of the above.

> [!IMPORTANT]
> On Android, use **either** `flutter_matter` **or** `google_matter_flutter` in one app, never both. Both embed a connectedhomeip build with the same Java classes (`chip.devicecontroller.*`) and the same `libCHIPController.so`, so Gradle fails with duplicate class and duplicate native library errors. `matter_sharing` and `matter_dcl` combine with either one.

> [!WARNING]
> `google_matter_flutter` is built on Google's *Matter Android Demo SDK*, which Google labels "development and example purposes only, should not be used in a production application". Its native libraries are also not 16 KB page aligned, which Google Play requires for apps targeting Android 15+. For production on Android, `flutter_matter` is the only alternative here, and it is also early (0.0.x, one maintainer), so evaluate it carefully. The other route is the Google Home APIs, integrated natively because no Flutter wrapper for them exists yet (see [docs/native-sdks.md](docs/native-sdks.md)).

## Add a package to your app

Reference it straight from this repo with a git dependency, adding only the packages you need. Remember: on Android, `flutter_matter` *or* `google_matter_flutter`, not both.

```yaml
dependencies:
  flutter_matter:
    git:
      url: https://github.com/Mohammad-Majdy-Mohammad/Flutter-Matter-Packages.git
      ref: main
      path: packages/flutter_matter
  matter_sharing:
    git:
      url: https://github.com/Mohammad-Majdy-Mohammad/Flutter-Matter-Packages.git
      ref: main
      path: packages/matter_sharing
  matter_dcl:
    git:
      url: https://github.com/Mohammad-Majdy-Mohammad/Flutter-Matter-Packages.git
      ref: main
      path: packages/matter_dcl
  # google_matter_flutter: same pattern, path: packages/google_matter_flutter
```

Your app's `pubspec.lock` records the exact commit, so everyone on the team gets the same bytes until someone runs `flutter pub upgrade`. To freeze a version for good, replace `main` with a commit SHA.

If the repo is private, every developer and the CI machine need git access to it. You can also clone it next to your app and use `path: ../Flutter-Matter-Packages/packages/flutter_matter`.

Requirements by package:

| Package | Flutter / Dart |
|---|---|
| matter_sharing | Flutter 3.41+ |
| flutter_matter | Flutter 3.3+, Dart 3.3.3+ |
| google_matter_flutter | Flutter 3.0+ |
| matter_dcl | Dart 3.4+ |

Everything here was verified together with Flutter 3.47.7 / Dart 3.13.5.

Then do the platform setup. Every package needs some manifest, Info.plist or entitlement work:

- [docs/android-setup.md](docs/android-setup.md)
- [docs/ios-setup.md](docs/ios-setup.md)

## Repository layout

```
packages/            the libraries, ready to depend on (upstream sources + bundled native SDKs)
  flutter_matter/        android/maven/ holds the bundled connectedhomeip AAR
  google_matter_flutter/ android/maven/ holds the bundled Matter Android Demo SDK
  matter_sharing/
  matter_dcl/
patches/             the only changes made to upstream sources (Android repository wiring)
native/              inventory and checksums of every bundled native binary
docs/                platform setup, native SDK reference
tool/fetch_sources.sh  rebuilds packages/ from pinned, checksummed upstream sources
tool/verify.sh         checks binaries, analyzes and tests every package and a consumer app
CATALOG.md           the full survey: what exists, what was bundled, what was left out
```

## What was changed from upstream

Two Android `build.gradle` files, nothing else ([patches/](patches)):

- **flutter_matter**: upstream pulled its native SDK `com.github.Tan-yi-xiong:flutter_matter_android_prefixed:1.0.5` from JitPack. Each app had to add JitPack itself, and JitPack is often blocked or slow. The AAR now ships in `packages/flutter_matter/android/maven/`, and the plugin registers that folder for the app.
- **google_matter_flutter**: `com.google.matter:matter-android-demo-sdk:1.0` ships in `packages/google_matter_flutter/android/maven/`, so builds are pinned and work offline.

Both use Gradle `exclusiveContent`, so those artifact groups resolve only from the bundled copies, whatever repositories the app declares.

## Maintaining this repo

```sh
tool/fetch_sources.sh   # re-download pinned sources, verify SHA-256, re-apply patches
tool/verify.sh          # needs flutter on PATH; uses gradle too if installed
```

To upgrade a library, bump its pin in `tool/fetch_sources.sh` (version + SHA-256 from `https://pub.dev/api/packages/<name>`) and run both scripts. Update `native/checksums.sha256` if a bundled binary changed, and update the tables here and in CATALOG.md.

What `verify.sh` covers: binary checksums; `pub get`, `analyze` and the upstream unit tests of each package; a fresh app that depends on all four packages and analyzes clean; and offline Gradle resolution of both bundled AARs through an app's repositories. It does **not** build an APK or IPA. Run your app on a real device to confirm the native side. Matter commissioning needs real hardware or Google's Matter Virtual Device.
