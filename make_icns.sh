#!/bin/bash
# make_icns.sh — Build AppIcon.icns from icon-1024.png using macOS iconutil
# Run this from the inkwell/ directory

set -e

ICONSET="AppIcon.iconset"
SRC="icon-1024.png"

mkdir -p "$ICONSET"

# Generate all required sizes from the 1024px source
sips -z 16   16   "$SRC" --out "$ICONSET/icon_16x16.png"
sips -z 32   32   "$SRC" --out "$ICONSET/icon_16x16@2x.png"
sips -z 32   32   "$SRC" --out "$ICONSET/icon_32x32.png"
sips -z 64   64   "$SRC" --out "$ICONSET/icon_32x32@2x.png"
sips -z 128  128  "$SRC" --out "$ICONSET/icon_128x128.png"
sips -z 256  256  "$SRC" --out "$ICONSET/icon_128x128@2x.png"
sips -z 256  256  "$SRC" --out "$ICONSET/icon_256x256.png"
sips -z 512  512  "$SRC" --out "$ICONSET/icon_256x256@2x.png"
cp                "$SRC"       "$ICONSET/icon_512x512@2x.png"
sips -z 512  512  "$SRC" --out "$ICONSET/icon_512x512.png"

iconutil -c icns "$ICONSET" -o AppIcon.icns

echo "Done: AppIcon.icns created."
rm -rf "$ICONSET"
