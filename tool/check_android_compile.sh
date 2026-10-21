#!/usr/bin/env bash
# Compiles the plugins' Android Kotlin code against their bundled native Matter
# SDKs, the Flutter embedding of the installed Flutter SDK and the Android 14
# framework, without needing the Android SDK. Run it after upgrading a plugin or
# a bundled AAR: it catches a plugin that no longer matches its native SDK.
#
#   - flutter_matter: all of its Android code.
#   - google_matter_flutter: its Matter code (chip/). The other files need
#     Google Play services, which is only published on Google Maven.
#
# Two androidx classes flutter_matter uses (a real app gets them through the
# Flutter embedding) and google_matter_flutter's generated BuildConfig are
# replaced by compile-only stubs.
#
# Needs: flutter on PATH, gradle, javac, jar, unzip, curl. Downloads ~140 MB.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

ANDROID_ALL_VERSION="14-robolectric-10818077" # Android framework classes (API 34) on Maven Central
KOTLIN_VERSION="2.0.21"
COROUTINES_VERSION="1.7.3"
MAVEN_CENTRAL_URLS=(
  "https://repo1.maven.org/maven2"
  "https://maven-central.storage-download.googleapis.com/maven2"
)

download_maven_central() { # path-in-repo output
  local base
  for base in "${MAVEN_CENTRAL_URLS[@]}"; do
    if curl -fsSL --retry 2 --retry-delay 10 -o "$2" "$base/$1"; then
      return 0
    fi
    echo "warning: $base failed, trying the next mirror" >&2
  done
  echo "error: could not download $1 from Maven Central" >&2
  exit 1
}

FLUTTER_BIN="$(dirname "$(command -v flutter)")"
ENGINE_HASH="$(cat "$FLUTTER_BIN/internal/engine.version")"

echo "==> downloading Android framework and Flutter embedding jars"
SHARED="$WORK/shared"
mkdir -p "$SHARED"
download_maven_central \
  "org/robolectric/android-all/$ANDROID_ALL_VERSION/android-all-$ANDROID_ALL_VERSION.jar" \
  "$SHARED/android-all.jar"
curl -fsSL --retry 2 -o "$SHARED/flutter_embedding.jar" \
  "https://storage.googleapis.com/download.flutter.io/io/flutter/flutter_embedding_debug/1.0.0-$ENGINE_HASH/flutter_embedding_debug-1.0.0-$ENGINE_HASH.jar"

mkdir -p "$WORK/stubs/androidx/annotation" "$WORK/stubs/androidx/core/os" \
  "$WORK/stubs/com/google/google_matter_flutter/google_matter_flutter" "$WORK/stub-classes"
cat > "$WORK/stubs/androidx/annotation/NonNull.java" <<'EOF'
package androidx.annotation;
@java.lang.annotation.Retention(java.lang.annotation.RetentionPolicy.CLASS)
public @interface NonNull {}
EOF
cat > "$WORK/stubs/androidx/core/os/HandlerCompat.java" <<'EOF'
package androidx.core.os;
public final class HandlerCompat {
    public static android.os.Handler createAsync(android.os.Looper looper) { return null; }
}
EOF
cat > "$WORK/stubs/com/google/google_matter_flutter/google_matter_flutter/BuildConfig.java" <<'EOF'
package com.google.google_matter_flutter.google_matter_flutter;
public final class BuildConfig { public static final boolean DEBUG = true; }
EOF
javac -d "$WORK/stub-classes" -cp "$SHARED/android-all.jar" $(find "$WORK/stubs" -name '*.java')
(cd "$WORK/stub-classes" && jar cf "$SHARED/stubs.jar" .)

compile_plugin() { # name aar kotlin-source-dir
  local name=$1 aar=$2 sources=$3
  local dir="$WORK/$name"
  echo "==> compiling $name against $(basename "$aar")"
  mkdir -p "$dir/libs" "$dir/aar"
  unzip -q "$aar" -d "$dir/aar"
  cp "$dir"/aar/libs/*.jar "$SHARED"/*.jar "$dir/libs/"
  cat > "$dir/settings.gradle" <<EOF
pluginManagement { repositories { mavenCentral(); gradlePluginPortal() } }
rootProject.name = '$name-compile-check'
EOF
  cat > "$dir/build.gradle" <<EOF
plugins { id 'org.jetbrains.kotlin.jvm' version '$KOTLIN_VERSION' }
repositories { mavenCentral() }
java { sourceCompatibility = JavaVersion.VERSION_17; targetCompatibility = JavaVersion.VERSION_17 }
kotlin { compilerOptions { jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17 } }
sourceSets { main { kotlin.srcDirs = ['$sources'] } }
dependencies {
    implementation fileTree(dir: 'libs', include: ['*.jar'])
    implementation 'org.jetbrains.kotlinx:kotlinx-coroutines-core:$COROUTINES_VERSION'
}
EOF
  (cd "$dir" && gradle --quiet compileKotlin)
  echo "    $(find "$dir/build/classes" -name '*.class' | wc -l | tr -d ' ') classes compiled"
}

compile_plugin flutter_matter \
  "$ROOT/packages/flutter_matter/android/maven/com/github/Tan-yi-xiong/flutter_matter_android_prefixed/1.0.5/flutter_matter_android_prefixed-1.0.5.aar" \
  "$ROOT/packages/flutter_matter/android/src/main/kotlin"
compile_plugin google_matter_flutter \
  "$ROOT/packages/google_matter_flutter/android/maven/com/google/matter/matter-android-demo-sdk/1.0/matter-android-demo-sdk-1.0.aar" \
  "$ROOT/packages/google_matter_flutter/android/src/main/kotlin/com/google/google_matter_flutter/google_matter_flutter/chip"

echo "Android code compiles against the bundled native SDKs."
