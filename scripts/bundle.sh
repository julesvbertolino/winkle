#!/bin/bash
# Construit Winkle.app à partir du binaire SPM (release).
# Nécessaire pour : notifications, lancement au démarrage, distribution.
set -euo pipefail

cd "$(dirname "$0")/.."

VERSION="1.0.0"
BUNDLE_ID="fr.julesbertolino.winkle"
BUILD_DIR=".build/release"
APP="build/Winkle.app"

swift build -c release

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BUILD_DIR/Winkle" "$APP/Contents/MacOS/Winkle"

# Icône (générée à la demande si absente).
[ -f assets/Winkle.icns ] || ./scripts/make-icns.sh
cp assets/Winkle.icns "$APP/Contents/Resources/Winkle.icns"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>          <string>Winkle</string>
    <key>CFBundleIconFile</key>            <string>Winkle</string>
    <key>CFBundleIdentifier</key>          <string>${BUNDLE_ID}</string>
    <key>CFBundleName</key>                <string>Winkle</string>
    <key>CFBundleDisplayName</key>         <string>Winkle</string>
    <key>CFBundlePackageType</key>         <string>APPL</string>
    <key>CFBundleShortVersionString</key>  <string>${VERSION}</string>
    <key>CFBundleVersion</key>             <string>${VERSION}</string>
    <key>LSMinimumSystemVersion</key>      <string>13.0</string>
    <key>LSUIElement</key>                 <true/>
    <key>NSHumanReadableCopyright</key>    <string>Open source — MIT</string>
</dict>
</plist>
PLIST

# Signature ad-hoc pour l'exécution locale (notarisation à part pour la distribution).
codesign --force --deep --sign - "$APP"

echo "✓ ${APP}"
