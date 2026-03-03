import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:darkfeed/services/window_service.dart';
import '../helpers/mock_storage_service.mocks.dart';
import '../helpers/mock_window_manager.mocks.dart';
import '../helpers/test_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockStorageService mockStorage;
  late MockWindowManagerInterface mockWindowManager;
  late WindowService windowService;

  setUp(() {
    mockStorage = MockStorageService();
    mockWindowManager = MockWindowManagerInterface();
    windowService = WindowService(mockStorage, mockWindowManager);
  });

  tearDown(() {
    windowService.dispose();
  });

  group('First Launch', () {
    test('should maximize window when no settings exist', () async {
      when(mockStorage.hasWindowSettings()).thenAnswer((_) async => false);
      when(mockWindowManager.waitUntilReadyToShow(any, any)).thenAnswer((
        invocation,
      ) async {
        final callback = invocation.positionalArguments[1] as Function;
        await callback();
      });
      when(mockWindowManager.maximize()).thenAnswer((_) async {});
      when(mockWindowManager.show()).thenAnswer((_) async {});
      when(mockStorage.saveWindowMaximized(any)).thenAnswer((_) async {});

      await windowService.initialize();

      verify(mockWindowManager.maximize()).called(1);
      verify(mockStorage.saveWindowMaximized(true)).called(1);
    });

    test(
      'should save maximized state after maximizing on first launch',
      () async {
        when(mockStorage.hasWindowSettings()).thenAnswer((_) async => false);
        when(mockWindowManager.waitUntilReadyToShow(any, any)).thenAnswer((
          invocation,
        ) async {
          final callback = invocation.positionalArguments[1] as Function;
          await callback();
        });
        when(mockWindowManager.maximize()).thenAnswer((_) async {});
        when(mockWindowManager.show()).thenAnswer((_) async {});
        when(mockStorage.saveWindowMaximized(any)).thenAnswer((_) async {});

        await windowService.initialize();

        verify(mockStorage.saveWindowMaximized(true)).called(1);
      },
    );
  });

  group('Restore Window State', () {
    test('should restore saved window size when not maximized', () async {
      when(mockStorage.hasWindowSettings()).thenAnswer((_) async => true);
      when(mockStorage.isWindowMaximized()).thenAnswer((_) async => false);
      when(
        mockStorage.getWindowSize(),
      ).thenAnswer((_) async => WindowTestFixtures.customSize);
      when(mockWindowManager.waitUntilReadyToShow(any, any)).thenAnswer((
        invocation,
      ) async {
        final callback = invocation.positionalArguments[1] as Function;
        await callback();
      });
      when(mockWindowManager.setSize(any)).thenAnswer((_) async {});
      when(mockWindowManager.center()).thenAnswer((_) async {});
      when(mockWindowManager.show()).thenAnswer((_) async {});

      await windowService.initialize();

      verify(
        mockWindowManager.setSize(WindowTestFixtures.customSize),
      ).called(1);
      verify(mockWindowManager.center()).called(1);
    });

    test('should restore maximized state when saved as maximized', () async {
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

      await windowService.initialize();

      verify(mockWindowManager.maximize()).called(1);
    });

    test('should use default size when saved size is invalid (0x0)', () async {
      when(mockStorage.hasWindowSettings()).thenAnswer((_) async => true);
      when(mockStorage.isWindowMaximized()).thenAnswer((_) async => false);
      when(
        mockStorage.getWindowSize(),
      ).thenAnswer((_) async => WindowTestFixtures.invalidSize);
      when(mockWindowManager.waitUntilReadyToShow(any, any)).thenAnswer((
        invocation,
      ) async {
        final callback = invocation.positionalArguments[1] as Function;
        await callback();
      });
      when(mockWindowManager.setSize(any)).thenAnswer((_) async {});
      when(mockWindowManager.center()).thenAnswer((_) async {});
      when(mockWindowManager.show()).thenAnswer((_) async {});

      await windowService.initialize();

      verify(
        mockWindowManager.setSize(WindowTestFixtures.defaultSize),
      ).called(1);
    });

    test('should use default size when saved size is negative', () async {
      when(mockStorage.hasWindowSettings()).thenAnswer((_) async => true);
      when(mockStorage.isWindowMaximized()).thenAnswer((_) async => false);
      when(
        mockStorage.getWindowSize(),
      ).thenAnswer((_) async => WindowTestFixtures.negativeSize);
      when(mockWindowManager.waitUntilReadyToShow(any, any)).thenAnswer((
        invocation,
      ) async {
        final callback = invocation.positionalArguments[1] as Function;
        await callback();
      });
      when(mockWindowManager.setSize(any)).thenAnswer((_) async {});
      when(mockWindowManager.center()).thenAnswer((_) async {});
      when(mockWindowManager.show()).thenAnswer((_) async {});

      await windowService.initialize();

      verify(
        mockWindowManager.setSize(WindowTestFixtures.defaultSize),
      ).called(1);
    });

    test('should use default size when saved size is too large', () async {
      when(mockStorage.hasWindowSettings()).thenAnswer((_) async => true);
      when(mockStorage.isWindowMaximized()).thenAnswer((_) async => false);
      when(
        mockStorage.getWindowSize(),
      ).thenAnswer((_) async => WindowTestFixtures.offscreenSize);
      when(mockWindowManager.waitUntilReadyToShow(any, any)).thenAnswer((
        invocation,
      ) async {
        final callback = invocation.positionalArguments[1] as Function;
        await callback();
      });
      when(mockWindowManager.setSize(any)).thenAnswer((_) async {});
      when(mockWindowManager.center()).thenAnswer((_) async {});
      when(mockWindowManager.show()).thenAnswer((_) async {});

      await windowService.initialize();

      verify(
        mockWindowManager.setSize(WindowTestFixtures.defaultSize),
      ).called(1);
    });

    test('should center window after restoring valid size', () async {
      when(mockStorage.hasWindowSettings()).thenAnswer((_) async => true);
      when(mockStorage.isWindowMaximized()).thenAnswer((_) async => false);
      when(
        mockStorage.getWindowSize(),
      ).thenAnswer((_) async => WindowTestFixtures.hdSize);
      when(mockWindowManager.waitUntilReadyToShow(any, any)).thenAnswer((
        invocation,
      ) async {
        final callback = invocation.positionalArguments[1] as Function;
        await callback();
      });
      when(mockWindowManager.setSize(any)).thenAnswer((_) async {});
      when(mockWindowManager.center()).thenAnswer((_) async {});
      when(mockWindowManager.show()).thenAnswer((_) async {});

      await windowService.initialize();

      verify(mockWindowManager.center()).called(1);
    });
  });

  group('Save Window State', () {
    test('should save current window size and maximized state', () async {
      when(mockWindowManager.isMaximized()).thenAnswer((_) async => false);
      when(
        mockWindowManager.getSize(),
      ).thenAnswer((_) async => WindowTestFixtures.customSize);
      when(mockStorage.saveWindowMaximized(any)).thenAnswer((_) async {});
      when(mockStorage.saveWindowSize(any, any)).thenAnswer((_) async {});

      await windowService.saveCurrentWindowState();

      verify(mockStorage.saveWindowMaximized(false)).called(1);
      verify(mockStorage.saveWindowSize(1600, 900)).called(1);
    });

    test('should save only maximized state when maximized', () async {
      when(mockWindowManager.isMaximized()).thenAnswer((_) async => true);
      when(mockStorage.saveWindowMaximized(any)).thenAnswer((_) async {});

      await windowService.saveCurrentWindowState();

      verify(mockStorage.saveWindowMaximized(true)).called(1);
      verifyNever(mockStorage.saveWindowSize(any, any));
    });
  });

  group('Window Events', () {
    test('should immediately save maximized=true on maximize event', () async {
      when(mockWindowManager.isMaximized()).thenAnswer((_) async => true);
      when(mockStorage.saveWindowMaximized(any)).thenAnswer((_) async {});

      windowService.onWindowMaximize();

      await Future.delayed(const Duration(milliseconds: 50));

      verify(mockStorage.saveWindowMaximized(true)).called(1);
    });

    test(
      'should immediately save maximized=false on unmaximize event',
      () async {
        when(mockWindowManager.isMaximized()).thenAnswer((_) async => false);
        when(
          mockWindowManager.getSize(),
        ).thenAnswer((_) async => WindowTestFixtures.hdSize);
        when(mockStorage.saveWindowMaximized(any)).thenAnswer((_) async {});
        when(mockStorage.saveWindowSize(any, any)).thenAnswer((_) async {});

        windowService.onWindowUnmaximize();

        await Future.delayed(const Duration(milliseconds: 50));

        verify(mockStorage.saveWindowMaximized(false)).called(1);
        verify(mockStorage.saveWindowSize(any, any)).called(1);
      },
    );

    test('should debounce resize events', () async {
      when(mockWindowManager.isMaximized()).thenAnswer((_) async => false);
      when(
        mockWindowManager.getSize(),
      ).thenAnswer((_) async => WindowTestFixtures.customSize);
      when(mockStorage.saveWindowMaximized(any)).thenAnswer((_) async {});
      when(mockStorage.saveWindowSize(any, any)).thenAnswer((_) async {});

      // Trigger multiple rapid resize events
      windowService.onWindowResized();
      windowService.onWindowResized();
      windowService.onWindowResized();

      // Should not save immediately
      await Future.delayed(const Duration(milliseconds: 100));
      verifyNever(mockStorage.saveWindowSize(any, any));

      // Should save after debounce delay
      await Future.delayed(const Duration(milliseconds: 500));
      verify(mockStorage.saveWindowSize(1600, 900)).called(1);
    });
  });

  group('Lifecycle', () {
    test('should add listener during initialize()', () async {
      when(mockStorage.hasWindowSettings()).thenAnswer((_) async => false);
      when(mockWindowManager.waitUntilReadyToShow(any, any)).thenAnswer((
        invocation,
      ) async {
        final callback = invocation.positionalArguments[1] as Function;
        await callback();
      });
      when(mockWindowManager.maximize()).thenAnswer((_) async {});
      when(mockWindowManager.show()).thenAnswer((_) async {});
      when(mockStorage.saveWindowMaximized(any)).thenAnswer((_) async {});

      await windowService.initialize();

      verify(mockWindowManager.addListener(windowService)).called(1);
    });

    test('should remove listener during dispose()', () {
      windowService.dispose();

      verify(mockWindowManager.removeListener(windowService)).called(1);
    });
  });
}
