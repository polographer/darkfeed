import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'package:darkfeed/providers/auth_provider.dart';
import 'package:darkfeed/screens/login_screen.dart';

import '../helpers/mock_oauth_service.mocks.dart';
import '../helpers/mock_pixelfed_service.mocks.dart';
import '../helpers/test_fixtures.dart';

void main() {
  late MockOAuthService mockOAuthService;
  late MockPixelfedService mockPixelfedService;
  late AuthProvider authProvider;

  setUp(() {
    mockOAuthService = MockOAuthService();
    mockPixelfedService = MockPixelfedService();

    // Prevent auto-initialization
    when(mockOAuthService.isAuthenticated()).thenAnswer((_) async => false);

    // Default stub for authenticate to prevent errors in simple rendering tests
    when(
      mockOAuthService.authenticate(any),
    ).thenAnswer((_) async => 'default_token');
    when(mockPixelfedService.initialize()).thenAnswer((_) async {});
    when(
      mockPixelfedService.getCurrentUser(),
    ).thenAnswer((_) async => AuthTestFixtures.createTestUserAccount());

    authProvider = AuthProvider(mockOAuthService, mockPixelfedService);
  });

  tearDown(() {
    authProvider.dispose();
  });

  Widget createTestWidget(String instanceUrl) {
    return MaterialApp(
      home: ChangeNotifierProvider<AuthProvider>.value(
        value: authProvider,
        child: LoginScreen(instanceUrl: instanceUrl),
      ),
    );
  }

  group('LoginScreen - Widget Rendering', () {
    testWidgets('displays instance URL correctly', (tester) async {
      const testUrl = 'pixelfed.social';

      await tester.pumpWidget(createTestWidget(testUrl));
      await tester.pumpAndSettle();

      expect(find.text(testUrl), findsOneWidget);
      expect(find.text('Connecting to'), findsOneWidget);
      expect(find.byIcon(Icons.cloud), findsOneWidget);
    });

    testWidgets('displays app bar with title', (tester) async {
      await tester.pumpWidget(createTestWidget('test.instance'));
      await tester.pumpAndSettle();

      expect(find.text('Login'), findsOneWidget);
      expect(find.widgetWithText(AppBar, 'Login'), findsOneWidget);
    });

    testWidgets('displays help text at bottom', (tester) async {
      await tester.pumpWidget(createTestWidget('test.instance'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'You will be redirected to your instance to authorize DarkFeed',
        ),
        findsOneWidget,
      );
    });

    testWidgets('displays loading state initially', (tester) async {
      when(mockOAuthService.authenticate(any)).thenAnswer(
        (_) async =>
            Future.delayed(const Duration(seconds: 2), () => 'test_token'),
      );

      await tester.pumpWidget(createTestWidget('test.instance'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Authenticating...'), findsOneWidget);
    });

    testWidgets('displays platform-specific message on Linux', (tester) async {
      // Skip on non-Linux platforms
      if (!Platform.isLinux) {
        return;
      }

      when(mockOAuthService.authenticate(any)).thenAnswer(
        (_) async =>
            Future.delayed(const Duration(seconds: 2), () => 'test_token'),
      );

      await tester.pumpWidget(createTestWidget('test.instance'));
      await tester.pump();

      expect(find.textContaining('Note: On Linux'), findsOneWidget);
    });

    testWidgets('displays generic message on non-Linux', (tester) async {
      // Skip on Linux
      if (Platform.isLinux) {
        return;
      }

      when(mockOAuthService.authenticate(any)).thenAnswer(
        (_) async =>
            Future.delayed(const Duration(seconds: 2), () => 'test_token'),
      );

      await tester.pumpWidget(createTestWidget('test.instance'));
      await tester.pump();

      expect(
        find.text('Please complete the login in your browser'),
        findsOneWidget,
      );
      expect(find.textContaining('Note: On Linux'), findsNothing);
    });

    testWidgets('displays error state when login fails', (tester) async {
      when(
        mockOAuthService.authenticate(any),
      ).thenThrow(Exception('Network error'));

      await tester.pumpWidget(createTestWidget('test.instance'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Login Failed'), findsOneWidget);
      expect(
        find.textContaining('Login failed: Exception: Network error'),
        findsOneWidget,
      );
    });

    testWidgets('displays retry and cancel buttons on error', (tester) async {
      when(
        mockOAuthService.authenticate(any),
      ).thenThrow(Exception('Network error'));

      await tester.pumpWidget(createTestWidget('test.instance'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(ElevatedButton, 'Retry'), findsOneWidget);
      expect(
        find.widgetWithIcon(ElevatedButton, Icons.refresh),
        findsOneWidget,
      );
      expect(find.widgetWithText(TextButton, 'Cancel'), findsOneWidget);
    });

    testWidgets('hides back button during loading', (tester) async {
      when(mockOAuthService.authenticate(any)).thenAnswer(
        (_) async =>
            Future.delayed(const Duration(seconds: 2), () => 'test_token'),
      );

      await tester.pumpWidget(createTestWidget('test.instance'));
      await tester.pump();

      expect(find.byIcon(Icons.arrow_back), findsNothing);
    });

    testWidgets('shows back button in error state', (tester) async {
      when(
        mockOAuthService.authenticate(any),
      ).thenThrow(Exception('Network error'));

      await tester.pumpWidget(createTestWidget('test.instance'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });
  });

  group('LoginScreen - Auto-Login Behavior', () {
    testWidgets('automatically starts login on init', (tester) async {
      when(
        mockOAuthService.authenticate(any),
      ).thenAnswer((_) async => 'test_token');
      when(mockPixelfedService.initialize()).thenAnswer((_) async {});
      when(
        mockPixelfedService.getCurrentUser(),
      ).thenAnswer((_) async => AuthTestFixtures.createTestUserAccount());

      await tester.pumpWidget(createTestWidget('test.instance'));
      await tester.pump();

      verify(mockOAuthService.authenticate('test.instance')).called(1);
    });

    testWidgets('calls login with correct instance URL', (tester) async {
      const testUrl = 'my.pixelfed.instance';

      when(
        mockOAuthService.authenticate(any),
      ).thenAnswer((_) async => 'test_token');
      when(mockPixelfedService.initialize()).thenAnswer((_) async {});
      when(
        mockPixelfedService.getCurrentUser(),
      ).thenAnswer((_) async => AuthTestFixtures.createTestUserAccount());

      await tester.pumpWidget(createTestWidget(testUrl));
      await tester.pump();

      verify(mockOAuthService.authenticate(testUrl)).called(1);
    });
  });

  group('LoginScreen - Success Behavior', () {
    testWidgets('pops navigation on successful login', (tester) async {
      when(
        mockOAuthService.authenticate(any),
      ).thenAnswer((_) async => 'test_token');
      when(mockPixelfedService.initialize()).thenAnswer((_) async {});
      when(
        mockPixelfedService.getCurrentUser(),
      ).thenAnswer((_) async => AuthTestFixtures.createTestUserAccount());

      await tester.pumpWidget(createTestWidget('test.instance'));

      // Wait for post-frame callback
      await tester.pump();

      // Wait for login to complete
      await tester.pumpAndSettle();

      // Screen should be popped (not found)
      expect(find.byType(LoginScreen), findsNothing);
    });

    testWidgets('waits 500ms before popping after success', (tester) async {
      when(
        mockOAuthService.authenticate(any),
      ).thenAnswer((_) async => 'test_token');
      when(mockPixelfedService.initialize()).thenAnswer((_) async {});
      when(
        mockPixelfedService.getCurrentUser(),
      ).thenAnswer((_) async => AuthTestFixtures.createTestUserAccount());

      await tester.pumpWidget(createTestWidget('test.instance'));
      await tester.pump();

      // Login completes but 500ms delay not elapsed
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(LoginScreen), findsOneWidget);

      // After full delay
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();
      expect(find.byType(LoginScreen), findsNothing);
    });
  });

  group('LoginScreen - Error Handling', () {
    testWidgets('handles OAuth service errors', (tester) async {
      when(
        mockOAuthService.authenticate(any),
      ).thenThrow(Exception('OAuth error'));

      await tester.pumpWidget(createTestWidget('test.instance'));
      await tester.pumpAndSettle();

      expect(find.text('Login Failed'), findsOneWidget);
      expect(find.textContaining('OAuth error'), findsOneWidget);
    });

    testWidgets('handles Pixelfed service initialization errors', (
      tester,
    ) async {
      when(
        mockOAuthService.authenticate(any),
      ).thenAnswer((_) async => 'test_token');
      when(
        mockPixelfedService.initialize(),
      ).thenThrow(Exception('Service init error'));

      await tester.pumpWidget(createTestWidget('test.instance'));
      await tester.pumpAndSettle();

      expect(find.text('Login Failed'), findsOneWidget);
      expect(find.textContaining('Service init error'), findsOneWidget);
    });

    testWidgets('handles user fetch errors', (tester) async {
      when(
        mockOAuthService.authenticate(any),
      ).thenAnswer((_) async => 'test_token');
      when(mockPixelfedService.initialize()).thenAnswer((_) async {});
      when(
        mockPixelfedService.getCurrentUser(),
      ).thenThrow(Exception('User fetch error'));

      await tester.pumpWidget(createTestWidget('test.instance'));
      await tester.pumpAndSettle();

      // Login should still succeed even if user fetch fails
      expect(find.byType(LoginScreen), findsNothing);
    });
  });

  group('LoginScreen - User Interactions', () {
    testWidgets('retry button triggers new login attempt', (tester) async {
      var callCount = 0;
      when(mockOAuthService.authenticate(any)).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) {
          throw Exception('First attempt failed');
        }
        return 'test_token';
      });
      when(mockPixelfedService.initialize()).thenAnswer((_) async {});
      when(
        mockPixelfedService.getCurrentUser(),
      ).thenAnswer((_) async => AuthTestFixtures.createTestUserAccount());

      await tester.pumpWidget(createTestWidget('test.instance'));
      await tester.pumpAndSettle();

      expect(find.text('Login Failed'), findsOneWidget);
      expect(callCount, 1);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Retry'));
      await tester.pump();

      expect(callCount, 2);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('cancel button pops navigation', (tester) async {
      when(
        mockOAuthService.authenticate(any),
      ).thenThrow(Exception('Login error'));

      await tester.pumpWidget(createTestWidget('test.instance'));
      await tester.pumpAndSettle();

      expect(find.text('Login Failed'), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsNothing);
    });

    testWidgets('back button pops navigation', (tester) async {
      when(
        mockOAuthService.authenticate(any),
      ).thenThrow(Exception('Login error'));

      await tester.pumpWidget(createTestWidget('test.instance'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsNothing);
    });

    testWidgets('clears error message on retry', (tester) async {
      var callCount = 0;
      when(mockOAuthService.authenticate(any)).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) {
          throw Exception('First attempt failed');
        }
        // Second attempt succeeds by taking a long time
        await Future.delayed(const Duration(seconds: 2));
        return 'test_token';
      });

      await tester.pumpWidget(createTestWidget('test.instance'));
      await tester.pumpAndSettle();

      expect(find.text('Login Failed'), findsOneWidget);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Retry'));
      await tester.pump();

      // Error message should be cleared, loading should show
      expect(find.text('Login Failed'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('LoginScreen - Edge Cases', () {
    testWidgets('handles empty instance URL', (tester) async {
      when(
        mockOAuthService.authenticate(any),
      ).thenAnswer((_) async => 'test_token');

      await tester.pumpWidget(createTestWidget(''));
      await tester.pump();

      expect(find.text(''), findsWidgets);
      verify(mockOAuthService.authenticate('')).called(1);
    });

    testWidgets('handles very long instance URL', (tester) async {
      final longUrl = 'a' * 200;

      when(
        mockOAuthService.authenticate(any),
      ).thenAnswer((_) async => 'test_token');

      await tester.pumpWidget(createTestWidget(longUrl));
      await tester.pump();

      expect(find.textContaining('a'), findsWidgets);
    });

    testWidgets('handles widget disposal during login', (tester) async {
      when(mockOAuthService.authenticate(any)).thenAnswer(
        (_) async =>
            Future.delayed(const Duration(seconds: 2), () => 'test_token'),
      );

      await tester.pumpWidget(createTestWidget('test.instance'));
      await tester.pump();

      // Remove widget while login is in progress
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));

      // Should not throw errors
      await tester.pumpAndSettle();
    });

    testWidgets('maintains state during rebuild', (tester) async {
      when(
        mockOAuthService.authenticate(any),
      ).thenThrow(Exception('Test error'));

      await tester.pumpWidget(createTestWidget('test.instance'));
      await tester.pumpAndSettle();

      expect(find.text('Login Failed'), findsOneWidget);

      // Trigger rebuild
      await tester.pumpWidget(createTestWidget('test.instance'));
      await tester.pump();

      // Error state should persist
      expect(find.text('Login Failed'), findsOneWidget);
    });
  });
}
