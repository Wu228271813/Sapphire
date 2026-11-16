#!/bin/bash
# Notch-only prototype. Does not build the full Sapphire scheme, register a
# helper, or copy anything to /Applications.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="${SAPPHIRE_LOCAL_UI_TEST_ROOT:-$HOME/SapphireFloatingCapsuleTest}"
DERIVED="$DEST/DerivedDataUI"
ORIG="/Applications/Sapphire.app"
APP="$DERIVED/Build/Products/Release/SapphireFloatingCapsuleTest.app"

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "xcodebuild is not on this machine. This script has to run on the Mac." >&2
  exit 1
fi

ORIG_STAMP=""
if [[ -d "$ORIG" ]]; then
  ORIG_STAMP="$(stat -f %m "$ORIG")"
  echo "Found $ORIG. This build will not replace it."
fi

mkdir -p "$DERIVED"
cd "$ROOT"

# Release is the app to open. It does not inject the debugger, a debug dylib, or
# get-task-allow. Ad-hoc signing does not keep a hardened-runtime flag; this
# script does not turn off OS protections. Tests stay on the Debug configuration.
xcodebuild \
  -project FloatingCapsuleTest/FloatingCapsuleTest.xcodeproj \
  -scheme FloatingCapsuleTest \
  -configuration Release \
  -destination "platform=macOS,arch=arm64" \
  -derivedDataPath "$DERIVED" \
  build

xcodebuild \
  -project FloatingCapsuleTest/FloatingCapsuleTest.xcodeproj \
  -scheme FloatingCapsuleTest \
  -configuration Debug \
  -destination "platform=macOS,arch=arm64" \
  -derivedDataPath "$DERIVED" \
  test

if [[ -n "$ORIG_STAMP" ]]; then
  NOW="$(stat -f %m "$ORIG")"
  if [[ "$NOW" != "$ORIG_STAMP" ]]; then
    echo "error: $ORIG changed while this script ran. Do not continue." >&2
    exit 1
  fi
  echo "Unchanged: $ORIG"
fi

if [[ ! -d "$APP" ]]; then
  echo "error: expected $APP" >&2
  exit 1
fi

IDENTIFIER="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$APP/Contents/Info.plist")"
if [[ "$IDENTIFIER" != "com.local.sapphire.floatingcapsule.test" ]]; then
  echo "error: bundle id is $IDENTIFIER" >&2
  exit 1
fi

if /usr/libexec/PlistBuddy -c 'Print :CFBundleURLTypes' "$APP/Contents/Info.plist" >/dev/null 2>&1; then
  echo "error: this prototype must not advertise a URL scheme" >&2
  exit 1
fi

echo "Built: $APP"
echo "Bundle id: $IDENTIFIER"
echo "Launch with: open \"$APP\""
echo "Quit from the panel or with Command-Q. That closes only this test."
echo "Do not copy the result to /Applications."
