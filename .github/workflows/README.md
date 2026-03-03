# GitHub Actions Workflows

This directory contains automated workflows for the DarkFeed project.

## Available Workflows

### Release AppImage (`release-appimage.yml`)

Automatically builds a Linux AppImage for distribution when a new release is created.

#### Triggers

1. **Automatic on Release**: Triggers when you create a new GitHub release
2. **Manual Trigger**: Can be run manually from the Actions tab with custom version

#### What it does

1. Checks out the code
2. Extracts version number from:
   - Manual workflow input (if provided)
   - Release tag name (e.g., `v1.0.0` → `1.0.0`)
   - `pubspec.yaml` file (as fallback)
3. Installs all required Linux dependencies (GTK, CMake, etc.)
4. Sets up Flutter SDK
5. Builds the AppImage with the correct version
6. Uploads the AppImage as a workflow artifact
7. Attaches the AppImage to the GitHub release
8. Generates and uploads SHA256 checksums

#### Output

- **AppImage file**: `darkfeed-{version}-x86_64.AppImage`
- **Checksums**: `checksums.txt` with SHA256 hashes
- **Artifacts**: Available for download from the Actions tab (30-day retention)

#### Usage

##### Automatic (Recommended)

1. Create a new release on GitHub:
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```
2. Go to GitHub → Releases → Draft a new release
3. Select the tag `v1.0.0`
4. Publish the release
5. The workflow automatically triggers and builds the AppImage
6. The AppImage is attached to the release when complete

##### Manual Trigger

1. Go to Actions tab on GitHub
2. Select "Build and Release AppImage"
3. Click "Run workflow"
4. Optionally specify a version number
5. The AppImage is created and available as an artifact

#### Version Handling

The workflow determines the version in this priority order:
1. Manual input version (workflow_dispatch)
2. Release tag name (strips 'v' prefix automatically)
3. Version from `pubspec.yaml`

#### Requirements

- No special setup required
- Uses public GitHub-hosted runners (Ubuntu latest)
- All dependencies are installed automatically
- Uses `GITHUB_TOKEN` (automatically provided)

#### Workflow Steps

```yaml
Checkout → Extract Version → Install Dependencies → Setup Flutter
    ↓
Get Dependencies → Build AppImage → Verify Build
    ↓
Upload Artifact → Upload to Release → Generate Checksums
```

#### Troubleshooting

**Workflow fails at "Install Flutter dependencies"**
- Check that all apt packages are available in Ubuntu latest
- Update package names if needed

**Workflow fails at "Build AppImage"**
- Check Flutter build logs in the workflow output
- Ensure `build-appimage.sh` has execute permissions (should be committed with +x)

**AppImage not attached to release**
- Verify the release was created (not draft)
- Check that `GITHUB_TOKEN` has appropriate permissions
- Ensure workflow runs to completion (check Actions tab)

**Wrong version number in AppImage**
- For releases: Ensure tag follows `vX.Y.Z` or `X.Y.Z` format
- Update version in `pubspec.yaml` before creating release
- Use manual trigger with explicit version

#### Configuration

Edit `.github/workflows/release-appimage.yml` to customize:

- **Runner OS**: Change `runs-on: ubuntu-latest` for different OS
- **Flutter channel**: Modify `channel: stable` to `beta` or `master`
- **Artifact retention**: Add `retention-days: N` to upload-artifact step
- **Additional platforms**: Add more jobs for macOS/Windows builds

#### Example Release Process

```bash
# 1. Update version in pubspec.yaml
sed -i 's/version: .*/version: 1.2.0+1/' pubspec.yaml

# 2. Commit and tag
git add pubspec.yaml
git commit -m "Release v1.2.0"
git tag v1.2.0
git push origin main
git push origin v1.2.0

# 3. Create release on GitHub
# Go to: https://github.com/your-username/darkfeed/releases/new
# - Choose tag: v1.2.0
# - Release title: "DarkFeed v1.2.0"
# - Description: Release notes
# - Publish release

# 4. Wait for workflow to complete
# AppImage will be automatically attached to the release
```

#### Build Time

Expected build time: 5-10 minutes
- Dependency installation: ~1 minute
- Flutter setup: ~2 minutes
- Flutter build: ~3-5 minutes
- AppImage generation: ~1 minute

#### Caching

The workflow uses Flutter caching to speed up subsequent builds:
- Dart SDK cache
- Flutter SDK cache
- Pub package cache

#### Manual Testing

To test the workflow locally before pushing:

```bash
# Install act (GitHub Actions runner)
# https://github.com/nektos/act

# Run the workflow locally
act release -s GITHUB_TOKEN=your_token
```

## Adding More Workflows

To add additional workflows:

1. Create a new `.yml` file in this directory
2. Follow GitHub Actions syntax
3. Test with workflow_dispatch trigger first
4. Document in this README

## References

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Flutter GitHub Actions](https://docs.flutter.dev/deployment/cd#github-actions)
- [AppImage Documentation](https://docs.appimage.org/)
