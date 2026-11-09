#!/usr/bin/env bash
# Build DarkFeed Flatpak for ARM64 (aarch64) or x86_64
#
# Usage:
#   ./flatpak/build.sh --arch aarch64   # Build for ARM64 (default)
#   ./flatpak/build.sh --arch x86_64    # Build for x86_64
#
# Prerequisites:
#   sudo apt install flatpak flatpak-builder
#   flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
#
# For local building, you also need Flutter + Linux deps:
#   sudo apt install clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev
#   # Then: flutter build linux --release

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
APP_ID="io.github.polographer.darkfeed"
ARCH="aarch64"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --arch) ARCH="$2"; shift 2 ;;
        *) shift ;;
    esac
done

MANIFEST="$SCRIPT_DIR/${APP_ID}.yml"
BUNDLE_DIR="build-flatpak-$ARCH"
BUILD_DIR="build-flatpak-builder-$ARCH"

echo "============================================"
echo " DarkFeed Flatpak Builder"
echo " Architecture: $ARCH"
echo " App ID:       $APP_ID"
echo "============================================"

# Step 0: Generate icons if source exists
if command -v convert &> /dev/null; then
    echo ""
    echo "Step 0: Generating Flatpak icons..."
    bash "$SCRIPT_DIR/generate-icons.sh" || true
else
    echo ""
    echo "Step 0: Skipping icon generation (install imagemagick)"
    echo "        Place icons manually in flatpak/icons/<size>x<size>/"
fi

# Step 1: Verify prerequisites
echo ""
echo "Step 1: Verifying prerequisites..."

for cmd in flatpak flatpak-builder; do
    if ! command -v "$cmd" &> /dev/null; then
        echo "ERROR: $cmd is not installed."
        echo "  sudo apt install flatpak flatpak-builder"
        exit 1
    fi
done

# Ensure Flathub remote
flatpak remote-add --if-not-exists flathub \
    https://flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true

# Step 2: Build Flutter Linux release
echo ""
echo "Step 2: Building Flutter Linux release..."
cd "$PROJECT_DIR"

if command -v flutter &> /dev/null; then
    flutter pub get
    flutter build linux --release
    echo "Flutter build complete."
else
    echo "WARNING: flutter not found. Skipping Flutter build."
    echo "        Ensure $BUNDLE_DIR already exists with a valid Linux bundle."
fi

# Step 3: Prepare bundle directory
echo ""
echo "Step 3: Preparing bundle directory..."
if [ ! -d "$BUNDLE_DIR" ]; then
    case "$ARCH" in
        aarch64)
            cp -r build/linux/arm64/release/bundle "$BUNDLE_DIR"
            ;;
        x86_64)
            cp -r build/linux/x64/release/bundle "$BUNDLE_DIR"
            ;;
    esac
fi

# Step 4: Build Flatpak
echo ""
echo "Step 4: Building Flatpak for $ARCH..."
cd "$SCRIPT_DIR"
mkdir -p "$BUILD_DIR"

flatpak-builder \
    --force-clean \
    --arch="$ARCH" \
    --env="FLATPAK_BUNDLE_DIR=$(cd "$PROJECT_DIR" && pwd)/$BUNDLE_DIR" \
    "$BUILD_DIR" \
    "$MANIFEST"

echo ""
echo "Step 5: Creating Flatpak bundle..."

flatpak build-bundle \
    "$BUILD_DIR" \
    "$BUILD_DIR/${APP_ID}_${ARCH}.flatpak" \
    "$APP_ID"

echo ""
echo "============================================"
echo " Build complete!"
echo " Bundle: $BUILD_DIR/${APP_ID}_${ARCH}.flatpak"
echo "============================================"
echo ""
echo "To install:"
echo "  flatpak install --user $BUILD_DIR/${APP_ID}_${ARCH}.flatpak"
echo ""
echo "To run:"
echo "  flatpak run $APP_ID"
