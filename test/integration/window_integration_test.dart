import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:darkfeed/services/window_service.dart';
import '../helpers/mock_storage_service.mocks.dart';
import '../helpers/mock_window_manager.mocks.dart';
import '../helpers/test_fixtures.dart';

void main() {
  late MockStorageService mockStorage;
  late MockWindowManagerInterface mockWindowManager;
  late WindowService windowService;

  setUp(() {
    mockStorage = MockStorageService();
    mockWindowManager = MockWindowManagerInterface();
    windowService = WindowService(mockStorage, mockWindowManager);

    // Default mock setup for common operations
    when(mockWindowManager.addListener(any)).thenReturn(null);
    when(mockWindowManager.removeListener(any)).thenReturn(null);
  });

  tearDown(() {
    windowService.dispose();
  });

  group('Integration - First Launch Flow', () {
    test('should maximize window on first launch and save state', () async {
      // Arrange: No existing settings
      when(mockStorage.hasWindowSettings()).thenAnswer((_) async => false);
      when(mockWindowManager.waitUntilReadyToShow(any, any)).thenAnswer((
        invocation,
      ) async {
        final callback = invocation.positionalArguments[1] as Function;
        await callback();
      });
      when(mockWindowManager.maximize()).thenAnswer((_) async {});
      when(mockWindowManager.show()).thenAnswer((_) async {});
      when(mockWindowManager.isMaximized()).thenAnswer((_) async => true);
      when(mockStorage.saveWindowMaximized(any)).thenAnswer((_) async {});

      // Act: Initialize window service
      await windowService.initialize();

      // Assert: Window was maximized
      verify(mockWindowManager.maximize()).called(1);
      verify(mockWindowManager.show()).called(1);

      // Simulate the maximize event that would be triggered by the window manager
      windowService.onWindowMaximize();
      await Future.delayed(const Duration(milliseconds: 50));

      // Assert: Maximized state was saved at least once
      // Note: It may be saved during maximize call and/or during the event
      verify(
        mockStorage.saveWindowMaximized(true),
      ).called(greaterThanOrEqualTo(1));
    });

    test(
      'should handle first launch with default size fallback on maximize failure',
      () async {
        // Arrange: No existing settings, maximize fails
        when(mockStorage.hasWindowSettings()).thenAnswer((_) async => false);
        when(mockWindowManager.waitUntilReadyToShow(any, any)).thenAnswer((
          invocation,
        ) async {
          final callback = invocation.positionalArguments[1] as Function;
          await callback();
        });
        when(
          mockWindowManager.maximize(),
        ).thenThrow(Exception('Maximize failed'));
        when(mockWindowManager.show()).thenAnswer((_) async {});
        when(mockWindowManager.setSize(any)).thenAnswer((_) async {});
        when(mockWindowManager.center()).thenAnswer((_) async {});

        // Act: Initialize window service (should fall back gracefully)
        await windowService.initialize();

        // Assert: Fallback size was applied
        verify(
          mockWindowManager.setSize(WindowTestFixtures.defaultSize),
        ).called(1);
        verify(mockWindowManager.center()).called(1);
      },
    );
  });

  group('Integration - Resize and Restore Flow', () {
    test(
      'should save window size on resize and restore it on next launch',
      () async {
        // Arrange: Setup for resize event
        const customSize = WindowTestFixtures.customSize;
        when(mockStorage.hasWindowSettings()).thenAnswer((_) async => false);
        when(mockWindowManager.waitUntilReadyToShow(any, any)).thenAnswer((
          invocation,
        ) async {
          final callback = invocation.positionalArguments[1] as Function;
          await callback();
        });
        when(mockWindowManager.maximize()).thenAnswer((_) async {});
        when(mockWindowManager.show()).thenAnswer((_) async {});
        when(mockWindowManager.getSize()).thenAnswer((_) async => customSize);
        when(mockWindowManager.isMaximized()).thenAnswer((_) async => false);
        when(mockStorage.saveWindowSize(any, any)).thenAnswer((_) async {});
        when(mockStorage.saveWindowMaximized(any)).thenAnswer((_) async {});

        // Act: Initialize and trigger resize
        await windowService.initialize();
        windowService.onWindowResized();

        // Wait for debounce
        await Future.delayed(const Duration(milliseconds: 600));

        // Assert: Size was saved
        verify(
          mockStorage.saveWindowSize(customSize.width, customSize.height),
        ).called(1);
        verify(mockStorage.saveWindowMaximized(false)).called(1);

        // Simulate next launch
        reset(mockStorage);
        reset(mockWindowManager);
        when(mockWindowManager.addListener(any)).thenReturn(null);
        when(mockWindowManager.removeListener(any)).thenReturn(null);
        when(mockStorage.hasWindowSettings()).thenAnswer((_) async => true);
        when(mockStorage.isWindowMaximized()).thenAnswer((_) async => false);
        when(mockStorage.getWindowSize()).thenAnswer((_) async => customSize);
        when(mockWindowManager.waitUntilReadyToShow(any, any)).thenAnswer((
          invocation,
        ) async {
          final callback = invocation.positionalArguments[1] as Function;
          await callback();
        });
        when(mockWindowManager.setSize(any)).thenAnswer((_) async {});
        when(mockWindowManager.center()).thenAnswer((_) async {});
        when(mockWindowManager.show()).thenAnswer((_) async {});

        final newWindowService = WindowService(mockStorage, mockWindowManager);
        await newWindowService.initialize();

        // Assert: Restored to saved size
        verify(mockWindowManager.setSize(customSize)).called(1);
        verify(mockWindowManager.center()).called(1);

        newWindowService.dispose();
      },
    );

    test('should handle rapid resize events with debouncing', () async {
      // Arrange
      when(mockStorage.hasWindowSettings()).thenAnswer((_) async => false);
      when(mockWindowManager.waitUntilReadyToShow(any, any)).thenAnswer((
        invocation,
      ) async {
        final callback = invocation.positionalArguments[1] as Function;
        await callback();
      });
      when(mockWindowManager.maximize()).thenAnswer((_) async {});
      when(mockWindowManager.show()).thenAnswer((_) async {});
      when(
        mockWindowManager.getSize(),
      ).thenAnswer((_) async => WindowTestFixtures.customSize);
      when(mockWindowManager.isMaximized()).thenAnswer((_) async => false);
      when(mockStorage.saveWindowSize(any, any)).thenAnswer((_) async {});
      when(mockStorage.saveWindowMaximized(any)).thenAnswer((_) async {});

      // Act: Initialize and trigger multiple rapid resizes
      await windowService.initialize();

      // Trigger 5 resize events rapidly
      for (int i = 0; i < 5; i++) {
        windowService.onWindowResized();
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // Wait for debounce to complete
      await Future.delayed(const Duration(milliseconds: 600));

      // Assert: Size was saved only once (debounced)
      verify(mockStorage.saveWindowSize(any, any)).called(1);
    });
  });

  group('Integration - Maximize Toggle Flow', () {
    test('should handle maximize -> unmaximize -> restore flow', () async {
      // Arrange: Start with saved non-maximized size
      const initialSize = WindowTestFixtures.customSize;
      when(mockStorage.hasWindowSettings()).thenAnswer((_) async => true);
      when(mockStorage.isWindowMaximized()).thenAnswer((_) async => false);
      when(mockStorage.getWindowSize()).thenAnswer((_) async => initialSize);
      when(mockWindowManager.waitUntilReadyToShow(any, any)).thenAnswer((
        invocation,
      ) async {
        final callback = invocation.positionalArguments[1] as Function;
        await callback();
      });
      when(mockWindowManager.setSize(any)).thenAnswer((_) async {});
      when(mockWindowManager.center()).thenAnswer((_) async {});
      when(mockWindowManager.show()).thenAnswer((_) async {});
      when(mockStorage.saveWindowMaximized(any)).thenAnswer((_) async {});
      when(mockStorage.saveWindowSize(any, any)).thenAnswer((_) async {});
      when(mockWindowManager.getSize()).thenAnswer((_) async => initialSize);
      when(mockWindowManager.isMaximized()).thenAnswer((_) async => false);

      // Act: Initialize with non-maximized size
      await windowService.initialize();

      // User maximizes window
      when(mockWindowManager.isMaximized()).thenAnswer((_) async => true);
      windowService.onWindowMaximize();
      await Future.delayed(const Duration(milliseconds: 50));

      // Assert: Maximized state saved
      verify(mockStorage.saveWindowMaximized(true)).called(1);

      // Act: User unmaximizes window (returns to previous size)
      when(mockWindowManager.isMaximized()).thenAnswer((_) async => false);
      windowService.onWindowUnmaximize();
      await Future.delayed(const Duration(milliseconds: 50));

      // Assert: Non-maximized state and size saved
      verify(mockStorage.saveWindowMaximized(false)).called(1);
      verify(
        mockStorage.saveWindowSize(initialSize.width, initialSize.height),
      ).called(1);

      // Simulate next launch
      reset(mockStorage);
      reset(mockWindowManager);
      when(mockWindowManager.addListener(any)).thenReturn(null);
      when(mockWindowManager.removeListener(any)).thenReturn(null);
      when(mockStorage.hasWindowSettings()).thenAnswer((_) async => true);
      when(mockStorage.isWindowMaximized()).thenAnswer((_) async => false);
      when(mockStorage.getWindowSize()).thenAnswer((_) async => initialSize);
      when(mockWindowManager.waitUntilReadyToShow(any, any)).thenAnswer((
        invocation,
      ) async {
        final callback = invocation.positionalArguments[1] as Function;
        await callback();
      });
      when(mockWindowManager.setSize(any)).thenAnswer((_) async {});
      when(mockWindowManager.center()).thenAnswer((_) async {});
      when(mockWindowManager.show()).thenAnswer((_) async {});

      final newWindowService = WindowService(mockStorage, mockWindowManager);
      await newWindowService.initialize();

      // Assert: Restored to unmaximized size
      verify(mockWindowManager.setSize(initialSize)).called(1);

      newWindowService.dispose();
    });

    test('should restore maximized state correctly on launch', () async {
      // Arrange: Previously maximized
      when(mockStorage.hasWindowSettings()).thenAnswer((_) async => true);
      when(mockStorage.isWindowMaximized()).thenAnswer((_) async => true);
      when(mockWindowManager.waitUntilReadyToShow(any, any)).thenAnswer((
        invocation,
      ) async {
        final callback = invocation.positionalArguments[1] as Function;
        await callback();
      });
      when(mockWindowManager.maximize()).thenAnswer((_) async {});
      when(mockWindowManager.show()).thenAnswer((_) async {});

      // Act: Initialize
      await windowService.initialize();

      // Assert: Window was maximized
      verify(mockWindowManager.maximize()).called(1);
      verify(mockWindowManager.show()).called(1);

      // Size setters should NOT be called when maximized
      verifyNever(mockWindowManager.setSize(any));
    });
  });

  group('Integration - Error Handling', () {
    test('should gracefully handle storage read errors', () async {
      // Arrange: Storage throws error
      when(
        mockStorage.hasWindowSettings(),
      ).thenThrow(Exception('Storage error'));
      when(mockWindowManager.setSize(any)).thenAnswer((_) async {});
      when(mockWindowManager.center()).thenAnswer((_) async {});

      // Act: Initialize (should not throw)
      await windowService.initialize();

      // Assert: Fell back to default size
      verify(
        mockWindowManager.setSize(WindowTestFixtures.defaultSize),
      ).called(1);
      verify(mockWindowManager.center()).called(1);
    });

    test('should handle window manager errors gracefully', () async {
      // Arrange: Window manager operations fail
      when(mockStorage.hasWindowSettings()).thenAnswer((_) async => false);
      when(
        mockWindowManager.waitUntilReadyToShow(any, any),
      ).thenThrow(Exception('Window manager error'));
      when(mockWindowManager.setSize(any)).thenAnswer((_) async {});
      when(mockWindowManager.center()).thenAnswer((_) async {});

      // Act: Initialize (should not throw)
      await windowService.initialize();

      // Assert: Attempted fallback
      verify(
        mockWindowManager.setSize(WindowTestFixtures.defaultSize),
      ).called(1);
    });
  });
}
