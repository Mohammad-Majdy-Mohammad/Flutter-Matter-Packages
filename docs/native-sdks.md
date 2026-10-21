# Native Matter SDKs (reference)

These are the native SDKs underneath the Flutter packages, plus the ones no Flutter package wraps yet. Use this page when a package is missing something and you have to go native. In Flutter, that means writing a method-channel plugin.

## connectedhomeip (the Matter SDK)

- Source: https://github.com/project-chip/connectedhomeip (Apache-2.0). This is the reference implementation of Matter, maintained by the CSA.
- Every CHIP binary in this repo was built from it: both Android AARs and `ZGMatter.framework` (see [native/README.md](../native/README.md)).
- It ships the Android controller (`chip.devicecontroller.ChipDeviceController`, JNI `libCHIPController.so`), the Darwin `Matter.framework` (`MTR*` APIs, which Apple ships with iOS) and `chip-tool` for the command line.
- Rebuild it yourself when you need a newer Matter spec revision or clusters the bundled builds lack, security fixes, or 16 KB-aligned libraries for `google_matter_flutter`. Android build guide: `docs/platforms/android/android_building.md` in that repo. Replace the AAR in the relevant `android/maven/` folder under the same coordinates, then update `native/checksums.sha256`.

## Google

| SDK | What it gives you | How to get it | Wrapped by |
|---|---|---|---|
| Google Home Mobile SDK, `com.google.android.gms:play-services-home` | Play services Matter **Commissioning API** (system UI, commissions into Google's fabric and hands the device to your app's `CommissioningService`) and **Share Device API** (multi-admin) | Gradle, from Google Maven. Needs Play services with the Home module on the phone. [Docs](https://developers.home.google.com/matter/apis/home) | google_matter_flutter, matter_sharing |
| Matter Android Demo SDK, `com.google.matter:matter-android-demo-sdk:1.0` | connectedhomeip controller libraries packaged by Google for its sample app; dev and test only | Maven Central; **bundled** in `packages/google_matter_flutter/android/maven` | google_matter_flutter |
| Google Home APIs, Android | Device & Structure, Automation and Commissioning APIs against the user's Google Home | Sign-in download, hosted locally. [Docs](https://developers.home.google.com/apis/android/sdk), sample `google-home/google-home-api-sample-app-android` | none yet |
| Google Home APIs, iOS (`GoogleHomeSDK`, `GoogleHomeTypes`) | Same, for iOS | Sign-in download. [Docs](https://developers.home.google.com/apis/ios/sdk), sample `google-home/google-home-api-sample-app-ios` | matter_sharing (Google Home sharing on iOS) |
| Google Home Sample App for Matter | Reference Android controller app (commissioning, sharing, cluster control) | https://github.com/google-home/sample-apps-for-matter-android | basis of google_matter_flutter's Android code |
| Matter Virtual Device | Desktop emulator of Matter devices, for testing without hardware | https://developers.home.google.com/matter/tools/virtual-device | — |

## Apple

All three come with iOS 16.1+. Nothing to download; enable the capabilities in Xcode.

| Framework | What it gives you | Used by |
|---|---|---|
| `MatterSupport` | `MatterAddDeviceRequest`: the system "Add Accessory" UI plus your *Matter Accessory Setup Extension* | flutter_matter, matter_sharing |
| `Matter` | Apple's build of the connectedhomeip Darwin framework (`MTR*`) | matter_sharing (payload parsing); flutter_matter uses its own prefixed copy, `ZGMatter` |
| `HomeKit` | `HMAccessorySetupManager`, to add a Matter accessory to Apple Home | matter_sharing |

## CSA

- **Distributed Compliance Ledger (DCL)**: the public registry of Vendor IDs, products and certification records. Wrapped by `matter_dcl`. Mainnet `https://on.dcl.csa-iot.org`, testnet `https://on.test-net.dcl.csa-iot.org`.
- Test Vendor IDs `0xFFF1`–`0xFFF4` are reserved for development and appear in the sample payloads.
