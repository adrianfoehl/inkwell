#!/bin/bash
set -e
shopt -s nullglob

cd "$(dirname "$0")"

echo "Building Inkwell..."
swift build -c release 2>&1 | tail -1

APP=/Applications/Inkwell.app
# --show-bin-path resolves .build/release, which is a symlink that find won't follow
BUILD_DIR="$(swift build -c release --show-bin-path)"

mkdir -p "$APP/Contents/MacOS"
mkdir -p "$APP/Contents/Resources"

cp "$BUILD_DIR/Inkwell" "$APP/Contents/MacOS/Inkwell"

# Copy resource bundles (editor.html etc.), replacing any stale copy
for bundle in "$BUILD_DIR"/*.bundle; do
    rm -rf "$APP/Contents/Resources/$(basename "$bundle")"
    cp -R "$bundle" "$APP/Contents/Resources/"
done

# Copy app icon
cp AppIcon.icns "$APP/Contents/Resources/AppIcon.icns" 2>/dev/null

# Re-sign (required after binary replacement)
codesign --force --sign - "$APP"

# Register with Launch Services
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$APP"

# Fail loudly rather than shipping an app that can't load its editor
test -f "$APP/Contents/Resources/Inkwell_Inkwell.bundle/editor.html" \
    || { echo "ERROR: editor.html missing from $APP"; exit 1; }

echo "Done. Run: open $APP"
