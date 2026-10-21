# iOS setup

A checklist per package. The upstream guides inside each package have screenshots and full details.

## Every app

- **Deployment target 16.1.** Apple's Matter commissioning UI (`MatterSupport`) needs it, and both `flutter_matter` and `matter_sharing` go through it. Set `platform :ios, '16.1'` in `ios/Podfile` and `IPHONEOS_DEPLOYMENT_TARGET = 16.1` on the Runner target.
- **Real device.** `flutter_matter`'s `ZGMatter.framework` has only an arm64 iPhoneOS slice, so simulator builds fail to link. Matter needs a real network anyway.
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

Follow [packages/matter_sharing/SETUP_IOS.md](../packages/matter_sharing/SETUP_IOS.md). In short:

- **Apple Home only**: Runner capabilities (App Groups, HomeKit, Matter Allow Setup Payload), the Info.plist local network + Bonjour keys, and the `AppDelegate.swift` snippet.
- **Google Home as well**:
  1. Download the **Google Home APIs iOS SDK**. It requires signing in at [developers.home.google.com/apis/ios/sdk](https://developers.home.google.com/apis/ios/sdk). Put `GoogleHomeSDK.xcframework` and `GoogleHomeTypes.xcframework` in **your app's** `ios/Frameworks/`, then run `pod install`. This repo cannot bundle them (sign-in download under Google's terms). Keep them in your app repo only if your license allows it.
  2. Add the Matter Extension target. `pod install` generates its `RequestHandler.swift`, `Info.plist` and entitlements in `ios/MatterExtension/`.
  3. Put your Team ID, iOS + Web OAuth client IDs and App Group in the `MatterSharing*` keys of **both** the Runner and extension `Info.plist`.

## google_matter_flutter

Android only. On iOS, every call fails with `MissingPluginException`. Guard calls with `Platform.isAndroid`.

## matter_dcl

Pure Dart, so there is no iOS setup.
