import 'dart:ui';

import 'package:darkfeed/utils/constants.dart';

/// Test fixtures for window testing
class WindowTestFixtures {
  // Common window sizes
  static const Size defaultSize = Size(1280, 720);
  static const Size hdSize = Size(1920, 1080);
  static const Size customSize = Size(1600, 900);
  static const Size smallSize = Size(800, 600);
  static const Size invalidSize = Size(0, 0);
  static const Size negativeSize = Size(-100, -100);
  static const Size offscreenSize = Size(10000, 10000);
  static const Size tooSmallSize = Size(50, 50);

  // Settings maps for testing storage
  static Map<String, dynamic> noSettings() => {};

  static Map<String, dynamic> sizedSettings({
    double width = 1600.0,
    double height = 900.0,
    bool maximized = false,
  }) => {
    StorageKeys.windowWidth: width,
    StorageKeys.windowHeight: height,
    StorageKeys.windowMaximized: maximized,
  };

  static Map<String, dynamic> maximizedSettings() => {
    StorageKeys.windowMaximized: true,
  };

  static Map<String, dynamic> invalidSettings() => {
    StorageKeys.windowWidth: 0.0,
    StorageKeys.windowHeight: 0.0,
    StorageKeys.windowMaximized: false,
  };

  static Map<String, dynamic> partialSettings() => {
    StorageKeys.windowWidth: 1600.0,
    // Missing height and maximized
  };
}
