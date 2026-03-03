import 'dart:ui';

import 'package:darkfeed/services/window_manager_interface.dart';
import 'package:window_manager/window_manager.dart';

/// Concrete implementation of WindowManagerInterface that wraps the
/// window_manager package.
class WindowManagerImpl implements WindowManagerInterface {
  @override
  Future<void> ensureInitialized() => windowManager.ensureInitialized();

  @override
  Future<void> waitUntilReadyToShow(
    WindowOptions? options,
    VoidCallback callback,
  ) => windowManager.waitUntilReadyToShow(options, callback);

  @override
  Future<void> maximize() => windowManager.maximize();

  @override
  Future<void> unmaximize() => windowManager.unmaximize();

  @override
  Future<void> setSize(Size size, {bool animate = false}) =>
      windowManager.setSize(size, animate: animate);

  @override
  Future<Size> getSize() => windowManager.getSize();

  @override
  Future<bool> isMaximized() => windowManager.isMaximized();

  @override
  Future<void> center({bool animate = false}) =>
      windowManager.center(animate: animate);

  @override
  Future<void> show({bool inactive = false}) =>
      windowManager.show(inactive: inactive);

  @override
  void addListener(WindowListener listener) =>
      windowManager.addListener(listener);

  @override
  void removeListener(WindowListener listener) =>
      windowManager.removeListener(listener);
}
