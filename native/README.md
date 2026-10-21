# Bundled native binaries

These are all the prebuilt native files in this repo, where each came from, and how it is wired into a build. `checksums.sha256` pins every one of them, and `tool/verify.sh` checks the files against it.

| File | Size | Contents | Source | License |
|---|---|---|---|---|
| `packages/flutter_matter/android/maven/com/github/Tan-yi-xiong/flutter_matter_android_prefixed/1.0.5/flutter_matter_android_prefixed-1.0.5.aar` | 12.8 MB | connectedhomeip Android controller: `CHIPController.jar`, `CHIPClusters.jar`, `CHIPClusterID.jar`, `CHIPInteractionModel.jar`, `OnboardingPayload.jar`, `AndroidPlatform.jar`, `libMatterTlv.jar`, `libMatterJson.jar`; `libCHIPController.so` + `libc++_shared.so` for arm64-v8a and armeabi-v7a; ELF segments 16 KB aligned | `flutter_matter_android_prefixed/deploy/flutter_matter_android_prefixed-release.aar` at git tag `1.0.5` of https://github.com/Tan-yi-xiong/flutter_matter_android_prefixed. This is the same file JitPack serves for `com.github.Tan-yi-xiong:flutter_matter_android_prefixed:1.0.5`. | Apache-2.0 (connectedhomeip); the wrapper repo has no LICENSE |
| `…/flutter_matter_android_prefixed-1.0.5.pom` | <1 KB | Minimal POM (no dependencies), written by `tool/fetch_sources.sh` | generated | — |
| `packages/google_matter_flutter/android/maven/com/google/matter/matter-android-demo-sdk/1.0/matter-android-demo-sdk-1.0.aar` | 21.0 MB | connectedhomeip Android CHIP Tool libraries: `CHIPController.jar`, `AndroidPlatform.jar`, `SetupPayloadParser.jar`; `libCHIPController.so`, `libSetupPayloadParser.so`, `libc++_shared.so` for arm64-v8a, armeabi-v7a, x86, x86_64; ELF segments only 4 KB aligned, so **not** compatible with 16 KB page size devices | https://repo1.maven.org/maven2/com/google/matter/matter-android-demo-sdk/1.0/ | Apache-2.0. Google: "development and example purposes only" |
| `…/matter-android-demo-sdk-1.0.pom` | 3 KB | Upstream POM. Its runtime dependencies (kotlin-stdlib-jdk8, core-ktx, appcompat, material) come from Google Maven / Maven Central as usual. | same | — |
| `packages/flutter_matter/ios/frameworks/ZGMatter.framework/` | 30.4 MB binary + headers | connectedhomeip Darwin framework with every symbol prefixed `ZGMTR`, so it does not clash with Apple's own `Matter.framework`. Bundle id `com.zengge.ZGMatter`, arm64 iPhoneOS only, min iOS 14.0, built with the iOS 18.5 SDK. | shipped inside the `flutter_matter` 0.0.11 pub.dev package, vendored by its podspec | Apache-2.0 (connectedhomeip); no separate license |

## How the Android AARs reach your build

Each plugin's `android/build.gradle` (see `patches/`) registers its `android/maven` folder on every Gradle project with `exclusiveContent`:

```groovy
def bundledMavenRepo = new File(projectDir, 'maven')

rootProject.allprojects {
    repositories {
        exclusiveContent {
            forRepository { maven { url bundledMavenRepo.toURI() } }
            filter { includeGroup 'com.github.Tan-yi-xiong' }   // or 'com.google.matter'
        }
    }
}
```

It has to be every project, not only the plugin's own. The app module resolves its plugins' dependencies with its *own* repositories. `exclusiveContent` means those groups are looked up only in the bundled folder, never on JitPack or Maven Central.

This works with the standard Flutter Android template. If your app sets `dependencyResolutionManagement { repositoriesMode = FAIL_ON_PROJECT_REPOS }` in `settings.gradle`, add the same `exclusiveContent` blocks there instead. Point them at `<pub-cache or checkout>/packages/<plugin>/android/maven`.

## Why there are no unstripped `.so` files

The upstream `flutter_matter_android_prefixed` repo also commits unstripped `libCHIPController.so` files (85 to 90 MB each) for debugging. Only the release AAR is bundled here, because it is what JitPack served and what apps ship. For native symbolication, fetch the unstripped libraries from that repo at tag `1.0.5`.
