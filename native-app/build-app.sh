#!/bin/bash
#
# build-app.sh
#
# Compiles Headroom as a release binary and packages it into a proper
# Headroom.app bundle in ~/Applications — so you can double-click it,
# add it to Login Items to auto-start, and never touch Terminal again
# for day-to-day use. Re-run this any time the source changes.

set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

APP_NAME="Headroom"
APP_DIR="$HOME/Applications/${APP_NAME}.app"
BIN_SRC=".build/release/${APP_NAME}"

echo "Building release binary…"
swift build -c release

echo "Packaging ${APP_NAME}.app…"
mkdir -p "$HOME/Applications"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

cp "$BIN_SRC" "$APP_DIR/Contents/MacOS/${APP_NAME}"
chmod +x "$APP_DIR/Contents/MacOS/${APP_NAME}"

cat > "$APP_DIR/Contents/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleExecutable</key>
	<string>${APP_NAME}</string>
	<key>CFBundleIdentifier</key>
	<string>com.achint.headroom</string>
	<key>CFBundleName</key>
	<string>${APP_NAME}</string>
	<key>CFBundleShortVersionString</key>
	<string>1.0</string>
	<key>CFBundleVersion</key>
	<string>1</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>LSUIElement</key>
	<true/>
	<key>LSMinimumSystemVersion</key>
	<string>13.0</string>
	<key>NSHighResolutionCapable</key>
	<true/>
</dict>
</plist>
PLIST

echo "Codesigning (ad-hoc, so it launches cleanly without a Gatekeeper prompt)…"
codesign --force --deep --sign - "$APP_DIR"

echo
echo "Done. ${APP_NAME}.app is installed at:"
echo "  $APP_DIR"
echo
echo "Launch it now with:"
echo "  open \"$APP_DIR\""
echo
echo "Or find it in Finder (Go > Home > Applications) and double-click it."
echo "To auto-start at login: System Settings > General > Login Items & Extensions > add Headroom."
