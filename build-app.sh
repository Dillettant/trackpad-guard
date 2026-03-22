#!/bin/bash
set -euo pipefail

APP_NAME="TrackpadGuard"
BUNDLE_DIR="build/${APP_NAME}.app"

echo "Building release binary..."
swift build -c release

echo "Assembling ${APP_NAME}.app bundle..."
rm -rf "$BUNDLE_DIR"
mkdir -p "${BUNDLE_DIR}/Contents/MacOS"
mkdir -p "${BUNDLE_DIR}/Contents/Resources"

cp .build/release/trackpad-guard "${BUNDLE_DIR}/Contents/MacOS/trackpad-guard"
cp Resources/Info.plist "${BUNDLE_DIR}/Contents/"

echo "APPL????" > "${BUNDLE_DIR}/Contents/PkgInfo"

echo ""
echo "Built: ${BUNDLE_DIR}"
echo ""
echo "To install:"
echo "  cp -r ${BUNDLE_DIR} /Applications/"
echo ""
echo "Then open TrackpadGuard from /Applications and grant Accessibility permission when prompted."
