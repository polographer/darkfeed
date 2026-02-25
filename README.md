# DarkFeed

A Pixelfed client built with Flutter featuring TikTok/Reels-style vertical navigation.

## Features

- 📱 Full-screen vertical timeline (swipe up/down on mobile, arrow keys on desktop)
- 🌓 Dark gray theme (#1C1C1E background)
- ❤️ Like/unlike posts
- 💬 View comments and captions
- 👤 User profiles
- 🔐 Secure OAuth2 authentication
- 🖥️ Multi-platform: Android, iOS, Linux, macOS, Web, Windows

## Getting Started

### Prerequisites

- Flutter SDK (stable channel, 3.41.2+)
- Dart 3.11.0+

### Platform-Specific Requirements

#### Linux Desktop
```bash
sudo apt-get install libwebkit2gtk-4.1-dev
```

#### All Platforms
```bash
flutter pub get
```

## Running the App

### Mobile/Desktop
```bash
flutter run
```

### Web
```bash
flutter run -d chrome
# or
flutter run -d web-server --web-port=8080
```

## Known Issues

### Linux Desktop OAuth

Due to a bug in the `desktop_webview_window` package, the OAuth web view may crash the app after successful authentication on Linux desktop. However, **authentication still works** - the token is saved before the crash.

**Workaround:**
1. Start the app and begin OAuth login
2. Complete authentication in the browser window
3. The app will crash after OAuth completes
4. **Restart the app** - you will be automatically logged in with your saved credentials

**Alternative:** Use the web platform for development/testing:
```bash
flutter run -d chrome
```

The web platform has full OAuth support without any crashes.

## Building

```bash
# Android
flutter build apk

# Linux
flutter build linux

# Web
flutter build web
```

## Architecture

```
lib/
├── main.dart              # App entry point
├── screens/               # UI screens
│   ├── instance_selector_screen.dart
│   ├── login_screen.dart
│   └── timeline_screen.dart
├── providers/             # State management (Provider pattern)
│   ├── auth_provider.dart
│   ├── instance_provider.dart
│   └── timeline_provider.dart
├── services/              # Business logic
│   ├── oauth_service.dart
│   ├── pixelfed_service.dart
│   └── storage_service.dart
└── utils/                 # Constants and utilities
    ├── constants.dart
    ├── known_instances.dart
    └── platform_utils.dart
```

## Usage

1. **Select Instance**: Choose from popular instances or enter a custom Pixelfed instance URL
2. **Authenticate**: Complete OAuth2 login flow
3. **Browse Timeline**: Swipe vertically (mobile) or use arrow keys (desktop) to navigate posts
4. **Interact**: Tap screen to show/hide overlay, like posts, view captions

## Testing

```bash
flutter test
```

## License

This project is for educational purposes.

