# DarkFeed

A Pixelfed client built with Flutter featuring TikTok/Reels-style vertical navigation.

# Disclaimer --- human

I'm a experienced software engineer, however I never got chance to break into linux software development. This app was a plan that I had for years but never been able to materialize because of lack of time and kids. 

This app is vibe coded and I review the code as much as I can. However I know that the vibe coded apps are susceptible to bugs and rough edges. I'm fixing them because this is my daily driver. I use this app because I don't like the current ones.

Why? that leads me to my vision; I'm also a photographer and I belive that the way to look at photography is without distractions, when I was learning photography we used to print our digital photos and took time to view them separately, we sometimes put it in a togheter to "select" but never to admire, thats why the Instagram timline approach is a dilution in the photography art, and downplays the experience. 

The closest I could imagine in this digital world is to view each picture in full screen and in a dark background, like in a darkroom, take our time to admire and dont have any other distraction (like the username, comments and likes). This is the idea behind this app, and I plan to distile it as much as possible.

My main platforms are linux, mac and iOS. That's my main focus but if someone wants to contribute for other platforms, they are welcome.

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

### Mobile/Desktop - tested the most on linux (debian trixie)
```bash
flutter run
```

### Web - not tested as much as other platforms
```bash
flutter run -d chrome
# or
flutter run -d web-server --web-port=8080
```

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
├── models/                # Data models
│   └── post.dart
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

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

