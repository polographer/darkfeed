# DarkFeed AppImage Build Instructions

This directory contains the recipe and build scripts to create an AppImage for DarkFeed.

## What is AppImage?

AppImage is a universal software package format for Linux that allows applications to run on various distributions without installation. It bundles all dependencies into a single executable file.

## Prerequisites

### Required Dependencies

1. **Flutter SDK** (already installed based on your project)
2. **Build dependencies for Linux**:
   ```bash
   # Ubuntu/Debian
   sudo apt-get update
   sudo apt-get install -y \
     clang cmake ninja-build pkg-config \
     libgtk-3-dev libblkid-dev liblzma-dev \
     libsecret-1-dev libsecret-1-0
   
   # Fedora
   sudo dnf install -y \
     clang cmake ninja-build pkg-config \
     gtk3-devel libblkid-devel xz-devel \
     libsecret-devel
   
   # Arch Linux
   sudo pacman -S --needed \
     clang cmake ninja pkg-config \
     gtk3 util-linux xz libsecret
   ```

3. **appimagetool** (optional - script will download if not found):
   ```bash
   # Download appimagetool
   wget https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage
   chmod +x appimagetool-x86_64.AppImage
   sudo mv appimagetool-x86_64.AppImage /usr/local/bin/appimagetool
   ```

## Building the AppImage

### Quick Build

From the project root directory:

```bash
./appimage/build-appimage.sh
```

The script will:
1. Build the Flutter Linux application in release mode
2. Create an AppDir structure with all necessary files
3. Bundle required libraries
4. Generate the AppImage file

### Output

The AppImage will be created at:
```
appimage/output/darkfeed-1.0.0-x86_64.AppImage
```

### Running the AppImage

```bash
chmod +x appimage/output/darkfeed-1.0.0-x86_64.AppImage
./appimage/output/darkfeed-1.0.0-x86_64.AppImage
```

## Files in this Directory

- **build-appimage.sh**: Main build script that orchestrates the AppImage creation
- **AppRun**: Launcher script that sets up the environment and runs the application
- **darkfeed.desktop**: Desktop entry file with application metadata
- **AppDir/**: (generated) Staging directory containing the application structure
- **output/**: (generated) Final AppImage output directory

## Customization

### Change Application Version

Edit `build-appimage.sh` and modify the version:
```bash
APP_VERSION="1.0.0"  # Change this
```

Or update `pubspec.yaml`:
```yaml
version: 1.0.0+1  # Update this
```

### Change Icon

The build script will use icons in this priority order:
1. `web/icons/circus-negative.png`
2. `web/icons/Icon-512.png`

Place your custom icon in one of these locations before building.

### Desktop Entry Customization

Edit `darkfeed.desktop` to change:
- Application name
- Description
- Categories
- Other desktop integration settings

## Troubleshooting

### "Flutter is not installed or not in PATH"

Make sure Flutter is in your PATH:
```bash
export PATH="$PATH:/path/to/flutter/bin"
```

### Missing GTK Libraries

Install GTK development packages:
```bash
sudo apt-get install libgtk-3-dev  # Ubuntu/Debian
```

### AppImage doesn't run

Check for missing libraries:
```bash
./darkfeed-1.0.0-x86_64.AppImage --appimage-extract
cd squashfs-root
./AppRun
```

### Clean Build

Remove generated directories:
```bash
rm -rf appimage/AppDir appimage/output
flutter clean
```

## Distribution

The generated AppImage can be distributed as-is. Users only need to:
1. Download the AppImage
2. Make it executable: `chmod +x darkfeed-*.AppImage`
3. Run it: `./darkfeed-*.AppImage`

No installation or root privileges required!

## Technical Details

### AppDir Structure

```
AppDir/
├── AppRun                          # Launcher script
├── darkfeed.desktop                # Desktop entry
├── darkfeed.png                    # Application icon
└── usr/
    ├── bin/
    │   └── darkfeed                # Main executable
    │   └── lib/                    # Flutter libraries
    │   └── data/                   # Application data
    ├── lib/
    │   └── *.so                    # Bundled shared libraries
    └── share/
        ├── applications/
        │   └── darkfeed.desktop
        └── icons/
            └── hicolor/256x256/apps/
                └── darkfeed.png
```

### Environment Variables

The AppRun script sets:
- `PATH`: Includes the bundled binaries
- `LD_LIBRARY_PATH`: Points to bundled libraries
- `XDG_DATA_DIRS`: Includes application data

## References

- [AppImage Documentation](https://docs.appimage.org/)
- [Flutter Linux Desktop](https://docs.flutter.dev/platform-integration/linux/building)
- [Desktop Entry Specification](https://specifications.freedesktop.org/desktop-entry-spec/latest/)
