#!/bin/bash
# Génère assets/Winkle.icns à partir de assets/icon-1024.png (via sips + iconutil).
set -euo pipefail
cd "$(dirname "$0")/.."

SRC="assets/icon-1024.png"
[ -f "$SRC" ] || swift scripts/make-icon.swift "$SRC"

ICONSET="assets/Winkle.iconset"
rm -rf "$ICONSET"
mkdir -p "$ICONSET"

# macOS attend ces tailles précises (@1x et @2x).
for spec in "16 16x16" "32 16x16@2x" "32 32x32" "64 32x32@2x" \
            "128 128x128" "256 128x128@2x" "256 256x256" "512 256x256@2x" \
            "512 512x512" "1024 512x512@2x"; do
    px="${spec% *}"; name="${spec#* }"
    sips -z "$px" "$px" "$SRC" --out "$ICONSET/icon_${name}.png" >/dev/null
done

iconutil -c icns "$ICONSET" -o assets/Winkle.icns
rm -rf "$ICONSET"
echo "✓ assets/Winkle.icns"
