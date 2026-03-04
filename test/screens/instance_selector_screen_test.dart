import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'package:darkfeed/models/post.dart';
import 'package:darkfeed/providers/auth_provider.dart';
import 'package:darkfeed/providers/instance_provider.dart';
import 'package:darkfeed/screens/instance_selector_screen.dart';
import 'package:darkfeed/screens/login_screen.dart';
import 'package:darkfeed/utils/constants.dart';
import 'package:darkfeed/utils/known_instances.dart';

import '../helpers/mock_oauth_service.mocks.dart';
import '../helpers/mock_pixelfed_service.mocks.dart';
import '../helpers/mock_storage_service.mocks.dart';
import '../helpers/test_fixtures.dart';

void main() {
  late MockOAuthService mockOAuthService;
  late MockPixelfedService mockPixelfedService;
  late MockStorageService mockStorageService;
  late AuthProvider authProvider;
  late InstanceProvider instanceProvider;

  setUp(() {
    mockOAuthService = MockOAuthService();
    mockPixelfedService = MockPixelfedService();
    mockStorageService = MockStorageService();

    // Prevent auto-initialization
    when(mockOAuthService.isAuthenticated()).thenAnswer((_) async => false);
    when(mockStorageService.getInstanceUrl()).thenAnswer((_) async => null);

    // Default stubs for common operations
    when(
      mockOAuthService.authenticate(any),
    ).thenAnswer((_) async => 'default_token');
    when(mockStorageService.saveInstanceUrl(any)).thenAnswer((_) async {});

    authProvider = AuthProvider(mockOAuthService, mockPixelfedService);
    instanceProvider = InstanceProvider(mockStorageService);
  });

  tearDown(() {
    authProvider.dispose();
    instanceProvider.dispose();
  });

  Widget createTestWidget() {
    return MaterialApp(
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<InstanceProvider>.value(
            value: instanceProvider,
          ),
        ],
        child: const InstanceSelectorScreen(),
      ),
    );
  }

  group('InstanceSelectorScreen - Widget Rendering', () {
    testWidgets('displays app title and subtitle', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text(appName), findsOneWidget);
      expect(find.text('A Pixelfed client'), findsOneWidget);
    });

    testWidgets('displays instance URL input field', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Instance URL'), findsOneWidget);
      expect(find.text('pixelfed.social'), findsOneWidget); // Hint text
      expect(find.byIcon(Icons.language), findsOneWidget);
    });

    testWidgets('displays connect button', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.widgetWithText(ElevatedButton, 'Connect'), findsOneWidget);
    });

    testWidgets('displays popular instances section', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Popular Instances'), findsOneWidget);
      expect(find.byType(Divider), findsOneWidget);
    });

    testWidgets('displays list of known instances', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byType(ListTile), findsNWidgets(knownInstances.length));

      // Check first few instances
      for (int i = 0; i < 3 && i < knownInstances.length; i++) {
        expect(find.text(knownInstances[i].name), findsOneWidget);
        expect(find.text(knownInstances[i].url), findsOneWidget);
      }
    });

    testWidgets('displays instance avatars with first letter', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Check that first instance has correct avatar letter
      if (knownInstances.isNotEmpty) {
        final firstLetter = knownInstances[0].name[0].toUpperCase();
        expect(find.text(firstLetter), findsWidgets);
      }
    });

    testWidgets('displays arrow icons on instance list items', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(
        find.byIcon(Icons.arrow_forward_ios),
        findsNWidgets(knownInstances.length),
      );
    });
  });

  group('InstanceSelectorScreen - Input Validation', () {
    testWidgets('displays error for empty input', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Try to connect with empty input
      await tester.tap(find.widgetWithText(ElevatedButton, 'Connect'));
      await tester.pumpAndSettle();

      // Button should not trigger anything with empty input
      verifyNever(mockStorageService.saveInstanceUrl(any));
    });

    testWidgets('displays error for invalid URL (no dot)', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Enter invalid URL
      await tester.enterText(find.byType(TextField), 'invalidurl');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Connect'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid instance URL'), findsOneWidget);
    });

    testWidgets('accepts valid URL with dot', (tester) async {
      when(mockStorageService.saveInstanceUrl(any)).thenAnswer((_) async => {});
      when(
        mockOAuthService.authenticate(any),
      ).thenAnswer((_) async => 'test_token');

      await tester.pumpWidget(createTestWidget());

      // Enter valid URL
      await tester.enterText(find.byType(TextField), 'test.instance');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Connect'));
      await tester.pump();

      // Should navigate to LoginScreen
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('trims whitespace from input', (tester) async {
      when(mockStorageService.saveInstanceUrl(any)).thenAnswer((_) async => {});
      when(
        mockOAuthService.authenticate(any),
      ).thenAnswer((_) async => 'test_token');

      await tester.pumpWidget(createTestWidget());

      // Enter URL with whitespace
      await tester.enterText(find.byType(TextField), '  test.instance  ');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Connect'));
      await tester.pump();

      // Should save trimmed version
      verify(mockStorageService.saveInstanceUrl('test.instance')).called(1);
    });

    testWidgets('trims whitespace from input', (tester) async {
      when(
        mockStorageService.saveInstanceUrl(any),
      ).thenAnswer((_) async => true);
      when(
        mockOAuthService.authenticate(any),
      ).thenAnswer((_) async => 'test_token');

      await tester.pumpWidget(createTestWidget());

      // Enter URL with whitespace
      await tester.enterText(find.byType(TextField), '  test.instance  ');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Connect'));
      await tester.pump();

      // Should save trimmed version
      verify(mockStorageService.saveInstanceUrl('test.instance')).called(1);
    });

    testWidgets('clears error message on new input', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Trigger error
      await tester.enterText(find.byType(TextField), 'invalid');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Connect'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid instance URL'), findsOneWidget);

      // Enter valid URL
      await tester.enterText(find.byType(TextField), 'valid.url');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Connect'));
      await tester.pump();

      // Error should be cleared
      expect(find.text('Please enter a valid instance URL'), findsNothing);
    });
  });

  group('InstanceSelectorScreen - Instance Selection', () {
    testWidgets('navigates to login screen on connect button tap', (
      tester,
    ) async {
      when(
        mockStorageService.saveInstanceUrl(any),
      ).thenAnswer((_) async => true);
      when(
        mockOAuthService.authenticate(any),
      ).thenAnswer((_) async => 'test_token');

      await tester.pumpWidget(createTestWidget());

      await tester.enterText(find.byType(TextField), 'pixelfed.social');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Connect'));
      await tester.pump();

      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('navigates to login screen on text field submit', (
      tester,
    ) async {
      when(
        mockStorageService.saveInstanceUrl(any),
      ).thenAnswer((_) async => true);
      when(
        mockOAuthService.authenticate(any),
      ).thenAnswer((_) async => 'test_token');

      await tester.pumpWidget(createTestWidget());

      await tester.enterText(find.byType(TextField), 'pixelfed.social');
      await tester.testTextInput.receiveAction(TextInputAction.go);
      await tester.pump();

      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('navigates to login screen when tapping instance list item', (
      tester,
    ) async {
      when(
        mockStorageService.saveInstanceUrl(any),
      ).thenAnswer((_) async => true);
      when(
        mockOAuthService.authenticate(any),
      ).thenAnswer((_) async => 'test_token');

      await tester.pumpWidget(createTestWidget());

      // Tap first instance
      if (knownInstances.isNotEmpty) {
        await tester.tap(find.text(knownInstances[0].name));
        await tester.pump();

        expect(find.byType(LoginScreen), findsOneWidget);
      }
    });

    testWidgets('passes correct instance URL to login screen', (tester) async {
      const testUrl = 'test.pixelfed.instance';
      when(
        mockStorageService.saveInstanceUrl(any),
      ).thenAnswer((_) async => true);
      when(
        mockOAuthService.authenticate(any),
      ).thenAnswer((_) async => 'test_token');

      await tester.pumpWidget(createTestWidget());

      await tester.enterText(find.byType(TextField), testUrl);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Connect'));
      await tester.pump();

      // Verify LoginScreen received correct URL
      final loginScreen = tester.widget<LoginScreen>(find.byType(LoginScreen));
      expect(loginScreen.instanceUrl, testUrl);
    });

    testWidgets('saves selected instance to storage', (tester) async {
      const testUrl = 'test.instance';
      when(
        mockStorageService.saveInstanceUrl(any),
      ).thenAnswer((_) async => true);
      when(
        mockOAuthService.authenticate(any),
      ).thenAnswer((_) async => 'test_token');

      await tester.pumpWidget(createTestWidget());

      await tester.enterText(find.byType(TextField), testUrl);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Connect'));
      await tester.pump();

      verify(mockStorageService.saveInstanceUrl(testUrl)).called(1);
    });
  });

  group('InstanceSelectorScreen - Authentication Flow', () {
    testWidgets('pops screen after successful login', (tester) async {
      when(
        mockStorageService.saveInstanceUrl(any),
      ).thenAnswer((_) async => true);
      when(
        mockOAuthService.authenticate(any),
      ).thenAnswer((_) async => 'test_token');
      when(mockPixelfedService.initialize()).thenAnswer((_) async {});
      when(
        mockPixelfedService.getCurrentUser(),
      ).thenAnswer((_) async => AuthTestFixtures.createTestUserAccount());

      await tester.pumpWidget(createTestWidget());

      await tester.enterText(find.byType(TextField), 'pixelfed.social');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Connect'));
      await tester.pump();

      // LoginScreen appears
      expect(find.byType(LoginScreen), findsOneWidget);

      // Wait for login to complete
      await tester.pumpAndSettle();

      // Both screens should be popped
      expect(find.byType(InstanceSelectorScreen), findsNothing);
      expect(find.byType(LoginScreen), findsNothing);
    });

    testWidgets('stays on screen if login fails', (tester) async {
      when(
        mockStorageService.saveInstanceUrl(any),
      ).thenAnswer((_) async => true);
      when(
        mockOAuthService.authenticate(any),
      ).thenThrow(Exception('Login failed'));

      await tester.pumpWidget(createTestWidget());

      await tester.enterText(find.byType(TextField), 'pixelfed.social');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Connect'));
      await tester.pump();

      // LoginScreen appears
      expect(find.byType(LoginScreen), findsOneWidget);

      // Cancel login
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      // Should return to instance selector
      expect(find.byType(InstanceSelectorScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
    });

    testWidgets('stays on screen if login is canceled', (tester) async {
      when(
        mockStorageService.saveInstanceUrl(any),
      ).thenAnswer((_) async => true);
      when(
        mockOAuthService.authenticate(any),
      ).thenThrow(Exception('User canceled'));

      await tester.pumpWidget(createTestWidget());

      await tester.enterText(find.byType(TextField), 'pixelfed.social');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Connect'));
      await tester.pump();

      await tester.pumpAndSettle();

      // Cancel the login
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Should be back on instance selector
      expect(find.byType(InstanceSelectorScreen), findsOneWidget);
    });
  });

  group('InstanceSelectorScreen - Edge Cases', () {
    testWidgets('handles multiple rapid instance selections', (tester) async {
      when(
        mockStorageService.saveInstanceUrl(any),
      ).thenAnswer((_) async => true);
      when(mockOAuthService.authenticate(any)).thenAnswer(
        (_) async => Future.delayed(
          const Duration(milliseconds: 100),
          () => 'test_token',
        ),
      );

      await tester.pumpWidget(createTestWidget());

      // Rapidly tap connect multiple times
      await tester.enterText(find.byType(TextField), 'test.instance');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Connect'));
      await tester.tap(find.widgetWithText(ElevatedButton, 'Connect'));
      await tester.pump();

      // Should only navigate once
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('handles special characters in URL', (tester) async {
      when(
        mockStorageService.saveInstanceUrl(any),
      ).thenAnswer((_) async => true);
      when(
        mockOAuthService.authenticate(any),
      ).thenAnswer((_) async => 'test_token');

      await tester.pumpWidget(createTestWidget());

      // Enter URL with special characters
      await tester.enterText(
        find.byType(TextField),
        'test-instance_123.example.com',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Connect'));
      await tester.pump();

      // Should accept it (has a dot)
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('handles very long instance URL', (tester) async {
      final longUrl = '${'a' * 100}.com';
      when(
        mockStorageService.saveInstanceUrl(any),
      ).thenAnswer((_) async => true);
      when(
        mockOAuthService.authenticate(any),
      ).thenAnswer((_) async => 'test_token');

      await tester.pumpWidget(createTestWidget());

      await tester.enterText(find.byType(TextField), longUrl);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Connect'));
      await tester.pump();

      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('properly disposes text controller', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Remove widget
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));

      // Should not throw any errors
      await tester.pumpAndSettle();
    });

    testWidgets('handles keyboard input correctly', (tester) async {
      await tester.pumpWidget(createTestWidget());

      final textField = find.byType(TextField);
      await tester.tap(textField);
      await tester.enterText(textField, 'pixelfed.social');

      expect(find.text('pixelfed.social'), findsOneWidget);
    });

    testWidgets('displays scroll behavior for long instance list', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      // ListView should be present
      expect(find.byType(ListView), findsOneWidget);

      // Scroll should work
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();
    });
  });

  group('InstanceSelectorScreen - UI State', () {
    testWidgets('maintains input after validation error', (tester) async {
      await tester.pumpWidget(createTestWidget());

      const invalidInput = 'noDotHere';
      await tester.enterText(find.byType(TextField), invalidInput);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Connect'));
      await tester.pumpAndSettle();

      // Input should still be present
      expect(find.text(invalidInput), findsOneWidget);
    });

    testWidgets('shows error text in text field decoration', (tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.enterText(find.byType(TextField), 'invalid');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Connect'));
      await tester.pumpAndSettle();

      // Check that TextField has error
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(
        textField.decoration!.errorText,
        'Please enter a valid instance URL',
      );
    });

    testWidgets('does not navigate when submit with empty field', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      // Submit empty field
      await tester.tap(find.byType(TextField));
      await tester.testTextInput.receiveAction(TextInputAction.go);
      await tester.pumpAndSettle();

      // Should not navigate
      expect(find.byType(LoginScreen), findsNothing);
      expect(find.byType(InstanceSelectorScreen), findsOneWidget);
    });
  });
}
