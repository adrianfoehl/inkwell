#!/bin/bash
set -e
shopt -s nullglob

cd "$(dirname "$0")"

# The one place the version is written. It lands in the app bundle and is what
# About Inkwell shows; keep CHANGELOG.md and the git tag in step with it.
VERSION="0.2.0"

echo "Building Inkwell $VERSION..."
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

# Bundle metadata: without it the app has no identity, no icon and no .md
# association, so a fresh clone used to build an app macOS would not open files with.
sed "s/__VERSION__/$VERSION/g" Info.plist > "$APP/Contents/Info.plist"

# Re-sign (required after binary replacement)
codesign --force --sign - "$APP"

# Register with Launch Services
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$APP"

# Fail loudly rather than shipping an app that can't load its editor
test -f "$APP/Contents/Resources/Inkwell_Inkwell.bundle/editor.html" \
    || { echo "ERROR: editor.html missing from $APP"; exit 1; }
test -f "$APP/Contents/Info.plist" \
    || { echo "ERROR: Info.plist missing from $APP"; exit 1; }

echo "Done ($VERSION). Run: open $APP"
