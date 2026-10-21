#!/usr/bin/env bash
# Rebuilds packages/ from the pinned upstream sources below.
#
# Every download is pinned by version and checked against its SHA-256, so running
# this on a clean checkout reproduces the committed tree. To upgrade a library:
# bump its pin, run this script, fix any patch in patches/ that no longer applies,
# then run tool/verify.sh.
#
# Needs: bash, curl, tar, git, patch, and sha256sum or shasum.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PACKAGES_DIR="$ROOT/packages"
PATCHES_DIR="$ROOT/patches"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# Flutter/Dart packages: name, version, archive SHA-256 (https://pub.dev/api/packages/<name>).
PUB_PACKAGES=(
  "flutter_matter 0.0.11 92cbab5e4f73226dbfde6f8d4d94e1615c7b42969d20a1a77c5d9c1c09ab78b3"
  "google_matter_flutter 0.2.0 af5c89f00ca772d6722261d24a147a724ba2ddbfd49654f09f0b40c2f6cb6b57"
  "matter_sharing 0.1.6 1eda8050eb0b05aaf8e24c4599160ce26040730ef4c2231a7235db8404b3410f"
  "matter_dcl 0.1.0 beadcd5f8de6fd1d688c6a1951cbdf34f9a9a67bf4d08c3e61cd7f9f33bed0b7"
)

# Native Matter SDK for flutter_matter (Android). Upstream publishes it only on JitPack,
# which builds it from the release AAR committed at this tag.
PREFIXED_REPO="https://github.com/Tan-yi-xiong/flutter_matter_android_prefixed.git"
PREFIXED_VERSION="1.0.5"
PREFIXED_AAR_PATH="flutter_matter_android_prefixed/deploy/flutter_matter_android_prefixed-release.aar"
PREFIXED_AAR_SHA256="64dca2a6b74a00b99167e297d79581cb496c4cccd62595cfbf5a729ff396d034"

# Native Matter SDK for google_matter_flutter (Android), from Maven Central
# (Google's mirror of Maven Central is the fallback when Central rate-limits).
DEMO_SDK_PATH="com/google/matter/matter-android-demo-sdk/1.0"
MAVEN_CENTRAL_URLS=(
  "https://repo1.maven.org/maven2"
  "https://maven-central.storage-download.googleapis.com/maven2"
)
DEMO_SDK_AAR_SHA256="50f30bb0644d4857a44e300b2435e1ed73243ffbef3b0f41b148358efae518a4"
DEMO_SDK_POM_SHA256="2ad3a52594b7128a094fc1a2c88f2381f66994309688f3fcd905511f0378299b"

sha256() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | cut -d' ' -f1
  else
    shasum -a 256 "$1" | cut -d' ' -f1
  fi
}

check_sha256() { # file expected
  local actual
  actual="$(sha256 "$1")"
  if [[ "$actual" != "$2" ]]; then
    echo "error: checksum mismatch for $(basename "$1"): expected $2, got $actual" >&2
    exit 1
  fi
}

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

fetch_pub_package() { # name version sha256
  local name=$1 version=$2 sha=$3
  local archive="$WORK/$name-$version.tar.gz"
  echo "==> $name $version (pub.dev)"
  curl -fsSL --retry 4 --retry-delay 10 -o "$archive" "https://pub.dev/api/archives/$name-$version.tar.gz"
  check_sha256 "$archive" "$sha"
  rm -rf "${PACKAGES_DIR:?}/$name"
  mkdir -p "$PACKAGES_DIR/$name"
  tar -xzf "$archive" -C "$PACKAGES_DIR/$name"
}

# Lays out one AAR + POM as a Maven repository that Gradle can resolve offline.
install_maven_aar() { # repo_dir group artifact version aar pom
  local repo=$1 group=$2 artifact=$3 version=$4 aar=$5 pom=$6
  local dir="$repo/${group//.//}/$artifact/$version"
  mkdir -p "$dir"
  cp "$aar" "$dir/$artifact-$version.aar"
  cp "$pom" "$dir/$artifact-$version.pom"
}

fetch_flutter_matter_native() {
  local src="$WORK/flutter_matter_android_prefixed"
  local aar="$WORK/flutter_matter_android_prefixed.aar"
  local pom="$WORK/flutter_matter_android_prefixed.pom"
  echo "==> flutter_matter_android_prefixed $PREFIXED_VERSION (git tag)"
  # Blobless clone: only the one AAR is downloaded, not the repo's unstripped .so files.
  git clone --quiet --filter=blob:none --no-checkout --depth 1 \
    --branch "$PREFIXED_VERSION" "$PREFIXED_REPO" "$src"
  git -C "$src" show "HEAD:$PREFIXED_AAR_PATH" > "$aar"
  check_sha256 "$aar" "$PREFIXED_AAR_SHA256"
  cat > "$pom" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0">
  <modelVersion>4.0.0</modelVersion>
  <groupId>com.github.Tan-yi-xiong</groupId>
  <artifactId>flutter_matter_android_prefixed</artifactId>
  <version>$PREFIXED_VERSION</version>
  <packaging>aar</packaging>
  <description>Matter SDK (connectedhomeip) Android controller JARs and arm64-v8a/armeabi-v7a JNI libraries used by flutter_matter. Copied from $PREFIXED_REPO at tag $PREFIXED_VERSION.</description>
</project>
EOF
  install_maven_aar "$PACKAGES_DIR/flutter_matter/android/maven" \
    com.github.Tan-yi-xiong flutter_matter_android_prefixed "$PREFIXED_VERSION" "$aar" "$pom"
}

fetch_google_matter_flutter_native() {
  local aar="$WORK/matter-android-demo-sdk-1.0.aar"
  local pom="$WORK/matter-android-demo-sdk-1.0.pom"
  echo "==> matter-android-demo-sdk 1.0 (Maven Central)"
  download_maven_central "$DEMO_SDK_PATH/matter-android-demo-sdk-1.0.aar" "$aar"
  download_maven_central "$DEMO_SDK_PATH/matter-android-demo-sdk-1.0.pom" "$pom"
  check_sha256 "$aar" "$DEMO_SDK_AAR_SHA256"
  check_sha256 "$pom" "$DEMO_SDK_POM_SHA256"
  install_maven_aar "$PACKAGES_DIR/google_matter_flutter/android/maven" \
    com.google.matter matter-android-demo-sdk 1.0 "$aar" "$pom"
}

apply_patches() {
  local patch_file name
  for patch_file in "$PATCHES_DIR"/*.patch; do
    name="$(basename "$patch_file" .patch)"
    echo "==> patching $name"
    patch --quiet --forward -p1 -d "$PACKAGES_DIR/$name" < "$patch_file"
  done
}

mkdir -p "$PACKAGES_DIR"
for entry in "${PUB_PACKAGES[@]}"; do
  # shellcheck disable=SC2086
  fetch_pub_package $entry
done
fetch_flutter_matter_native
fetch_google_matter_flutter_native
apply_patches
echo "Done. Run tool/verify.sh next."
