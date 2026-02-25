import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// Platform detection utilities for cross-platform support

/// Check if running on desktop platform (Linux, macOS, Windows)
bool get isDesktop {
  if (kIsWeb) return false;
  return Platform.isLinux || Platform.isMacOS || Platform.isWindows;
}

/// Check if running on mobile platform (Android, iOS)
bool get isMobile {
  if (kIsWeb) return false;
  return Platform.isAndroid || Platform.isIOS;
}

/// Check if running on web platform
bool get isWeb {
  return kIsWeb;
}

/// Check if running on Android
bool get isAndroid {
  if (kIsWeb) return false;
  return Platform.isAndroid;
}

/// Check if running on iOS
bool get isIOS {
  if (kIsWeb) return false;
  return Platform.isIOS;
}

/// Check if running on Linux
bool get isLinux {
  if (kIsWeb) return false;
  return Platform.isLinux;
}

/// Check if running on macOS
bool get isMacOS {
  if (kIsWeb) return false;
  return Platform.isMacOS;
}

/// Check if running on Windows
bool get isWindows {
  if (kIsWeb) return false;
  return Platform.isWindows;
}

/// Get platform name as string
String get platformName {
  if (kIsWeb) return 'Web';
  if (Platform.isAndroid) return 'Android';
  if (Platform.isIOS) return 'iOS';
  if (Platform.isLinux) return 'Linux';
  if (Platform.isMacOS) return 'macOS';
  if (Platform.isWindows) return 'Windows';
  return 'Unknown';
}
