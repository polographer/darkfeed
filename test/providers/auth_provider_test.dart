import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:darkfeed/providers/auth_provider.dart';
import 'package:darkfeed/models/post.dart';

import '../helpers/mock_oauth_service.mocks.dart';
import '../helpers/mock_pixelfed_service.mocks.dart';

void main() {
  group('AuthProvider', () {
    late AuthProvider authProvider;
    late MockOAuthService mockOAuthService;
    late MockPixelfedService mockPixelfedService;

    setUp(() {
      mockOAuthService = MockOAuthService();
      mockPixelfedService = MockPixelfedService();

      // Setup default behavior to prevent initialization from running
      when(mockOAuthService.isAuthenticated()).thenAnswer((_) async => false);

      authProvider = AuthProvider(mockOAuthService, mockPixelfedService);
    });

    tearDown(() {
      authProvider.dispose();
    });

    group('initialization', () {
      test('constructor triggers checkAuthStatus', () async {
        // Wait a bit for async initialization
        await Future<void>.delayed(const Duration(milliseconds: 50));

        verify(
          mockOAuthService.isAuthenticated(),
        ).called(greaterThanOrEqualTo(1));
      });

      test('checkAuthStatus sets authenticated when token exists', () async {
        final testUser = UserAccount(
          id: '123',
          username: 'testuser',
          displayName: 'Test User',
          avatar: 'https://example.com/avatar.jpg',
          followersCount: 10,
          followingCount: 5,
          statusesCount: 20,
        );

        when(mockOAuthService.isAuthenticated()).thenAnswer((_) async => true);
        when(mockPixelfedService.initialize()).thenAnswer((_) async => {});
        when(
          mockPixelfedService.getCurrentUser(),
        ).thenAnswer((_) async => testUser);

        await authProvider.checkAuthStatus();

        expect(authProvider.state, AuthState.authenticated);
        expect(authProvider.currentUser, testUser);
        verify(mockPixelfedService.initialize()).called(1);
        verify(mockPixelfedService.getCurrentUser()).called(1);
      });

      test(
        'checkAuthStatus sets unauthenticated when no token exists',
        () async {
          when(
            mockOAuthService.isAuthenticated(),
          ).thenAnswer((_) async => false);

          await authProvider.checkAuthStatus();

          expect(authProvider.state, AuthState.unauthenticated);
          expect(authProvider.currentUser, isNull);
          verifyNever(mockPixelfedService.initialize());
        },
      );

      test('checkAuthStatus handles initialization errors', () async {
        when(
          mockOAuthService.isAuthenticated(),
        ).thenThrow(Exception('Storage error'));

        await authProvider.checkAuthStatus();

        expect(authProvider.state, AuthState.unauthenticated);
        expect(authProvider.error, contains('Storage error'));
      });
    });

    group('login', () {
      test('successfully logs in user', () async {
        const instanceUrl = 'https://pixelfed.social';
        const accessToken = 'test_access_token';

        final testUser = UserAccount(
          id: '123',
          username: 'testuser',
          displayName: 'Test User',
          followersCount: 10,
          followingCount: 5,
          statusesCount: 20,
        );

        when(
          mockOAuthService.authenticate(instanceUrl),
        ).thenAnswer((_) async => accessToken);
        when(mockPixelfedService.initialize()).thenAnswer((_) async => {});
        when(
          mockPixelfedService.getCurrentUser(),
        ).thenAnswer((_) async => testUser);

        final result = await authProvider.login(instanceUrl);

        expect(result, isTrue);
        expect(authProvider.state, AuthState.authenticated);
        expect(authProvider.error, isNull);
        expect(authProvider.currentUser, testUser);
        verify(mockPixelfedService.initialize()).called(1);
      });

      test('sets loading state during login', () async {
        const instanceUrl = 'https://pixelfed.social';
        const accessToken = 'test_access_token';

        when(mockOAuthService.authenticate(instanceUrl)).thenAnswer((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return accessToken;
        });
        when(mockPixelfedService.initialize()).thenAnswer((_) async => {});
        when(mockPixelfedService.getCurrentUser()).thenAnswer(
          (_) async => UserAccount(
            id: '1',
            username: 'test',
            displayName: 'Test',
            followersCount: 0,
            followingCount: 0,
            statusesCount: 0,
          ),
        );

        final loginFuture = authProvider.login(instanceUrl);
        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(authProvider.state, AuthState.loading);

        await loginFuture;
        expect(authProvider.state, AuthState.authenticated);
      });

      test('handles login failure with error state', () async {
        const instanceUrl = 'https://pixelfed.social';

        when(
          mockOAuthService.authenticate(instanceUrl),
        ).thenThrow(Exception('OAuth failed'));

        final result = await authProvider.login(instanceUrl);

        expect(result, isFalse);
        expect(authProvider.state, AuthState.error);
        expect(authProvider.error, contains('OAuth failed'));
        verifyNever(mockPixelfedService.initialize());
      });

      test('continues login even if getCurrentUser fails', () async {
        const instanceUrl = 'https://pixelfed.social';
        const accessToken = 'test_access_token';

        when(
          mockOAuthService.authenticate(instanceUrl),
        ).thenAnswer((_) async => accessToken);
        when(mockPixelfedService.initialize()).thenAnswer((_) async => {});
        when(
          mockPixelfedService.getCurrentUser(),
        ).thenThrow(Exception('User fetch failed'));

        final result = await authProvider.login(instanceUrl);

        expect(result, isTrue);
        expect(authProvider.state, AuthState.authenticated);
        expect(authProvider.currentUser, isNull);
      });
    });

    group('logout', () {
      test('successfully logs out user', () async {
        // Setup authenticated state
        when(mockOAuthService.isAuthenticated()).thenAnswer((_) async => true);
        when(mockPixelfedService.initialize()).thenAnswer((_) async => {});
        when(mockPixelfedService.getCurrentUser()).thenAnswer(
          (_) async => UserAccount(
            id: '1',
            username: 'test',
            displayName: 'Test',
            followersCount: 0,
            followingCount: 0,
            statusesCount: 0,
          ),
        );
        await authProvider.checkAuthStatus();

        when(mockOAuthService.logout()).thenAnswer((_) async => {});

        await authProvider.logout();

        expect(authProvider.state, AuthState.unauthenticated);
        expect(authProvider.error, isNull);
        expect(authProvider.currentUser, isNull);
        verify(mockOAuthService.logout()).called(1);
        verify(mockPixelfedService.dispose()).called(1);
      });

      test('handles logout failure', () async {
        // Setup authenticated state
        when(mockOAuthService.isAuthenticated()).thenAnswer((_) async => true);
        when(mockPixelfedService.initialize()).thenAnswer((_) async => {});
        when(mockPixelfedService.getCurrentUser()).thenAnswer(
          (_) async => UserAccount(
            id: '1',
            username: 'test',
            displayName: 'Test',
            followersCount: 0,
            followingCount: 0,
            statusesCount: 0,
          ),
        );
        await authProvider.checkAuthStatus();

        when(mockOAuthService.logout()).thenThrow(Exception('Logout failed'));

        await authProvider.logout();

        expect(authProvider.state, AuthState.error);
        expect(authProvider.error, contains('Logout failed'));
      });
    });

    group('notifyListeners', () {
      test('notifies listeners on state change', () async {
        var notificationCount = 0;
        authProvider.addListener(() {
          notificationCount++;
        });

        when(mockOAuthService.isAuthenticated()).thenAnswer((_) async => true);
        when(mockPixelfedService.initialize()).thenAnswer((_) async => {});
        when(mockPixelfedService.getCurrentUser()).thenAnswer(
          (_) async => UserAccount(
            id: '1',
            username: 'test',
            displayName: 'Test',
            followersCount: 0,
            followingCount: 0,
            statusesCount: 0,
          ),
        );

        await authProvider.checkAuthStatus();

        // Should notify at least once during initialization
        expect(notificationCount, greaterThan(0));
      });

      test('notifies listeners on login', () async {
        var notificationCount = 0;
        authProvider.addListener(() {
          notificationCount++;
        });

        when(
          mockOAuthService.authenticate(any),
        ).thenAnswer((_) async => 'test_token');
        when(mockPixelfedService.initialize()).thenAnswer((_) async => {});
        when(mockPixelfedService.getCurrentUser()).thenAnswer(
          (_) async => UserAccount(
            id: '1',
            username: 'test',
            displayName: 'Test',
            followersCount: 0,
            followingCount: 0,
            statusesCount: 0,
          ),
        );

        await authProvider.login('https://pixelfed.social');

        // Should notify for loading and authenticated states
        expect(notificationCount, greaterThanOrEqualTo(2));
      });
    });

    group('error handling', () {
      test('clears error message on successful operation', () async {
        // Set initial error state
        when(
          mockOAuthService.isAuthenticated(),
        ).thenThrow(Exception('Initial error'));
        await authProvider.checkAuthStatus();
        expect(authProvider.error, isNotNull);

        // Successful login should clear error
        when(
          mockOAuthService.authenticate(any),
        ).thenAnswer((_) async => 'test_token');
        when(mockPixelfedService.initialize()).thenAnswer((_) async => {});
        when(mockPixelfedService.getCurrentUser()).thenAnswer(
          (_) async => UserAccount(
            id: '1',
            username: 'test',
            displayName: 'Test',
            followersCount: 0,
            followingCount: 0,
            statusesCount: 0,
          ),
        );
        await authProvider.login('https://pixelfed.social');

        expect(authProvider.error, isNull);
      });

      test('preserves error message until next operation', () async {
        when(
          mockOAuthService.authenticate(any),
        ).thenThrow(Exception('Login failed'));

        await authProvider.login('https://pixelfed.social');

        expect(authProvider.error, contains('Login failed'));
        expect(authProvider.state, AuthState.error);

        // Error should persist
        expect(authProvider.error, contains('Login failed'));
      });

      test('clearError method clears error and notifies listeners', () {
        var notificationCount = 0;
        authProvider.addListener(() {
          notificationCount++;
        });

        // Set error manually
        when(
          mockOAuthService.authenticate(any),
        ).thenThrow(Exception('Test error'));
        authProvider.login('https://pixelfed.social');

        authProvider.clearError();

        expect(authProvider.error, isNull);
        expect(notificationCount, greaterThan(0));
      });
    });

    group('getters', () {
      test('isAuthenticated returns true when authenticated', () async {
        when(mockOAuthService.isAuthenticated()).thenAnswer((_) async => true);
        when(mockPixelfedService.initialize()).thenAnswer((_) async => {});
        when(mockPixelfedService.getCurrentUser()).thenAnswer(
          (_) async => UserAccount(
            id: '1',
            username: 'test',
            displayName: 'Test',
            followersCount: 0,
            followingCount: 0,
            statusesCount: 0,
          ),
        );

        await authProvider.checkAuthStatus();

        expect(authProvider.isAuthenticated, isTrue);
      });

      test('isAuthenticated returns false when not authenticated', () async {
        when(mockOAuthService.isAuthenticated()).thenAnswer((_) async => false);

        await authProvider.checkAuthStatus();

        expect(authProvider.isAuthenticated, isFalse);
      });

      test('isLoading returns true during operations', () async {
        when(mockOAuthService.authenticate(any)).thenAnswer((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return 'token';
        });
        when(mockPixelfedService.initialize()).thenAnswer((_) async => {});
        when(mockPixelfedService.getCurrentUser()).thenAnswer(
          (_) async => UserAccount(
            id: '1',
            username: 'test',
            displayName: 'Test',
            followersCount: 0,
            followingCount: 0,
            statusesCount: 0,
          ),
        );

        final loginFuture = authProvider.login('https://pixelfed.social');
        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(authProvider.isLoading, isTrue);

        await loginFuture;
      });
    });
  });
}
