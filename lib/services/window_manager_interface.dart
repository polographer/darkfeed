import 'dart:ui';

import 'package:window_manager/window_manager.dart';

/// Abstract interface for window manager operations.
///
/// This interface wraps the window_manager package to enable clean mocking
/// and dependency injection in tests.
abstract class WindowManagerInterface {
  /// Ensures the window manager is initialized.
  Future<void> ensureInitialized();

  /// Waits until the window is ready to show, then executes callback.
  Future<void> waitUntilReadyToShow(
    WindowOptions? options,
    VoidCallback callback,
  );

  /// Maximizes the window.
  Future<void> maximize();

  /// Unmaximizes (restores) the window.
  Future<void> unmaximize();

  /// Sets the window size.
  Future<void> setSize(Size size, {bool animate = false});

  /// Gets the current window size.
  Future<Size> getSize();

  /// Checks if the window is currently maximized.
  Future<bool> isMaximized();

  /// Centers the window on screen.
  Future<void> center({bool animate = false});

  /// Shows the window.
  Future<void> show({bool inactive = false});

  /// Adds a window event listener.
  void addListener(WindowListener listener);

  /// Removes a window event listener.
  void removeListener(WindowListener listener);
}
