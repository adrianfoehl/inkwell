#!/bin/bash
set -e

cd "$(dirname "$0")"

echo "Building Inkwell..."
xcodebuild -scheme Inkwell -derivedDataPath .build/xcode -configuration Release -destination 'platform=macOS' build 2>&1 | tail -1

APP=~/Applications/Inkwell.app

mkdir -p "$APP/Contents/MacOS"
mkdir -p "$APP/Contents/Resources"

cp .build/xcode/Build/Products/Release/Inkwell "$APP/Contents/MacOS/Inkwell"

# Copy resource bundles (editor.html etc.)
find .build/xcode/Build/Products/Release -name "*.bundle" -maxdepth 1 -exec cp -R {} "$APP/Contents/Resources/" \;

# Register with Launch Services
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$APP"

echo "Done. Run: open ~/Applications/Inkwell.app"
