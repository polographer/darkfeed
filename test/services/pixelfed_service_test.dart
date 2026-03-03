import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:darkfeed/services/pixelfed_service.dart';
import '../helpers/mock_storage_service.mocks.dart';

void main() {
  late MockStorageService mockStorage;
  late PixelfedService pixelfedService;

  setUp(() {
    mockStorage = MockStorageService();
    pixelfedService = PixelfedService(mockStorage);
  });

  group('PixelfedService - Initialization', () {
    test('initialize throws when no access token', () async {
      // Arrange
      when(mockStorage.getAccessToken()).thenAnswer((_) async => null);
      when(
        mockStorage.getInstanceUrl(),
      ).thenAnswer((_) async => 'https://pixelfed.social');

      // Act & Assert
      expect(
        () => pixelfedService.initialize(),
        throwsA(
          isA<PixelfedException>().having(
            (e) => e.message,
            'message',
            'Not authenticated',
          ),
        ),
      );
    });

    test('initialize throws when no instance URL', () async {
      // Arrange
      when(mockStorage.getAccessToken()).thenAnswer((_) async => 'test_token');
      when(mockStorage.getInstanceUrl()).thenAnswer((_) async => null);

      // Act & Assert
      expect(
        () => pixelfedService.initialize(),
        throwsA(
          isA<PixelfedException>().having(
            (e) => e.message,
            'message',
            'Not authenticated',
          ),
        ),
      );
    });

    test('initialize succeeds with valid credentials', () async {
      // Arrange
      when(mockStorage.getAccessToken()).thenAnswer((_) async => 'test_token');
      when(
        mockStorage.getInstanceUrl(),
      ).thenAnswer((_) async => 'https://pixelfed.social');

      // Act
      await pixelfedService.initialize();

      // Assert: No exception thrown
      verify(mockStorage.getAccessToken()).called(1);
      verify(mockStorage.getInstanceUrl()).called(1);
    });
  });

  group('PixelfedService - Not Initialized', () {
    test('getCurrentUser throws when not initialized', () async {
      // Act & Assert
      expect(
        () => pixelfedService.getCurrentUser(),
        throwsA(
          isA<PixelfedException>().having(
            (e) => e.message,
            'message',
            contains('not initialized'),
          ),
        ),
      );
    });

    test('getHomeTimeline throws when not initialized', () async {
      // Act & Assert
      expect(
        () => pixelfedService.getHomeTimeline(),
        throwsA(
          isA<PixelfedException>().having(
            (e) => e.message,
            'message',
            contains('not initialized'),
          ),
        ),
      );
    });

    test('likePost throws when not initialized', () async {
      // Act & Assert
      expect(
        () => pixelfedService.likePost('123'),
        throwsA(
          isA<PixelfedException>().having(
            (e) => e.message,
            'message',
            contains('not initialized'),
          ),
        ),
      );
    });

    test('getComments throws when not initialized', () async {
      // Act & Assert
      expect(
        () => pixelfedService.getComments('123'),
        throwsA(
          isA<PixelfedException>().having(
            (e) => e.message,
            'message',
            contains('not initialized'),
          ),
        ),
      );
    });

    test('getUserProfile throws when not initialized', () async {
      // Act & Assert
      expect(
        () => pixelfedService.getUserProfile('123'),
        throwsA(
          isA<PixelfedException>().having(
            (e) => e.message,
            'message',
            contains('not initialized'),
          ),
        ),
      );
    });

    test('getUserPosts throws when not initialized', () async {
      // Act & Assert
      expect(
        () => pixelfedService.getUserPosts(userId: '123'),
        throwsA(
          isA<PixelfedException>().having(
            (e) => e.message,
            'message',
            contains('not initialized'),
          ),
        ),
      );
    });
  });

  group('PixelfedService - Dispose', () {
    test('dispose clears credentials', () async {
      // Arrange
      when(mockStorage.getAccessToken()).thenAnswer((_) async => 'test_token');
      when(
        mockStorage.getInstanceUrl(),
      ).thenAnswer((_) async => 'https://pixelfed.social');
      await pixelfedService.initialize();

      // Act
      pixelfedService.dispose();

      // Assert: After dispose, should throw not initialized error
      expect(
        () => pixelfedService.getHomeTimeline(),
        throwsA(isA<PixelfedException>()),
      );
    });

    test('dispose can be called multiple times safely', () {
      // Act & Assert: Should not throw
      pixelfedService.dispose();
      pixelfedService.dispose();
      pixelfedService.dispose();
    });
  });

  group('PixelfedException', () {
    test('creates exception with message', () {
      // Arrange & Act
      final exception = PixelfedException('Test error');

      // Assert
      expect(exception.message, 'Test error');
      expect(exception.toString(), 'Test error');
    });

    test('can be thrown and caught', () {
      // Arrange
      void throwError() {
        throw PixelfedException('API error');
      }

      // Act & Assert
      expect(
        () => throwError(),
        throwsA(
          isA<PixelfedException>().having(
            (e) => e.message,
            'message',
            'API error',
          ),
        ),
      );
    });
  });

  group('PixelfedService - State Management', () {
    test('maintains state after initialization', () async {
      // Arrange
      when(mockStorage.getAccessToken()).thenAnswer((_) async => 'token123');
      when(
        mockStorage.getInstanceUrl(),
      ).thenAnswer((_) async => 'https://test.com');

      // Act
      await pixelfedService.initialize();

      // Assert: Storage should only be called once during init
      verify(mockStorage.getAccessToken()).called(1);
      verify(mockStorage.getInstanceUrl()).called(1);
      verifyNoMoreInteractions(mockStorage);
    });

    test('can be re-initialized with new credentials', () async {
      // Arrange: First initialization
      when(mockStorage.getAccessToken()).thenAnswer((_) async => 'token1');
      when(
        mockStorage.getInstanceUrl(),
      ).thenAnswer((_) async => 'https://a.com');
      await pixelfedService.initialize();

      // Act: Re-initialize with new credentials
      when(mockStorage.getAccessToken()).thenAnswer((_) async => 'token2');
      when(
        mockStorage.getInstanceUrl(),
      ).thenAnswer((_) async => 'https://b.com');
      await pixelfedService.initialize();

      // Assert: Should be called twice (once for each init)
      verify(mockStorage.getAccessToken()).called(2);
      verify(mockStorage.getInstanceUrl()).called(2);
    });

    test('handles initialization errors gracefully', () async {
      // Arrange
      when(mockStorage.getAccessToken()).thenThrow(Exception('Storage error'));
      when(
        mockStorage.getInstanceUrl(),
      ).thenAnswer((_) async => 'https://test.com');

      // Act & Assert
      expect(() => pixelfedService.initialize(), throwsA(isA<Exception>()));
    });
  });

  group('PixelfedService - Multiple Instances', () {
    test('different instances maintain independent state', () async {
      // Arrange
      final service1 = PixelfedService(mockStorage);
      final service2 = PixelfedService(mockStorage);

      when(mockStorage.getAccessToken()).thenAnswer((_) async => 'token');
      when(
        mockStorage.getInstanceUrl(),
      ).thenAnswer((_) async => 'https://test.com');

      // Act
      await service1.initialize();

      // Assert: service1 initialized, service2 not
      expect(
        () => service2.getHomeTimeline(),
        throwsA(isA<PixelfedException>()),
      );

      // Act: Initialize service2
      await service2.initialize();

      // Both services should be usable now (though they'll fail without HTTP mocking)
      verify(mockStorage.getAccessToken()).called(2);
      verify(mockStorage.getInstanceUrl()).called(2);
    });

    test('disposing one instance does not affect others', () async {
      // Arrange
      final service1 = PixelfedService(mockStorage);
      final service2 = PixelfedService(mockStorage);

      when(mockStorage.getAccessToken()).thenAnswer((_) async => 'token');
      when(
        mockStorage.getInstanceUrl(),
      ).thenAnswer((_) async => 'https://test.com');

      await service1.initialize();
      await service2.initialize();

      // Act: Dispose service1
      service1.dispose();

      // Assert: service1 throws, but storage calls still from init
      expect(
        () => service1.getHomeTimeline(),
        throwsA(isA<PixelfedException>()),
      );

      // service2 should still throw (because we haven't mocked HTTP)
      // but for different reason (HTTP error, not initialization error)
      expect(() => service2.getHomeTimeline(), throwsA(isA<Exception>()));
    });
  });

  group('PixelfedService - Error Messages', () {
    test('not initialized error message is clear', () async {
      // Act & Assert
      try {
        await pixelfedService.getCurrentUser();
        fail('Should have thrown');
      } catch (e) {
        expect(e, isA<PixelfedException>());
        final exception = e as PixelfedException;
        expect(exception.message.toLowerCase(), contains('initialize'));
      }
    });

    test('not authenticated error message is clear', () async {
      // Arrange
      when(mockStorage.getAccessToken()).thenAnswer((_) async => null);
      when(mockStorage.getInstanceUrl()).thenAnswer((_) async => null);

      // Act & Assert
      try {
        await pixelfedService.initialize();
        fail('Should have thrown');
      } catch (e) {
        expect(e, isA<PixelfedException>());
        final exception = e as PixelfedException;
        expect(exception.message.toLowerCase(), contains('authenticated'));
      }
    });
  });
}
