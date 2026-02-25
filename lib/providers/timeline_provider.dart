import 'package:flutter/foundation.dart';

import 'package:darkfeed/models/post.dart';
import 'package:darkfeed/services/pixelfed_service.dart';

/// Provider for managing timeline posts and interactions
class TimelineProvider with ChangeNotifier {
  final PixelfedService _pixelfedService;

  TimelineProvider(this._pixelfedService);

  List<Post> _posts = [];
  bool _isLoading = false;
  bool _isLoadingMore = false; // Separate flag for pagination loading
  String? _error;
  int _currentIndex = 0;
  int _currentImageIndex = 0; // Track current image index for multi-image posts

  List<Post> get posts => _posts;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  int get currentIndex => _currentIndex;
  int get currentImageIndex => _currentImageIndex;
  Post? get currentPost => _posts.isNotEmpty && _currentIndex < _posts.length
      ? _posts[_currentIndex]
      : null;

  /// Load home timeline, filtering for image posts only
  Future<void> loadTimeline() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('TimelineProvider: Loading timeline...');
      final allPosts = await _pixelfedService.getHomeTimeline();
      debugPrint('TimelineProvider: Received ${allPosts.length} posts');

      // Posts are already filtered for media in the service
      _posts = allPosts;

      debugPrint('TimelineProvider: Loaded ${_posts.length} image posts');
      _currentIndex = 0;
      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (e, stackTrace) {
      _error = 'Failed to load timeline: $e';
      _isLoading = false;
      debugPrint('TimelineProvider error: $e');
      debugPrint('Stack trace: $stackTrace');
      notifyListeners();
    }
  }

  /// Navigate to next post
  void nextPost() {
    if (_currentIndex < _posts.length - 1) {
      _currentIndex++;
      _currentImageIndex = 0; // Reset image index when changing posts
      notifyListeners();

      // Preload more posts when approaching the end
      if (_currentIndex >= _posts.length - 3 && !_isLoadingMore) {
        debugPrint(
          'TimelineProvider: Approaching end (${_currentIndex + 1}/${_posts.length}), loading more...',
        );
        _loadMorePosts();
      }
    }
  }

  /// Navigate to previous post
  void previousPost() {
    if (_currentIndex > 0) {
      _currentIndex--;
      _currentImageIndex = 0; // Reset image index when changing posts
      notifyListeners();
    }
  }

  /// Navigate to next image in current post
  void nextImage() {
    final post = currentPost;
    if (post == null) return;

    if (_currentImageIndex < post.mediaAttachments.length - 1) {
      _currentImageIndex++;
      debugPrint(
        'TimelineProvider: Next image (${_currentImageIndex + 1}/${post.mediaAttachments.length})',
      );
      notifyListeners();
    }
  }

  /// Navigate to previous image in current post
  void previousImage() {
    if (_currentImageIndex > 0) {
      _currentImageIndex--;
      debugPrint(
        'TimelineProvider: Previous image (${_currentImageIndex + 1}/${currentPost?.mediaAttachments.length})',
      );
      notifyListeners();
    }
  }

  /// Jump to specific post index
  void setCurrentIndex(int index) {
    if (index >= 0 && index < _posts.length) {
      _currentIndex = index;
      _currentImageIndex = 0; // Reset image index when changing posts
      notifyListeners();

      // Preload more posts when approaching the end
      if (index >= _posts.length - 3 && !_isLoadingMore) {
        debugPrint(
          'TimelineProvider: Approaching end (${index + 1}/${_posts.length}), loading more...',
        );
        _loadMorePosts();
      }
    }
  }

  /// Load more posts (pagination)
  Future<void> _loadMorePosts() async {
    if (_isLoadingMore || _posts.isEmpty) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final oldestPostId = _posts.last.id;
      debugPrint('TimelineProvider: Loading more posts after ID $oldestPostId');

      final morePosts = await _pixelfedService.getHomeTimeline(
        maxId: oldestPostId,
      );

      debugPrint('TimelineProvider: Loaded ${morePosts.length} more posts');

      // Posts are already filtered for media in the service
      if (morePosts.isNotEmpty) {
        _posts.addAll(morePosts);
        debugPrint('TimelineProvider: Total posts now: ${_posts.length}');
      } else {
        debugPrint('TimelineProvider: No more posts available');
      }

      _isLoadingMore = false;
      notifyListeners();
    } catch (e) {
      // Don't fail the whole timeline - just log the error
      debugPrint('TimelineProvider: Failed to load more posts: $e');
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Like a post
  Future<void> likePost(String statusId) async {
    try {
      await _pixelfedService.likePost(statusId);

      // Update local state
      final index = _posts.indexWhere((post) => post.id == statusId);
      if (index != -1) {
        _posts[index] = _posts[index].copyWith(
          favourited: true,
          favouritesCount: _posts[index].favouritesCount + 1,
        );
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to like post: $e';
      notifyListeners();
    }
  }

  /// Unlike a post
  Future<void> unlikePost(String statusId) async {
    try {
      await _pixelfedService.unlikePost(statusId);

      // Update local state
      final index = _posts.indexWhere((post) => post.id == statusId);
      if (index != -1) {
        _posts[index] = _posts[index].copyWith(
          favourited: false,
          favouritesCount: _posts[index].favouritesCount > 0
              ? _posts[index].favouritesCount - 1
              : 0,
        );
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to unlike post: $e';
      notifyListeners();
    }
  }

  /// Repost a post
  Future<void> repostPost(String statusId) async {
    try {
      await _pixelfedService.repostPost(statusId);

      // Update local state
      final index = _posts.indexWhere((post) => post.id == statusId);
      if (index != -1) {
        _posts[index] = _posts[index].copyWith(
          reblogged: true,
          reblogsCount: _posts[index].reblogsCount + 1,
        );
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to repost post: $e';
      notifyListeners();
    }
  }

  /// Unrepost a post
  Future<void> unrepostPost(String statusId) async {
    try {
      await _pixelfedService.unrepostPost(statusId);

      // Update local state
      final index = _posts.indexWhere((post) => post.id == statusId);
      if (index != -1) {
        _posts[index] = _posts[index].copyWith(
          reblogged: false,
          reblogsCount: _posts[index].reblogsCount > 0
              ? _posts[index].reblogsCount - 1
              : 0,
        );
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to unrepost post: $e';
      notifyListeners();
    }
  }

  /// Toggle like/unlike for current post
  Future<void> toggleLike() async {
    final post = currentPost;
    if (post == null) return;

    debugPrint('TimelineProvider: Toggle like called for post ${post.id}');
    if (post.favourited == true) {
      debugPrint('TimelineProvider: Unliking post');
      await unlikePost(post.id);
    } else {
      debugPrint('TimelineProvider: Liking post');
      await likePost(post.id);
    }
  }

  /// Toggle repost/unrepost for current post
  Future<void> toggleRepost() async {
    final post = currentPost;
    if (post == null) return;

    debugPrint('TimelineProvider: Toggle repost called for post ${post.id}');
    if (post.reblogged == true) {
      debugPrint('TimelineProvider: Unreposting post');
      await unrepostPost(post.id);
    } else {
      debugPrint('TimelineProvider: Reposting post');
      await repostPost(post.id);
    }
  }

  /// Refresh timeline
  Future<void> refresh() async {
    await loadTimeline();
  }

  /// Clear all posts and reset state
  void clear() {
    _posts = [];
    _currentIndex = 0;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
