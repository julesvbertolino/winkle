#!/bin/bash
# Construit Winkle.app puis l'empaquette dans un .dmg partageable
# (avec un raccourci vers /Applications pour l'installation par glisser-déposer).
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="1.0.0"
APP="build/Winkle.app"
DMG="build/Winkle-${VERSION}.dmg"
STAGING="build/dmg-staging"

# 1. (Re)construit l'app.
./scripts/bundle.sh

# 2. Prépare le contenu du volume : l'app + un alias vers Applications.
rm -rf "$STAGING" "$DMG"
mkdir -p "$STAGING"
cp -R "$APP" "$STAGING/"
ln -s /Applications "$STAGING/Applications"

# 3. Fabrique le DMG compressé.
hdiutil create \
    -volname "Winkle" \
    -srcfolder "$STAGING" \
    -ov -format UDZO \
    "$DMG" >/dev/null

rm -rf "$STAGING"
echo "✓ ${DMG}  ($(du -h "$DMG" | cut -f1))"
