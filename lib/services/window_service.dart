import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:window_manager/window_manager.dart';

import 'package:darkfeed/services/storage_service.dart';
import 'package:darkfeed/services/window_manager_interface.dart';

/// Manages window state persistence and restoration for desktop platforms.
///
/// This service handles:
/// - Automatic window maximization on first launch
/// - Saving and restoring window size between sessions
/// - Saving and restoring maximized state
/// - Debounced state saving during window resize
///
/// Usage:
/// ```dart
/// final windowService = WindowService(storageService, windowManager);
/// await windowService.initialize();
/// ```
class WindowService extends WindowListener {
  final StorageService _storageService;
  final WindowManagerInterface _windowManager;
  Timer? _debounceTimer;

  static const Duration _debounceDuration = Duration(milliseconds: 500);
  static const Size _defaultSize = Size(1280, 720);
  static const double _minSize = 100.0;
  static const double _maxSize = 10000.0;

  WindowService(this._storageService, this._windowManager);

  /// Initializes the window service and restores window state.
  ///
  /// If no saved settings exist, maximizes the window on first launch.
  /// Otherwise, restores the previously saved size and maximized state.
  Future<void> initialize() async {
    _windowManager.addListener(this);

    try {
      final hasSettings = await _storageService.hasWindowSettings();

      if (!hasSettings) {
        await maximizeIfFirstLaunch();
      } else {
        await restoreWindowState();
      }
    } catch (e) {
      debugPrint('WindowService: Failed to initialize: $e');
      // Fallback to defaults
      await _applyWindowSize(_defaultSize);
      await _centerWindow();
    }
  }

  /// Maximizes the window on first launch and saves the state.
  Future<void> maximizeIfFirstLaunch() async {
    try {
      await _windowManager.waitUntilReadyToShow(null, () async {
        await _windowManager.maximize();
        await _windowManager.show();
      });
      await _storageService.saveWindowMaximized(true);
      debugPrint('WindowService: Maximized window on first launch');
    } catch (e) {
      debugPrint('WindowService: Failed to maximize on first launch: $e');
      // Fallback: set default size and center
      await _applyWindowSize(_defaultSize);
      await _centerWindow();
    }
  }

  /// Restores the window state from saved preferences.
  ///
  /// Validates saved sizes and falls back to defaults if invalid.
  Future<void> restoreWindowState() async {
    try {
      final maximized = await _storageService.isWindowMaximized();

      if (maximized == true) {
        await _windowManager.waitUntilReadyToShow(null, () async {
          await _windowManager.maximize();
          await _windowManager.show();
        });
        debugPrint('WindowService: Restored maximized state');
      } else {
        final size = await _storageService.getWindowSize();

        if (size != null && _isValidSize(size)) {
          await _windowManager.waitUntilReadyToShow(null, () async {
            await _applyWindowSize(size);
            await _centerWindow();
            await _windowManager.show();
          });
          debugPrint(
            'WindowService: Restored window size: ${size.width}x${size.height}',
          );
        } else {
          // Invalid or missing size: use default
          await _windowManager.waitUntilReadyToShow(null, () async {
            await _applyWindowSize(_defaultSize);
            await _centerWindow();
            await _windowManager.show();
          });
          debugPrint('WindowService: Used default window size');
        }
      }
    } catch (e) {
      debugPrint('WindowService: Failed to restore window state: $e');
      // Fallback to defaults
      await _applyWindowSize(_defaultSize);
      await _centerWindow();
    }
  }

  /// Saves the current window state (size and maximized status).
  Future<void> saveCurrentWindowState() async {
    try {
      final maximized = await _windowManager.isMaximized();
      await _storageService.saveWindowMaximized(maximized);

      if (!maximized) {
        final size = await _windowManager.getSize();
        await _storageService.saveWindowSize(size.width, size.height);
        debugPrint(
          'WindowService: Saved window state: ${size.width}x${size.height}, maximized: $maximized',
        );
      } else {
        debugPrint('WindowService: Saved maximized state');
      }
    } catch (e) {
      debugPrint('WindowService: Failed to save window state: $e');
    }
  }

  /// Disposes the window service and cancels any pending timers.
  void dispose() {
    _debounceTimer?.cancel();
    _windowManager.removeListener(this);
  }

  // WindowListener overrides

  @override
  void onWindowResized() {
    _debouncedSave();
  }

  @override
  void onWindowMaximize() {
    _debounceTimer?.cancel();
    saveCurrentWindowState();
  }

  @override
  void onWindowUnmaximize() {
    _debounceTimer?.cancel();
    saveCurrentWindowState();
  }

  // Private helper methods

  Future<void> _applyWindowSize(Size size) async {
    try {
      await _windowManager.setSize(size);
    } catch (e) {
      debugPrint('WindowService: Failed to set window size: $e');
    }
  }

  Future<void> _centerWindow() async {
    try {
      await _windowManager.center();
    } catch (e) {
      debugPrint('WindowService: Failed to center window: $e');
    }
  }

  bool _isValidSize(Size size) {
    return size.width >= _minSize &&
        size.width < _maxSize &&
        size.height >= _minSize &&
        size.height < _maxSize;
  }

  void _debouncedSave() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () async {
      final maximized = await _windowManager.isMaximized();
      if (!maximized) {
        await saveCurrentWindowState();
      }
    });
  }
}
