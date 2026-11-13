#!/usr/bin/env bash
# Idempotent Android SDK bootstrap for Forgejo CI jobs (cached when ANDROID_HOME is a persistent mount).
set -euxo pipefail
: "${ANDROID_HOME:?}"
mkdir -p "$ANDROID_HOME" /root/.gradle
if [ ! -x "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" ]; then
  mkdir -p "$ANDROID_HOME/cmdline-tools"
  curl -fSL --retry 3 --connect-timeout 30 -o /tmp/cmdtools.zip https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip
  rm -rf /tmp/cmdtools
  unzip -q /tmp/cmdtools.zip -d /tmp/cmdtools
  rm -rf "$ANDROID_HOME/cmdline-tools/latest"
  mv /tmp/cmdtools/cmdline-tools "$ANDROID_HOME/cmdline-tools/latest"
fi
SDKM="$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager"
"$SDKM" --version
yes | "$SDKM" --licenses || echo "licenses exit=$?"
V=plugins/src/main/kotlin/Versions.kt
COMPILE=$(grep -E "const val COMPILE_SDK" $V | grep -oE "[0-9]+" | head -1)
BT=$(grep -E "BUILD_TOOLS_VERSION =" $V | grep -oE "[0-9]+(\.[0-9]+)+" | head -1)
echo "compileSdk=$COMPILE buildTools=$BT"
test -n "$COMPILE" && test -n "$BT"
yes | "$SDKM" "platforms;android-$COMPILE" "build-tools;$BT" "platform-tools" || test -d "$ANDROID_HOME/platforms/android-$COMPILE"
ls "$ANDROID_HOME/platforms" "$ANDROID_HOME/build-tools"
