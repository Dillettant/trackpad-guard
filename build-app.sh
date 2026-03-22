#!/bin/bash
set -euo pipefail

APP_NAME="TrackpadGuard"
VERSION="${1:-1.0.0}"
BUNDLE_DIR="build/${APP_NAME}.app"
DMG_NAME="${APP_NAME}-${VERSION}.dmg"

echo "=== Building ${APP_NAME} v${VERSION} ==="

# Generate icon if not present
if [ ! -f Resources/AppIcon.icns ]; then
    echo "Generating app icon..."
    bash scripts/generate-icns.sh
fi

# Build release binary
echo "Building release binary..."
swift build -c release

# Assemble .app bundle
echo "Assembling ${APP_NAME}.app..."
rm -rf "$BUNDLE_DIR"
mkdir -p "${BUNDLE_DIR}/Contents/MacOS"
mkdir -p "${BUNDLE_DIR}/Contents/Resources"

cp .build/release/trackpad-guard "${BUNDLE_DIR}/Contents/MacOS/trackpad-guard"
cp Resources/Info.plist "${BUNDLE_DIR}/Contents/"
cp Resources/AppIcon.icns "${BUNDLE_DIR}/Contents/Resources/"
echo "APPL????" > "${BUNDLE_DIR}/Contents/PkgInfo"

# Create DMG
echo "Creating DMG..."
DMG_STAGING="build/dmg-staging"
rm -rf "$DMG_STAGING"
mkdir -p "$DMG_STAGING"
cp -r "$BUNDLE_DIR" "$DMG_STAGING/"

# Add Applications symlink for drag-to-install
ln -s /Applications "$DMG_STAGING/Applications"

rm -f "build/${DMG_NAME}"
hdiutil create \
    -volname "$APP_NAME" \
    -srcfolder "$DMG_STAGING" \
    -ov \
    -format UDZO \
    "build/${DMG_NAME}"

rm -rf "$DMG_STAGING"

# Print SHA-256 for Homebrew
DMG_SHA=$(shasum -a 256 "build/${DMG_NAME}" | awk '{print $1}')

echo ""
echo "=== Build complete ==="
echo "  App:  ${BUNDLE_DIR}"
echo "  DMG:  build/${DMG_NAME}"
echo "  SHA:  ${DMG_SHA}"
echo ""
echo "Install:"
echo "  cp -r ${BUNDLE_DIR} /Applications/"
echo "  # or open build/${DMG_NAME} and drag to Applications"
