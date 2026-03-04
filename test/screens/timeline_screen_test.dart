import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'package:darkfeed/models/post.dart';
import 'package:darkfeed/providers/auth_provider.dart';
import 'package:darkfeed/providers/timeline_provider.dart';
import 'package:darkfeed/screens/timeline_screen.dart';
import 'package:darkfeed/utils/constants.dart';

import '../helpers/mock_oauth_service.mocks.dart';
import '../helpers/mock_pixelfed_service.mocks.dart';
import '../helpers/test_fixtures.dart';

void main() {
  late MockOAuthService mockOAuthService;
  late MockPixelfedService mockPixelfedService;
  late AuthProvider authProvider;
  late TimelineProvider timelineProvider;

  setUp(() {
    mockOAuthService = MockOAuthService();
    mockPixelfedService = MockPixelfedService();

    // Prevent auto-initialization
    when(mockOAuthService.isAuthenticated()).thenAnswer((_) async => false);

    // Default stub for getHomeTimeline
    when(mockPixelfedService.getHomeTimeline()).thenAnswer((_) async => []);

    authProvider = AuthProvider(mockOAuthService, mockPixelfedService);
    timelineProvider = TimelineProvider(mockPixelfedService);
  });

  tearDown(() {
    authProvider.dispose();
    timelineProvider.dispose();
  });

  Widget createTestWidget() {
    return MaterialApp(
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<TimelineProvider>.value(
            value: timelineProvider,
          ),
        ],
        child: const TimelineScreen(),
      ),
    );
  }

  group('TimelineScreen - Widget Rendering', () {
    testWidgets('displays loading indicator when loading and posts empty', (
      tester,
    ) async {
      when(mockPixelfedService.getHomeTimeline()).thenAnswer(
        (_) async => Future.delayed(const Duration(seconds: 2), () => []),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays error state when loading fails', (tester) async {
      when(
        mockPixelfedService.getHomeTimeline(),
      ).thenThrow(Exception('Network error'));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Failed to load timeline'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.textContaining('Network error'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Retry'), findsOneWidget);
    });

    testWidgets('displays empty state when no posts', (tester) async {
      when(mockPixelfedService.getHomeTimeline()).thenAnswer((_) async => []);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('No posts to show'), findsOneWidget);
      expect(
        find.text('Follow some accounts to see their posts here'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.image_not_supported_outlined), findsOneWidget);
    });

    testWidgets('displays timeline with posts', (tester) async {
      final testPosts = [
        TestFixtures.createTestPost(id: '1'),
        TestFixtures.createTestPost(id: '2'),
      ];

      when(
        mockPixelfedService.getHomeTimeline(),
      ).thenAnswer((_) async => testPosts);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(PageView), findsOneWidget);
    });

    testWidgets('displays post content', (tester) async {
      final testPosts = [
        TestFixtures.createTestPost(id: '1', content: 'Test post content'),
      ];

      when(
        mockPixelfedService.getHomeTimeline(),
      ).thenAnswer((_) async => testPosts);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Toggle overlay to see content
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle();

      expect(find.textContaining('Test post content'), findsOneWidget);
    });
  });

  group('TimelineScreen - Error Handling', () {
    testWidgets('retry button reloads timeline', (tester) async {
      var callCount = 0;
      when(mockPixelfedService.getHomeTimeline()).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) {
          throw Exception('Network error');
        }
        return [TestFixtures.createTestPost()];
      });

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Failed to load timeline'), findsOneWidget);
      expect(callCount, 1);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Retry'));
      await tester.pumpAndSettle();

      expect(callCount, 2);
      expect(find.text('Failed to load timeline'), findsNothing);
      expect(find.byType(PageView), findsOneWidget);
    });

    testWidgets('handles empty timeline gracefully', (tester) async {
      when(mockPixelfedService.getHomeTimeline()).thenAnswer((_) async => []);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Should show empty state, not error
      expect(find.text('No posts to show'), findsOneWidget);
      expect(find.text('Failed to load timeline'), findsNothing);
    });
  });

  group('TimelineScreen - Navigation', () {
    testWidgets('navigates to next post with PageView swipe', (tester) async {
      final testPosts = [
        TestFixtures.createTestPost(id: '1', mediaCount: 1),
        TestFixtures.createTestPost(id: '2', mediaCount: 1),
        TestFixtures.createTestPost(id: '3', mediaCount: 1),
      ];

      when(
        mockPixelfedService.getHomeTimeline(),
      ).thenAnswer((_) async => testPosts);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(timelineProvider.currentIndex, 0);

      // Swipe up (to next post)
      await tester.drag(find.byType(PageView), const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(timelineProvider.currentIndex, 1);
    });

    testWidgets('navigates to previous post with PageView swipe', (
      tester,
    ) async {
      final testPosts = [
        TestFixtures.createTestPost(id: '1', mediaCount: 1),
        TestFixtures.createTestPost(id: '2', mediaCount: 1),
      ];

      when(
        mockPixelfedService.getHomeTimeline(),
      ).thenAnswer((_) async => testPosts);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Navigate to second post first
      await tester.drag(find.byType(PageView), const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(timelineProvider.currentIndex, 1);

      // Swipe down (to previous post)
      await tester.drag(find.byType(PageView), const Offset(0, 300));
      await tester.pumpAndSettle();

      expect(timelineProvider.currentIndex, 0);
    });

    testWidgets('navigates with keyboard arrow down', (tester) async {
      final testPosts = [
        TestFixtures.createTestPost(id: '1', mediaCount: 1),
        TestFixtures.createTestPost(id: '2', mediaCount: 1),
      ];

      when(
        mockPixelfedService.getHomeTimeline(),
      ).thenAnswer((_) async => testPosts);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(timelineProvider.currentIndex, 0);

      // Simulate arrow down key
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();

      expect(timelineProvider.currentIndex, 1);
    });

    testWidgets('navigates with keyboard arrow up', (tester) async {
      final testPosts = [
        TestFixtures.createTestPost(id: '1', mediaCount: 1),
        TestFixtures.createTestPost(id: '2', mediaCount: 1),
      ];

      when(
        mockPixelfedService.getHomeTimeline(),
      ).thenAnswer((_) async => testPosts);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Navigate to second post first
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();

      expect(timelineProvider.currentIndex, 1);

      // Navigate back
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();

      expect(timelineProvider.currentIndex, 0);
    });
  });

  group('TimelineScreen - Image Carousel', () {
    testWidgets('navigates to next image with arrow right', (tester) async {
      final testPosts = [TestFixtures.createTestPost(id: '1', mediaCount: 3)];

      when(
        mockPixelfedService.getHomeTimeline(),
      ).thenAnswer((_) async => testPosts);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(timelineProvider.currentImageIndex, 0);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();

      expect(timelineProvider.currentImageIndex, 1);
    });

    testWidgets('navigates to previous image with arrow left', (tester) async {
      final testPosts = [TestFixtures.createTestPost(id: '1', mediaCount: 3)];

      when(
        mockPixelfedService.getHomeTimeline(),
      ).thenAnswer((_) async => testPosts);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Move to second image first
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();

      expect(timelineProvider.currentImageIndex, 1);

      // Navigate back
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();

      expect(timelineProvider.currentImageIndex, 0);
    });

    testWidgets('displays image indicators for multi-image posts', (
      tester,
    ) async {
      final testPosts = [TestFixtures.createTestPost(id: '1', mediaCount: 3)];

      when(
        mockPixelfedService.getHomeTimeline(),
      ).thenAnswer((_) async => testPosts);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Toggle overlay to see indicators
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle();

      // Should have 3 indicators
      expect(find.text('1/3'), findsOneWidget);
    });
  });

  group('TimelineScreen - Overlay Toggle', () {
    testWidgets('toggles overlay with tap', (tester) async {
      final testPosts = [TestFixtures.createTestPost(id: '1')];

      when(
        mockPixelfedService.getHomeTimeline(),
      ).thenAnswer((_) async => testPosts);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Overlay initially hidden
      expect(find.text('@testuser'), findsNothing);

      // Tap to show overlay
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle();

      // Overlay now visible
      expect(find.text('@testuser'), findsOneWidget);

      // Tap again to hide
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle();

      // Overlay hidden again
      expect(find.text('@testuser'), findsNothing);
    });

    testWidgets('toggles overlay with spacebar', (tester) async {
      final testPosts = [TestFixtures.createTestPost(id: '1')];

      when(
        mockPixelfedService.getHomeTimeline(),
      ).thenAnswer((_) async => testPosts);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Overlay initially hidden
      expect(find.text('@testuser'), findsNothing);

      // Press space to toggle
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();

      // Overlay now visible
      expect(find.text('@testuser'), findsOneWidget);
    });
  });

  group('TimelineScreen - Interactions', () {
    testWidgets('displays like button', (tester) async {
      final testPosts = [
        TestFixtures.createTestPost(id: '1', favourited: false),
      ];

      when(
        mockPixelfedService.getHomeTimeline(),
      ).thenAnswer((_) async => testPosts);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Show overlay to see action buttons
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    });

    testWidgets('like button triggers like action', (tester) async {
      final testPost = TestFixtures.createTestPost(id: '1', favourited: false);
      final testPosts = [testPost];

      when(
        mockPixelfedService.getHomeTimeline(),
      ).thenAnswer((_) async => testPosts);
      when(mockPixelfedService.likePost(any)).thenAnswer(
        (_) async => testPost.copyWith(
          favourited: true,
          favouritesCount: testPost.favouritesCount + 1,
        ),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Show overlay
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle();

      // Tap like button
      await tester.tap(find.byIcon(Icons.favorite_border));
      await tester.pumpAndSettle();

      verify(mockPixelfedService.likePost('1')).called(1);
    });
  });

  group('TimelineScreen - Logout', () {
    testWidgets('shows logout confirmation dialog', (tester) async {
      final testPosts = [TestFixtures.createTestPost(id: '1')];

      when(
        mockPixelfedService.getHomeTimeline(),
      ).thenAnswer((_) async => testPosts);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Show overlay to see logout button
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle();

      // Tap logout button
      await tester.tap(find.byIcon(Icons.logout));
      await tester.pumpAndSettle();

      // Confirmation dialog should appear
      expect(find.text('Logout'), findsWidgets);
      expect(find.text('Are you sure you want to logout?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('cancel button dismisses logout dialog', (tester) async {
      final testPosts = [TestFixtures.createTestPost(id: '1')];

      when(
        mockPixelfedService.getHomeTimeline(),
      ).thenAnswer((_) async => testPosts);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Show overlay and open logout dialog
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.logout));
      await tester.pumpAndSettle();

      // Cancel logout
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      // Dialog should be dismissed
      expect(find.text('Are you sure you want to logout?'), findsNothing);

      // Should not call logout
      verifyNever(mockOAuthService.logout());
    });

    testWidgets('confirm logout logs out user', (tester) async {
      final testPosts = [TestFixtures.createTestPost(id: '1')];

      when(
        mockPixelfedService.getHomeTimeline(),
      ).thenAnswer((_) async => testPosts);
      when(mockOAuthService.logout()).thenAnswer((_) async {});

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Show overlay and open logout dialog
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.logout));
      await tester.pumpAndSettle();

      // Confirm logout
      await tester.tap(find.widgetWithText(TextButton, 'Logout').last);
      await tester.pumpAndSettle();

      // Should call logout
      verify(mockOAuthService.logout()).called(1);
    });
  });

  group('TimelineScreen - Edge Cases', () {
    testWidgets('handles post with single image', (tester) async {
      final testPosts = [TestFixtures.createTestPost(id: '1', mediaCount: 1)];

      when(
        mockPixelfedService.getHomeTimeline(),
      ).thenAnswer((_) async => testPosts);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(PageView), findsOneWidget);
    });

    testWidgets('handles post with no content', (tester) async {
      final testPosts = [TestFixtures.createTestPost(id: '1', content: '')];

      when(
        mockPixelfedService.getHomeTimeline(),
      ).thenAnswer((_) async => testPosts);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(PageView), findsOneWidget);
    });

    testWidgets('does not navigate past last post', (tester) async {
      final testPosts = [
        TestFixtures.createTestPost(id: '1', mediaCount: 1),
        TestFixtures.createTestPost(id: '2', mediaCount: 1),
      ];

      when(
        mockPixelfedService.getHomeTimeline(),
      ).thenAnswer((_) async => testPosts);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Navigate to last post
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();

      expect(timelineProvider.currentIndex, 1);

      // Try to navigate past last post
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();

      // Should stay at last post
      expect(timelineProvider.currentIndex, 1);
    });

    testWidgets('does not navigate before first post', (tester) async {
      final testPosts = [
        TestFixtures.createTestPost(id: '1', mediaCount: 1),
        TestFixtures.createTestPost(id: '2', mediaCount: 1),
      ];

      when(
        mockPixelfedService.getHomeTimeline(),
      ).thenAnswer((_) async => testPosts);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(timelineProvider.currentIndex, 0);

      // Try to navigate before first post
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();

      // Should stay at first post
      expect(timelineProvider.currentIndex, 0);
    });

    testWidgets('properly disposes controllers', (tester) async {
      final testPosts = [TestFixtures.createTestPost(id: '1')];

      when(
        mockPixelfedService.getHomeTimeline(),
      ).thenAnswer((_) async => testPosts);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Remove widget
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));

      // Should not throw errors
      await tester.pumpAndSettle();
    });
  });
}
