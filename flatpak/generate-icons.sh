#!/usr/bin/env bash
# Generate Flatpak icons from the macOS 1024x1024 source icon.
# Requires: imagemagick (convert command)
# Usage: ./generate-icons.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ICONS_DIR="$SCRIPT_DIR/icons"

# Source icon (macOS has the best quality)
SOURCE="$SCRIPT_DIR/../macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_1024.png"

if [[ ! -f "$SOURCE" ]]; then
    echo "Error: Source icon not found at $SOURCE"
    echo "Please provide a source icon or place one at the path above."
    exit 1
fi

echo "Generating Flatpak icons from: $SOURCE"

# Create directories
for size in 128 256 512 1024; do
    mkdir -p "$ICONS_DIR/$size"x"$size"
done

# Generate icons using ImageMagick
for size in 128 256 512 1024; do
    DEST="$ICONS_DIR/${size}x${size}/io.github.polographer.darkfeed.png"
    echo "  Generating ${size}x${size} -> $DEST"
    convert "$SOURCE" \
        -resize "${size}x${size}" \
        -background none \
        "$DEST"
done

echo "Done! Icons generated in $ICONS_DIR/"
