#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
ICON_DIR="${PROJECT_DIR}/Resources"
ICONSET_DIR="${ICON_DIR}/AppIcon.iconset"
SOURCE_PNG="${ICON_DIR}/AppIcon.png"

# Generate source PNG
echo "Generating icon artwork..."
swift "${SCRIPT_DIR}/generate-icon.swift" "$SOURCE_PNG"

# Create iconset
echo "Creating iconset..."
mkdir -p "$ICONSET_DIR"

sips -z 16 16       "$SOURCE_PNG" --out "${ICONSET_DIR}/icon_16x16.png"      > /dev/null
sips -z 32 32       "$SOURCE_PNG" --out "${ICONSET_DIR}/icon_16x16@2x.png"   > /dev/null
sips -z 32 32       "$SOURCE_PNG" --out "${ICONSET_DIR}/icon_32x32.png"      > /dev/null
sips -z 64 64       "$SOURCE_PNG" --out "${ICONSET_DIR}/icon_32x32@2x.png"   > /dev/null
sips -z 128 128     "$SOURCE_PNG" --out "${ICONSET_DIR}/icon_128x128.png"    > /dev/null
sips -z 256 256     "$SOURCE_PNG" --out "${ICONSET_DIR}/icon_128x128@2x.png" > /dev/null
sips -z 256 256     "$SOURCE_PNG" --out "${ICONSET_DIR}/icon_256x256.png"    > /dev/null
sips -z 512 512     "$SOURCE_PNG" --out "${ICONSET_DIR}/icon_256x256@2x.png" > /dev/null
sips -z 512 512     "$SOURCE_PNG" --out "${ICONSET_DIR}/icon_512x512.png"    > /dev/null
sips -z 1024 1024   "$SOURCE_PNG" --out "${ICONSET_DIR}/icon_512x512@2x.png" > /dev/null

# Convert to .icns
echo "Converting to .icns..."
iconutil -c icns "$ICONSET_DIR" -o "${ICON_DIR}/AppIcon.icns"

# Clean up iconset directory
rm -rf "$ICONSET_DIR"

echo "Done: ${ICON_DIR}/AppIcon.icns"
