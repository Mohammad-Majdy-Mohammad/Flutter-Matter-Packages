#!/usr/bin/env bash
# Checks that the vendored packages are intact and usable:
#   1. the bundled native binaries match native/checksums.sha256, and
#      matter_sharing's CocoaPods and Swift Package Manager sources match
#   2. each package resolves, analyzes and passes its own tests
#   3. each plugin's example app resolves, analyzes and passes its tests
#   4. a fresh app that depends on all of them resolves and analyzes
#   5. if gradle is installed, the bundled Maven repos resolve offline through
#      an app's repositories, the way a Flutter Android build resolves them
#
# tool/check_android_compile.sh is the slower companion that compiles the
# plugins' Kotlin code against the bundled native SDKs.
#
# Works on a temporary copy of packages/, because the flutter tool rewrites
# analysis_options.yaml files in place.
#
# Needs: flutter on PATH (3.41 or newer). Optional: gradle.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

FLUTTER_PACKAGES=(flutter_matter google_matter_flutter matter_sharing)
DART_PACKAGES=(matter_dcl)

echo "==> native binaries"
cd "$ROOT"
if command -v sha256sum >/dev/null 2>&1; then
  sha256sum --quiet -c native/checksums.sha256
else
  shasum -a 256 --quiet -c native/checksums.sha256
fi

echo "==> matter_sharing iOS sources"
# Flutter builds the Classes/ copy with CocoaPods and the Sources/ copy with
# Swift Package Manager (the default). They must not drift apart again.
diff -r packages/matter_sharing/ios/Classes packages/matter_sharing/ios/matter_sharing/Sources/matter_sharing

cp -R "$ROOT/packages" "$WORK/packages"

check_package() { # name tool
  local name=$1 tool=$2
  echo "==> $name"
  cd "$WORK/packages/$name"
  "$tool" pub get >/dev/null
  # Only the library and its tests: the upstream example apps are reference material.
  local targets=(lib)
  [[ -d test ]] && targets+=(test)
  # Upstream lint warnings are not ours to fix; errors still fail the check.
  local flags=(--no-fatal-warnings)
  [[ "$tool" == flutter ]] && flags+=(--no-fatal-infos)
  "$tool" analyze "${flags[@]}" "${targets[@]}"
  if [[ -d test ]]; then
    "$tool" test
  fi
}

for name in "${FLUTTER_PACKAGES[@]}"; do check_package "$name" flutter; done
for name in "${DART_PACKAGES[@]}"; do check_package "$name" dart; done

for name in "${FLUTTER_PACKAGES[@]}"; do
  echo "==> $name example app"
  cd "$WORK/packages/$name/example"
  flutter pub get >/dev/null
  flutter analyze --no-fatal-infos --no-fatal-warnings
  if [[ -d test ]]; then
    flutter test test
  fi
done

echo "==> consumer app using every package"
cd "$WORK"
flutter create --org com.example --project-name matter_consumer --platforms android,ios consumer >/dev/null
cd consumer
rm -rf test
for name in "${FLUTTER_PACKAGES[@]}" "${DART_PACKAGES[@]}"; do
  flutter pub add "$name" --path "$WORK/packages/$name" >/dev/null
done
cat > lib/main.dart <<'EOF'
import 'package:flutter/material.dart';
import 'package:flutter_matter/flutter_matter.dart';
import 'package:google_matter_flutter/google_matter_flutter.dart';
import 'package:matter_dcl/matter_dcl.dart';
import 'package:matter_sharing/matter_sharing.dart';

void main() {
  // One symbol from each package, so the analyzer checks they resolve together.
  debugPrint('${OnboardingPayloadParser()} ${GoogleMatterFlutter()} ${MatterDcl()}');
  debugPrint('${MatterSharing.shareToAppleHome}');
  runApp(const SizedBox());
}
EOF
flutter analyze

if ! command -v gradle >/dev/null 2>&1; then
  echo "==> gradle not found, skipping the bundled Maven repo check"
  echo "All checks passed."
  exit 0
fi

echo "==> bundled Maven repos (gradle --offline)"
# Builds a stand-in for each plugin's android/build.gradle from its real repository block,
# without the Android Gradle Plugin, and resolves the bundled AARs from an app module.
GRADLE_DIR="$WORK/gradle-check"
mkdir -p "$GRADLE_DIR/app"
make_stand_in() { # name coordinates
  local android_dir="$WORK/packages/$1/android"
  {
    echo "apply plugin: 'java-library'"
    tr -d '\r' < "$android_dir/build.gradle" |
      sed -n "/^def bundledMavenRepo/,/^apply plugin: 'com.android.library'/p" |
      grep -v "^apply plugin"
    echo "dependencies { implementation('$2') { transitive = false } }"
  } > "$android_dir/verify-repos.gradle"
}
make_stand_in flutter_matter com.github.Tan-yi-xiong:flutter_matter_android_prefixed:1.0.5
make_stand_in google_matter_flutter com.google.matter:matter-android-demo-sdk:1.0

cat > "$GRADLE_DIR/settings.gradle" <<EOF
rootProject.name = 'repo-check'
include ':app', ':flutter_matter', ':google_matter_flutter'
project(':flutter_matter').projectDir = file('$WORK/packages/flutter_matter/android')
project(':flutter_matter').buildFileName = 'verify-repos.gradle'
project(':google_matter_flutter').projectDir = file('$WORK/packages/google_matter_flutter/android')
project(':google_matter_flutter').buildFileName = 'verify-repos.gradle'
EOF
cat > "$GRADLE_DIR/build.gradle" <<'EOF'
// Like a Flutter app's android/build.gradle: public repositories come first.
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}
subprojects {
    if (project.name != 'app') project.evaluationDependsOn(':app')
}
EOF
cat > "$GRADLE_DIR/app/build.gradle" <<'EOF'
apply plugin: 'java'
dependencies {
    implementation project(':flutter_matter')
    implementation project(':google_matter_flutter')
}
tasks.register('checkBundledAars') {
    def classpath = configurations.runtimeClasspath
    doLast {
        def names = classpath.files*.name
        ['flutter_matter_android_prefixed-1.0.5.aar', 'matter-android-demo-sdk-1.0.aar'].each {
            if (!names.contains(it)) throw new GradleException("$it did not resolve; got $names")
            println "resolved $it"
        }
    }
}
EOF
(cd "$GRADLE_DIR" && gradle --offline --quiet :app:checkBundledAars)

echo "All checks passed."
