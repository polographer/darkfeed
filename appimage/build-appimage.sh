#!/bin/bash
# Build script for DarkFeed AppImage

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== DarkFeed AppImage Builder ===${NC}"

# Configuration
APP_NAME="darkfeed"
# Accept version as first argument, or extract from pubspec.yaml, or default to 1.0.0
if [ -n "$1" ]; then
    APP_VERSION="$1"
elif [ -f "pubspec.yaml" ]; then
    APP_VERSION=$(grep "^version:" pubspec.yaml | sed 's/version: *//' | sed 's/+.*//')
    if [ -z "$APP_VERSION" ]; then
        APP_VERSION="1.0.0"
    fi
else
    APP_VERSION="1.0.0"
fi
ARCH=$(uname -m)

echo -e "${GREEN}Building version: ${APP_VERSION}${NC}"
BUILD_DIR="$(pwd)/build/linux/x64/release/bundle"
APPDIR="$(pwd)/appimage/AppDir"
OUTPUT_DIR="$(pwd)/appimage/output"

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}Error: Flutter is not installed or not in PATH${NC}"
    exit 1
fi

# Check if appimagetool is installed
if ! command -v appimagetool &> /dev/null; then
    echo -e "${YELLOW}Warning: appimagetool not found. Attempting to download...${NC}"
    
    APPIMAGETOOL_URL="https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-${ARCH}.AppImage"
    wget -O /tmp/appimagetool "${APPIMAGETOOL_URL}"
    chmod +x /tmp/appimagetool
    # Use --appimage-extract-and-run for CI environments without FUSE
    APPIMAGETOOL="/tmp/appimagetool --appimage-extract-and-run"
else
    APPIMAGETOOL="appimagetool"
fi

# Step 1: Build the Flutter Linux application
echo -e "${GREEN}Step 1: Building Flutter application for Linux...${NC}"
flutter build linux --release

if [ ! -d "$BUILD_DIR" ]; then
    echo -e "${RED}Error: Build directory not found at $BUILD_DIR${NC}"
    exit 1
fi

# Step 2: Create AppDir structure
echo -e "${GREEN}Step 2: Creating AppDir structure...${NC}"
rm -rf "$APPDIR"
mkdir -p "$APPDIR/usr/bin"
mkdir -p "$APPDIR/usr/lib"
mkdir -p "$APPDIR/usr/share/applications"
mkdir -p "$APPDIR/usr/share/icons/hicolor/256x256/apps"

# Step 3: Copy Flutter build files
echo -e "${GREEN}Step 3: Copying application files...${NC}"
cp -r "$BUILD_DIR"/* "$APPDIR/usr/bin/"

# Step 4: Copy desktop file
echo -e "${GREEN}Step 4: Installing desktop file...${NC}"
cp appimage/darkfeed.desktop "$APPDIR/usr/share/applications/"
cp appimage/darkfeed.desktop "$APPDIR/"

# Step 5: Copy icon
echo -e "${GREEN}Step 5: Installing icon...${NC}"
if [ -f "web/icons/circus-negative.png" ]; then
    cp web/icons/circus-negative.png "$APPDIR/usr/share/icons/hicolor/256x256/apps/darkfeed.png"
    cp web/icons/circus-negative.png "$APPDIR/darkfeed.png"
elif [ -f "web/icons/Icon-512.png" ]; then
    cp web/icons/Icon-512.png "$APPDIR/usr/share/icons/hicolor/256x256/apps/darkfeed.png"
    cp web/icons/Icon-512.png "$APPDIR/darkfeed.png"
else
    echo -e "${YELLOW}Warning: No icon found, using placeholder${NC}"
fi

# Step 6: Copy AppRun script
echo -e "${GREEN}Step 6: Installing AppRun script...${NC}"
cp appimage/AppRun "$APPDIR/"
chmod +x "$APPDIR/AppRun"

# Step 7: Copy necessary system libraries
echo -e "${GREEN}Step 7: Bundling system libraries...${NC}"

# Function to copy library and its dependencies
copy_lib() {
    local lib=$1
    if [ -f "$lib" ]; then
        cp "$lib" "$APPDIR/usr/lib/"
        # Copy dependencies
        ldd "$lib" | grep "=> /" | awk '{print $3}' | while read dep; do
            if [ -f "$dep" ] && [ ! -f "$APPDIR/usr/lib/$(basename $dep)" ]; then
                cp "$dep" "$APPDIR/usr/lib/" 2>/dev/null || true
            fi
        done
    fi
}

# Bundle Flutter engine and common libraries
if [ -f "$APPDIR/usr/bin/lib/libflutter_linux_gtk.so" ]; then
    copy_lib "$APPDIR/usr/bin/lib/libflutter_linux_gtk.so"
fi

# Bundle GTK and GLib libraries (if not system-provided)
# Note: Most systems have these, so we rely on system libraries for GTK

# Step 8: Create output directory
mkdir -p "$OUTPUT_DIR"

# Step 9: Build AppImage
echo -e "${GREEN}Step 9: Building AppImage...${NC}"
APPIMAGE_NAME="${APP_NAME}-${APP_VERSION}-${ARCH}.AppImage"

cd appimage
eval "$APPIMAGETOOL" AppDir "output/$APPIMAGE_NAME"
cd ..

# Step 10: Done
echo -e "${GREEN}==================================${NC}"
echo -e "${GREEN}AppImage built successfully!${NC}"
echo -e "${GREEN}Location: appimage/output/$APPIMAGE_NAME${NC}"
echo -e "${GREEN}==================================${NC}"
echo ""
echo -e "${YELLOW}To run the AppImage:${NC}"
echo -e "  chmod +x appimage/output/$APPIMAGE_NAME"
echo -e "  ./appimage/output/$APPIMAGE_NAME"
