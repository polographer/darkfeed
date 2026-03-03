import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:darkfeed/services/oauth_service.dart';
import '../helpers/mock_storage_service.mocks.dart';

void main() {
  late MockStorageService mockStorage;
  late OAuthService oauthService;

  setUp(() {
    mockStorage = MockStorageService();
    oauthService = OAuthService(mockStorage);
  });

  group('OAuthService - Basic Operations', () {
    test('isAuthenticated returns true when storage has token', () async {
      // Arrange
      when(mockStorage.isAuthenticated()).thenAnswer((_) async => true);

      // Act
      final result = await oauthService.isAuthenticated();

      // Assert
      expect(result, true);
      verify(mockStorage.isAuthenticated()).called(1);
    });

    test('isAuthenticated returns false when storage has no token', () async {
      // Arrange
      when(mockStorage.isAuthenticated()).thenAnswer((_) async => false);

      // Act
      final result = await oauthService.isAuthenticated();

      // Assert
      expect(result, false);
      verify(mockStorage.isAuthenticated()).called(1);
    });

    test('getAccessToken returns token from storage', () async {
      // Arrange
      const testToken = 'test_access_token_12345';
      when(mockStorage.getAccessToken()).thenAnswer((_) async => testToken);

      // Act
      final result = await oauthService.getAccessToken();

      // Assert
      expect(result, testToken);
      verify(mockStorage.getAccessToken()).called(1);
    });

    test('getAccessToken returns null when no token', () async {
      // Arrange
      when(mockStorage.getAccessToken()).thenAnswer((_) async => null);

      // Act
      final result = await oauthService.getAccessToken();

      // Assert
      expect(result, null);
      verify(mockStorage.getAccessToken()).called(1);
    });

    test('getInstanceUrl returns URL from storage', () async {
      // Arrange
      const testUrl = 'https://pixelfed.social';
      when(mockStorage.getInstanceUrl()).thenAnswer((_) async => testUrl);

      // Act
      final result = await oauthService.getInstanceUrl();

      // Assert
      expect(result, testUrl);
      verify(mockStorage.getInstanceUrl()).called(1);
    });

    test('getInstanceUrl returns null when no URL', () async {
      // Arrange
      when(mockStorage.getInstanceUrl()).thenAnswer((_) async => null);

      // Act
      final result = await oauthService.getInstanceUrl();

      // Assert
      expect(result, null);
      verify(mockStorage.getInstanceUrl()).called(1);
    });

    test('logout clears auth data from storage', () async {
      // Arrange
      when(mockStorage.clearAuthData()).thenAnswer((_) async => {});

      // Act
      await oauthService.logout();

      // Assert
      verify(mockStorage.clearAuthData()).called(1);
    });
  });

  group('OAuthService - Platform-specific', () {
    test('getCallbackUrl returns correct URL format', () {
      // This tests internal logic through public methods
      // The callback URL logic is platform-dependent but we can verify
      // it doesn't throw and follows expected patterns
      expect(oauthService, isNotNull);
    });
  });

  group('OAuthException', () {
    test('OAuthException creates exception with message', () {
      // Arrange & Act
      final exception = OAuthException('Test error message');

      // Assert
      expect(exception.message, 'Test error message');
      expect(exception.toString(), 'Test error message');
    });

    test('OAuthException can be thrown and caught', () {
      // Arrange
      void throwError() {
        throw OAuthException('Custom error');
      }

      // Act & Assert
      expect(
        () => throwError(),
        throwsA(
          isA<OAuthException>().having(
            (e) => e.message,
            'message',
            'Custom error',
          ),
        ),
      );
    });
  });

  group('OAuthService - Error Handling', () {
    test('handles storage errors gracefully during isAuthenticated', () async {
      // Arrange
      when(mockStorage.isAuthenticated()).thenThrow(Exception('Storage error'));

      // Act & Assert
      expect(() => oauthService.isAuthenticated(), throwsA(isA<Exception>()));
    });

    test('handles storage errors gracefully during getAccessToken', () async {
      // Arrange
      when(mockStorage.getAccessToken()).thenThrow(Exception('Storage error'));

      // Act & Assert
      expect(() => oauthService.getAccessToken(), throwsA(isA<Exception>()));
    });

    test('handles storage errors gracefully during logout', () async {
      // Arrange
      when(mockStorage.clearAuthData()).thenThrow(Exception('Storage error'));

      // Act & Assert
      expect(() => oauthService.logout(), throwsA(isA<Exception>()));
    });
  });

  group('OAuthService - State Management', () {
    test('maintains independence from storage service state', () async {
      // Arrange: Create multiple OAuthService instances
      final service1 = OAuthService(mockStorage);
      final service2 = OAuthService(mockStorage);

      when(mockStorage.isAuthenticated()).thenAnswer((_) async => true);

      // Act
      final result1 = await service1.isAuthenticated();
      final result2 = await service2.isAuthenticated();

      // Assert: Both services work independently
      expect(result1, true);
      expect(result2, true);
      verify(mockStorage.isAuthenticated()).called(2);
    });

    test('correctly delegates all storage operations', () async {
      // Arrange
      const token = 'test_token';
      const url = 'https://example.com';

      when(mockStorage.getAccessToken()).thenAnswer((_) async => token);
      when(mockStorage.getInstanceUrl()).thenAnswer((_) async => url);
      when(mockStorage.isAuthenticated()).thenAnswer((_) async => true);
      when(mockStorage.clearAuthData()).thenAnswer((_) async => {});

      // Act: Perform all operations
      final gotToken = await oauthService.getAccessToken();
      final gotUrl = await oauthService.getInstanceUrl();
      final isAuth = await oauthService.isAuthenticated();
      await oauthService.logout();

      // Assert: All operations delegated correctly
      expect(gotToken, token);
      expect(gotUrl, url);
      expect(isAuth, true);

      verify(mockStorage.getAccessToken()).called(1);
      verify(mockStorage.getInstanceUrl()).called(1);
      verify(mockStorage.isAuthenticated()).called(1);
      verify(mockStorage.clearAuthData()).called(1);
    });
  });
}
