#!/bin/bash
# Build the floating-capsule UI test app on this Mac.
# Ad-hoc signature, separate name and bundle id, separate preferences.
# Does not copy anything to /Applications and does not use the team identity.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="${SAPPHIRE_LOCAL_UI_TEST_ROOT:-$HOME/SapphireFloatingCapsuleTest}"
DERIVED="$DEST/DerivedData"
ORIG="/Applications/Sapphire.app"
APP="$DERIVED/Build/Products/Debug/SapphireFloatingCapsuleTest.app"

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "xcodebuild is not on this machine. Install Xcode and finish its first launch, then run this script here." >&2
  exit 1
fi

ORIG_STAMP=""
if [[ -d "$ORIG" ]]; then
  ORIG_STAMP="$(stat -f %m "$ORIG")"
  echo "Found $ORIG. This build will not replace it."
fi

mkdir -p "$DERIVED"
cd "$ROOT"

xcodebuild \
  -project Sapphire.xcodeproj \
  -scheme Sapphire \
  -configuration Debug \
  -destination "platform=macOS,arch=arm64" \
  -derivedDataPath "$DERIVED" \
  ARCHS=arm64 \
  ONLY_ACTIVE_ARCH=YES \
  CODE_SIGN_STYLE=Manual \
  "CODE_SIGN_IDENTITY=-" \
  "DEVELOPMENT_TEAM=" \
  CODE_SIGNING_ALLOWED=YES \
  CODE_SIGNING_REQUIRED=YES \
  AD_HOC_CODE_SIGNING_ALLOWED=YES \
  CODE_SIGN_ENTITLEMENTS=Sapphire/SapphireLocalUITest.entitlements \
  SAPPHIRE_APP_ENTITLEMENTS=Sapphire/SapphireLocalUITest.entitlements \
  REGISTER_APP_GROUPS=NO \
  SAPPHIRE_SKIP_CRASHLYTICS_UPLOAD=YES \
  SAPPHIRE_APP_BUNDLE_IDENTIFIER=com.local.sapphire.floatingcapsule.test \
  SAPPHIRE_APP_PRODUCT_NAME=SapphireFloatingCapsuleTest \
  "SAPPHIRE_APP_DISPLAY_NAME=Sapphire Floating Test"

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

echo "Built: $APP"
echo "Bundle id: $IDENTIFIER"
echo "Preferences plist: ~/Library/Preferences/${IDENTIFIER}.plist"
echo "Support folder: ~/Library/Application Support/SapphireFloatingCapsuleTest"
echo "Launch with: open \"$APP\""
echo "Do not copy the result to /Applications."
