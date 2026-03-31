#!/bin/bash
set -e

cd "$(dirname "$0")"

echo "Building Inkwell..."
swift build -c release 2>&1 | tail -1

APP=/Applications/Inkwell.app
BUILD_DIR=.build/release

mkdir -p "$APP/Contents/MacOS"
mkdir -p "$APP/Contents/Resources"

cp "$BUILD_DIR/Inkwell" "$APP/Contents/MacOS/Inkwell"

# Copy resource bundles (editor.html etc.)
find "$BUILD_DIR" -name "*.bundle" -maxdepth 1 -exec cp -R {} "$APP/Contents/Resources/" \;

# Copy app icon
cp AppIcon.icns "$APP/Contents/Resources/AppIcon.icns" 2>/dev/null

# Re-sign (required after binary replacement)
codesign --force --sign - "$APP"

# Register with Launch Services
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$APP"

echo "Done. Run: open ~/Applications/Inkwell.app"
