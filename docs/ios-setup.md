# iOS setup

A checklist per package. The upstream guides inside each package have screenshots and full details. Where this page and an upstream guide disagree, follow this page: it was checked against Flutter 3.47.

## Every app

- **Deployment target 16.1.** Apple's Matter commissioning UI (`MatterSupport`) needs it, and both `flutter_matter` and `matter_sharing` go through it. Set `platform :ios, '16.1'` in `ios/Podfile` and `IPHONEOS_DEPLOYMENT_TARGET = 16.1` on the Runner target.
- **Real device.** `flutter_matter`'s `ZGMatter.framework` has only an arm64 iPhoneOS slice, so simulator builds fail to link. Matter needs a real network anyway.
- **Swift Package Manager vs CocoaPods.** Flutter 3.47 builds iOS plugins with Swift Package Manager by default and falls back to CocoaPods for plugins without a `Package.swift`.
  - `flutter_matter` is CocoaPods-only. Flutter handles that automatically, so there is nothing to do.
  - `matter_sharing` supports both. Apple Home sharing works with either. **Google Home sharing on iOS needs CocoaPods** (see below).
- **Using both `flutter_matter` and `matter_sharing`?** Each asks for a *Matter Accessory Setup Extension* whose `RequestHandler.swift` overrides the same `MatterAddDeviceExtensionRequestHandler` methods. `flutter_matter`'s handler hands the payload to the app through the App Group; `matter_sharing`'s commissions into Google Home. Plan one extension and one App Group that combine both behaviors, and test both flows.
- `ZGMatter.framework` prefixes every symbol with `ZGMTR`, so `flutter_matter` coexists with Apple's `Matter.framework` and with `matter_sharing`.

## flutter_matter

How it commissions: `request.perform()` shows Apple's "Add Accessory" UI. The extension stores the onboarding payload in the shared App Group, and the plugin then commissions the device into *your* fabric with `ZGMatter.framework`.

1. Add `NSBluetoothAlwaysUsageDescription`, `NSBonjourServices` (`_meshcop._udp`, `_matter._tcp`, `_matterc._udp`, `_matterd._udp`), `NSCameraUsageDescription` and `NSLocalNetworkUsageDescription` to `Runner/Info.plist`.
2. Add a **Matter Accessory Setup Extension** target.
3. On **both** targets, add the **App Groups** capability (same group) and **Matter Allow Setup Payload**.
4. On **both** targets, add the Info.plist key `AppGroupId` set to that group.
5. Copy `packages/flutter_matter/example/ios/MatterExt/RequestHandler.swift` into the extension.

Reference: [packages/flutter_matter/README.md](../packages/flutter_matter/README.md) (iOS section) and `packages/flutter_matter/example/ios`.

## matter_sharing

### Apple Home only

Works with Swift Package Manager or CocoaPods. Follow steps 1–3 of [packages/matter_sharing/SETUP_IOS.md](../packages/matter_sharing/SETUP_IOS.md):
- Runner capabilities: App Groups, HomeKit, Matter Allow Setup Payload.
- The Info.plist local network + Bonjour keys.
- The `AppDelegate.swift` snippet.

### Google Home as well

The plugin finds Google's SDK through Podfile hooks, so this path needs CocoaPods.

1. **Switch the app to CocoaPods** in your app's `pubspec.yaml`:
   ```yaml
   flutter:
     config:
       enable-swift-package-manager: false
   ```
2. **Download the Google Home APIs iOS SDK.** It requires signing in at [developers.home.google.com/apis/ios/sdk](https://developers.home.google.com/apis/ios/sdk). Put `GoogleHomeSDK.xcframework` and `GoogleHomeTypes.xcframework` in **your app's** `ios/Frameworks/`. This repo cannot bundle them (sign-in download under Google's terms). Keep them in your app repo only if your license allows it.
3. **Add the App Group to `Runner.entitlements` first**, then create the **MatterExtension** target in Xcode (*Matter Accessory Setup Extension*, product name `MatterExtension`).
4. **Copy two parts of `packages/matter_sharing/example/ios/Podfile` into your `ios/Podfile`:**
   - the `target 'MatterExtension' do … end` block;
   - everything inside its `post_install do |installer| … end` block.

   These hooks embed `GoogleHomeSDK`, add it to the search paths of the plugin, Runner and extension, and create `ios/MatterExtension/RequestHandler.swift`, `Info.plist` and `MatterExtension.entitlements` with your App Group filled in. Upstream's guide says `pod install` creates those files on its own. It only does so with these hooks in your Podfile.
5. Run `flutter pub get`, then `cd ios && pod install`. Add the three generated files to the MatterExtension target only, as in step 4-3 of SETUP_IOS.md.
6. Put your Team ID, iOS + Web OAuth client IDs and App Group in the `MatterSharing*` keys of **both** the Runner and extension `Info.plist` (step 4-4 and step 5 of SETUP_IOS.md).

Without the hooks the app still builds, but `MatterSharing.shareToGoogleHome` fails on iOS with `MatterSharingErrorCode.sdkNotLinked`.

## google_matter_flutter

Android only. On iOS, every call fails with `MissingPluginException`. Guard calls with `Platform.isAndroid`.

## matter_dcl

Pure Dart, so there is no iOS setup.
