import 'dart:ui';

import 'package:darkfeed/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storageService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storageService = StorageService();
    await storageService.init();
  });

  group('Window Size Storage', () {
    test('saveWindowSize() saves width and height correctly', () async {
      await storageService.saveWindowSize(1920, 1080);

      final size = await storageService.getWindowSize();
      expect(size, isNotNull);
      expect(size!.width, 1920);
      expect(size.height, 1080);
    });

    test('saveWindowSize() overwrites existing values', () async {
      await storageService.saveWindowSize(1280, 720);
      await storageService.saveWindowSize(1920, 1080);

      final size = await storageService.getWindowSize();
      expect(size!.width, 1920);
      expect(size.height, 1080);
    });

    test('getWindowSize() returns null when no values saved', () async {
      final size = await storageService.getWindowSize();
      expect(size, isNull);
    });

    test('getWindowSize() returns null when only width is saved', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('window_width', 1920);

      final size = await storageService.getWindowSize();
      expect(size, isNull);
    });

    test('getWindowSize() returns null when only height is saved', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('window_height', 1080);

      final size = await storageService.getWindowSize();
      expect(size, isNull);
    });

    test(
      'getWindowSize() returns correct Size when both values exist',
      () async {
        await storageService.saveWindowSize(1600, 900);

        final size = await storageService.getWindowSize();
        expect(size, const Size(1600, 900));
      },
    );
  });

  group('Window Maximized State Storage', () {
    test('saveWindowMaximized() saves boolean correctly', () async {
      await storageService.saveWindowMaximized(true);

      final maximized = await storageService.isWindowMaximized();
      expect(maximized, true);
    });

    test('saveWindowMaximized() can save false', () async {
      await storageService.saveWindowMaximized(false);

      final maximized = await storageService.isWindowMaximized();
      expect(maximized, false);
    });

    test('saveWindowMaximized() overwrites existing value', () async {
      await storageService.saveWindowMaximized(true);
      await storageService.saveWindowMaximized(false);

      final maximized = await storageService.isWindowMaximized();
      expect(maximized, false);
    });

    test('isWindowMaximized() returns null when not set', () async {
      final maximized = await storageService.isWindowMaximized();
      expect(maximized, isNull);
    });
  });

  group('Has Window Settings', () {
    test('hasWindowSettings() returns false when no settings exist', () async {
      final hasSettings = await storageService.hasWindowSettings();
      expect(hasSettings, false);
    });

    test('hasWindowSettings() returns true when width exists', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('window_width', 1920);

      final hasSettings = await storageService.hasWindowSettings();
      expect(hasSettings, true);
    });

    test('hasWindowSettings() returns true when height exists', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('window_height', 1080);

      final hasSettings = await storageService.hasWindowSettings();
      expect(hasSettings, true);
    });

    test('hasWindowSettings() returns true when maximized exists', () async {
      await storageService.saveWindowMaximized(true);

      final hasSettings = await storageService.hasWindowSettings();
      expect(hasSettings, true);
    });

    test('hasWindowSettings() returns true when all settings exist', () async {
      await storageService.saveWindowSize(1920, 1080);
      await storageService.saveWindowMaximized(false);

      final hasSettings = await storageService.hasWindowSettings();
      expect(hasSettings, true);
    });

    test('hasWindowSettings() returns true for partial settings', () async {
      await storageService.saveWindowSize(1600, 900);

      final hasSettings = await storageService.hasWindowSettings();
      expect(hasSettings, true);
    });
  });

  group('Integration', () {
    test('can save and retrieve complete window state', () async {
      await storageService.saveWindowSize(1920, 1080);
      await storageService.saveWindowMaximized(true);

      final size = await storageService.getWindowSize();
      final maximized = await storageService.isWindowMaximized();

      expect(size, const Size(1920, 1080));
      expect(maximized, true);
    });

    test('window settings persist across re-initialization', () async {
      await storageService.saveWindowSize(1600, 900);
      await storageService.saveWindowMaximized(false);

      // Create new instance
      final newStorageService = StorageService();
      await newStorageService.init();

      final size = await newStorageService.getWindowSize();
      final maximized = await newStorageService.isWindowMaximized();

      expect(size, const Size(1600, 900));
      expect(maximized, false);
    });
  });
}
