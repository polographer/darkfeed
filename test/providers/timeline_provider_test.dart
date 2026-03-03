import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:darkfeed/providers/timeline_provider.dart';

import '../helpers/mock_pixelfed_service.mocks.dart';
import '../helpers/test_fixtures.dart';

void main() {
  group('TimelineProvider', () {
    late TimelineProvider timelineProvider;
    late MockPixelfedService mockPixelfedService;

    setUp(() {
      mockPixelfedService = MockPixelfedService();
      timelineProvider = TimelineProvider(mockPixelfedService);
    });

    tearDown(() {
      timelineProvider.dispose();
    });

    group('initialization', () {
      test('starts with empty posts', () {
        expect(timelineProvider.posts, isEmpty);
        expect(timelineProvider.currentIndex, 0);
        expect(timelineProvider.currentPost, isNull);
      });

      test('starts with no loading state', () {
        expect(timelineProvider.isLoading, isFalse);
        expect(timelineProvider.isLoadingMore, isFalse);
      });

      test('starts with no error', () {
        expect(timelineProvider.error, isNull);
      });
    });

    group('loadTimeline', () {
      test('loads timeline posts successfully', () async {
        final testPosts = [
          TestFixtures.createTestPost(id: '1'),
          TestFixtures.createTestPost(id: '2'),
          TestFixtures.createTestPost(id: '3'),
        ];

        when(
          mockPixelfedService.getHomeTimeline(maxId: anyNamed('maxId')),
        ).thenAnswer((_) async => testPosts);

        await timelineProvider.loadTimeline();

        expect(timelineProvider.posts, testPosts);
        expect(timelineProvider.posts.length, 3);
        expect(timelineProvider.currentIndex, 0);
        expect(timelineProvider.error, isNull);
        expect(timelineProvider.isLoading, isFalse);
      });

      test('sets loading state during load', () async {
        when(
          mockPixelfedService.getHomeTimeline(maxId: anyNamed('maxId')),
        ).thenAnswer((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return [TestFixtures.createTestPost()];
        });

        final loadFuture = timelineProvider.loadTimeline();
        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(timelineProvider.isLoading, isTrue);

        await loadFuture;
        expect(timelineProvider.isLoading, isFalse);
      });

      test('handles empty timeline', () async {
        when(
          mockPixelfedService.getHomeTimeline(maxId: anyNamed('maxId')),
        ).thenAnswer((_) async => []);

        await timelineProvider.loadTimeline();

        expect(timelineProvider.posts, isEmpty);
        expect(timelineProvider.currentPost, isNull);
      });

      test('handles load error', () async {
        when(
          mockPixelfedService.getHomeTimeline(maxId: anyNamed('maxId')),
        ).thenThrow(Exception('Network error'));

        await timelineProvider.loadTimeline();

        expect(timelineProvider.posts, isEmpty);
        expect(timelineProvider.error, contains('Network error'));
        expect(timelineProvider.isLoading, isFalse);
      });

      test('resets currentIndex on load', () async {
        final testPosts = [
          TestFixtures.createTestPost(id: '1'),
          TestFixtures.createTestPost(id: '2'),
        ];

        when(
          mockPixelfedService.getHomeTimeline(maxId: anyNamed('maxId')),
        ).thenAnswer((_) async => testPosts);

        await timelineProvider.loadTimeline();
        timelineProvider.nextPost();
        expect(timelineProvider.currentIndex, 1);

        await timelineProvider.loadTimeline();
        expect(timelineProvider.currentIndex, 0);
      });
    });

    group('navigation', () {
      setUp(() async {
        final testPosts = [
          TestFixtures.createTestPost(id: '1'),
          TestFixtures.createTestPost(id: '2'),
          TestFixtures.createTestPost(id: '3'),
        ];

        when(
          mockPixelfedService.getHomeTimeline(maxId: anyNamed('maxId')),
        ).thenAnswer((_) async => testPosts);

        await timelineProvider.loadTimeline();
      });

      test('nextPost increments index', () {
        expect(timelineProvider.currentIndex, 0);

        timelineProvider.nextPost();

        expect(timelineProvider.currentIndex, 1);
        expect(timelineProvider.currentPost?.id, '2');
      });

      test('previousPost decrements index', () {
        timelineProvider.nextPost();
        expect(timelineProvider.currentIndex, 1);

        timelineProvider.previousPost();

        expect(timelineProvider.currentIndex, 0);
        expect(timelineProvider.currentPost?.id, '1');
      });

      test('nextPost does not exceed bounds', () {
        timelineProvider.setCurrentIndex(2); // Last post
        expect(timelineProvider.currentIndex, 2);

        timelineProvider.nextPost();

        expect(timelineProvider.currentIndex, 2); // Should not change
      });

      test('previousPost does not go below zero', () {
        expect(timelineProvider.currentIndex, 0);

        timelineProvider.previousPost();

        expect(timelineProvider.currentIndex, 0); // Should not change
      });

      test('setCurrentIndex sets index correctly', () {
        timelineProvider.setCurrentIndex(2);

        expect(timelineProvider.currentIndex, 2);
        expect(timelineProvider.currentPost?.id, '3');
      });

      test('setCurrentIndex validates bounds', () {
        timelineProvider.setCurrentIndex(10); // Out of bounds

        expect(timelineProvider.currentIndex, 0); // Should not change
      });

      test('setCurrentIndex validates negative index', () {
        timelineProvider.setCurrentIndex(-1);

        expect(timelineProvider.currentIndex, 0); // Should not change
      });

      test('navigation resets image index', () {
        timelineProvider.nextImage();
        expect(timelineProvider.currentImageIndex, 1);

        timelineProvider.nextPost();

        expect(timelineProvider.currentImageIndex, 0);
      });
    });

    group('image navigation', () {
      setUp(() async {
        final testPost = TestFixtures.createTestPost(id: '1', mediaCount: 3);

        when(
          mockPixelfedService.getHomeTimeline(maxId: anyNamed('maxId')),
        ).thenAnswer((_) async => [testPost]);

        await timelineProvider.loadTimeline();
      });

      test('nextImage increments image index', () {
        expect(timelineProvider.currentImageIndex, 0);

        timelineProvider.nextImage();

        expect(timelineProvider.currentImageIndex, 1);
      });

      test('previousImage decrements image index', () {
        timelineProvider.nextImage();
        expect(timelineProvider.currentImageIndex, 1);

        timelineProvider.previousImage();

        expect(timelineProvider.currentImageIndex, 0);
      });

      test('nextImage does not exceed image count', () {
        timelineProvider.nextImage(); // Index 1
        timelineProvider.nextImage(); // Index 2
        timelineProvider.nextImage(); // Should stay at 2

        expect(timelineProvider.currentImageIndex, 2);
      });

      test('previousImage does not go below zero', () {
        expect(timelineProvider.currentImageIndex, 0);

        timelineProvider.previousImage();

        expect(timelineProvider.currentImageIndex, 0);
      });
    });

    group('pagination', () {
      test('loads more posts when approaching end', () async {
        final initialPosts = List.generate(
          10,
          (i) => TestFixtures.createTestPost(id: '$i'),
        );

        final morePosts = List.generate(
          5,
          (i) => TestFixtures.createTestPost(id: '${i + 10}'),
        );

        when(
          mockPixelfedService.getHomeTimeline(maxId: anyNamed('maxId')),
        ).thenAnswer((_) async => initialPosts);

        await timelineProvider.loadTimeline();

        when(
          mockPixelfedService.getHomeTimeline(maxId: anyNamed('maxId')),
        ).thenAnswer((_) async => morePosts);

        // Navigate to index 7 (within 3 of end)
        timelineProvider.setCurrentIndex(7);

        // Wait for pagination to trigger
        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(timelineProvider.posts.length, greaterThan(10));
      });

      test('does not load more if already loading', () async {
        final testPosts = List.generate(
          10,
          (i) => TestFixtures.createTestPost(id: '$i'),
        );

        when(
          mockPixelfedService.getHomeTimeline(maxId: anyNamed('maxId')),
        ).thenAnswer((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 100));
          return testPosts;
        });

        await timelineProvider.loadTimeline();

        // Trigger pagination twice quickly
        timelineProvider.setCurrentIndex(7);
        timelineProvider.setCurrentIndex(8);

        await Future<void>.delayed(const Duration(milliseconds: 150));

        // Should only call once for pagination
        verify(
          mockPixelfedService.getHomeTimeline(maxId: anyNamed('maxId')),
        ).called(lessThanOrEqualTo(2)); // Initial + 1 pagination
      });
    });

    group('like/unlike', () {
      setUp(() async {
        final testPosts = [
          TestFixtures.createTestPost(id: '1', favourited: false),
          TestFixtures.createTestPost(id: '2', favourited: true),
        ];

        when(
          mockPixelfedService.getHomeTimeline(maxId: anyNamed('maxId')),
        ).thenAnswer((_) async => testPosts);

        await timelineProvider.loadTimeline();
      });

      test('likePost updates local state', () async {
        final likedPost = TestFixtures.createTestPost(
          id: '1',
          favourited: true,
        );
        when(
          mockPixelfedService.likePost('1'),
        ).thenAnswer((_) async => likedPost);

        await timelineProvider.likePost('1');

        expect(timelineProvider.posts[0].favourited, isTrue);
        expect(timelineProvider.posts[0].favouritesCount, 1);
        verify(mockPixelfedService.likePost('1')).called(1);
      });

      test('unlikePost updates local state', () async {
        final unlikedPost = TestFixtures.createTestPost(
          id: '2',
          favourited: false,
        );
        when(
          mockPixelfedService.unlikePost('2'),
        ).thenAnswer((_) async => unlikedPost);

        await timelineProvider.unlikePost('2');

        expect(timelineProvider.posts[1].favourited, isFalse);
        expect(timelineProvider.posts[1].favouritesCount, lessThanOrEqualTo(0));
        verify(mockPixelfedService.unlikePost('2')).called(1);
      });

      test('toggleLike likes unfavourited post', () async {
        final likedPost = TestFixtures.createTestPost(
          id: '1',
          favourited: true,
        );
        when(
          mockPixelfedService.likePost('1'),
        ).thenAnswer((_) async => likedPost);

        await timelineProvider.toggleLike();

        expect(timelineProvider.currentPost?.favourited, isTrue);
      });

      test('toggleLike unlikes favourited post', () async {
        timelineProvider.nextPost(); // Move to post 2 (favourited)
        final unlikedPost = TestFixtures.createTestPost(
          id: '2',
          favourited: false,
        );
        when(
          mockPixelfedService.unlikePost('2'),
        ).thenAnswer((_) async => unlikedPost);

        await timelineProvider.toggleLike();

        expect(timelineProvider.currentPost?.favourited, isFalse);
      });

      test('like handles errors gracefully', () async {
        when(
          mockPixelfedService.likePost('1'),
        ).thenThrow(Exception('Like failed'));

        await timelineProvider.likePost('1');

        expect(timelineProvider.error, contains('Like failed'));
        expect(timelineProvider.posts[0].favourited, isFalse); // No change
      });
    });

    group('repost/unrepost', () {
      setUp(() async {
        final testPosts = [
          TestFixtures.createTestPost(id: '1', reblogged: false),
          TestFixtures.createTestPost(id: '2', reblogged: true),
        ];

        when(
          mockPixelfedService.getHomeTimeline(maxId: anyNamed('maxId')),
        ).thenAnswer((_) async => testPosts);

        await timelineProvider.loadTimeline();
      });

      test('repostPost updates local state', () async {
        final repostedPost = TestFixtures.createTestPost(
          id: '1',
          reblogged: true,
        );
        when(
          mockPixelfedService.repostPost('1'),
        ).thenAnswer((_) async => repostedPost);

        await timelineProvider.repostPost('1');

        expect(timelineProvider.posts[0].reblogged, isTrue);
        expect(timelineProvider.posts[0].reblogsCount, 1);
        verify(mockPixelfedService.repostPost('1')).called(1);
      });

      test('unrepostPost updates local state', () async {
        final unrepostedPost = TestFixtures.createTestPost(
          id: '2',
          reblogged: false,
        );
        when(
          mockPixelfedService.unrepostPost('2'),
        ).thenAnswer((_) async => unrepostedPost);

        await timelineProvider.unrepostPost('2');

        expect(timelineProvider.posts[1].reblogged, isFalse);
        verify(mockPixelfedService.unrepostPost('2')).called(1);
      });

      test('toggleRepost reposts non-reblogged post', () async {
        final repostedPost = TestFixtures.createTestPost(
          id: '1',
          reblogged: true,
        );
        when(
          mockPixelfedService.repostPost('1'),
        ).thenAnswer((_) async => repostedPost);

        await timelineProvider.toggleRepost();

        expect(timelineProvider.currentPost?.reblogged, isTrue);
      });

      test('toggleRepost unreposts reblogged post', () async {
        timelineProvider.nextPost(); // Move to post 2 (reblogged)
        final unrepostedPost = TestFixtures.createTestPost(
          id: '2',
          reblogged: false,
        );
        when(
          mockPixelfedService.unrepostPost('2'),
        ).thenAnswer((_) async => unrepostedPost);

        await timelineProvider.toggleRepost();

        expect(timelineProvider.currentPost?.reblogged, isFalse);
      });

      test('repost handles errors gracefully', () async {
        when(
          mockPixelfedService.repostPost('1'),
        ).thenThrow(Exception('Repost failed'));

        await timelineProvider.repostPost('1');

        expect(timelineProvider.error, contains('Repost failed'));
        expect(timelineProvider.posts[0].reblogged, isFalse); // No change
      });
    });

    group('refresh', () {
      test('refresh reloads timeline', () async {
        final testPosts = [TestFixtures.createTestPost()];

        when(
          mockPixelfedService.getHomeTimeline(maxId: anyNamed('maxId')),
        ).thenAnswer((_) async => testPosts);

        await timelineProvider.refresh();

        expect(timelineProvider.posts, testPosts);
        verify(
          mockPixelfedService.getHomeTimeline(maxId: anyNamed('maxId')),
        ).called(1);
      });
    });

    group('clear', () {
      test('clear resets all state', () async {
        final testPosts = [TestFixtures.createTestPost()];

        when(
          mockPixelfedService.getHomeTimeline(maxId: anyNamed('maxId')),
        ).thenAnswer((_) async => testPosts);

        await timelineProvider.loadTimeline();
        expect(timelineProvider.posts.isNotEmpty, isTrue);

        timelineProvider.clear();

        expect(timelineProvider.posts, isEmpty);
        expect(timelineProvider.currentIndex, 0);
        expect(timelineProvider.error, isNull);
        expect(timelineProvider.isLoading, isFalse);
      });
    });

    group('notifyListeners', () {
      test('notifies on loadTimeline', () async {
        var notificationCount = 0;
        timelineProvider.addListener(() {
          notificationCount++;
        });

        when(
          mockPixelfedService.getHomeTimeline(maxId: anyNamed('maxId')),
        ).thenAnswer((_) async => [TestFixtures.createTestPost()]);

        await timelineProvider.loadTimeline();

        expect(notificationCount, greaterThanOrEqualTo(2)); // Start and end
      });

      test('notifies on navigation', () async {
        final testPosts = List.generate(
          10,
          (i) => TestFixtures.createTestPost(id: '$i'),
        );

        when(
          mockPixelfedService.getHomeTimeline(maxId: anyNamed('maxId')),
        ).thenAnswer((_) async => testPosts);

        await timelineProvider.loadTimeline();

        var notificationCount = 0;
        timelineProvider.addListener(() {
          notificationCount++;
        });

        timelineProvider.nextPost();

        expect(notificationCount, greaterThanOrEqualTo(1));
      });

      test('notifies on clear', () {
        var notificationCount = 0;
        timelineProvider.addListener(() {
          notificationCount++;
        });

        timelineProvider.clear();

        expect(notificationCount, 1);
      });
    });
  });
}
