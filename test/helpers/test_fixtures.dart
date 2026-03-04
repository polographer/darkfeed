import 'dart:ui';

import 'package:darkfeed/utils/constants.dart';
import 'package:darkfeed/models/post.dart';

/// Test fixtures for authentication testing
class AuthTestFixtures {
  /// Create a test UserAccount with default or custom values
  static UserAccount createTestUserAccount({
    String id = 'user123',
    String username = 'testuser',
    String displayName = 'Test User',
    String avatar = 'https://example.com/avatar.jpg',
    int followersCount = 100,
    int followingCount = 50,
    int statusesCount = 10,
  }) {
    return UserAccount(
      id: id,
      username: username,
      displayName: displayName,
      avatar: avatar,
      followersCount: followersCount,
      followingCount: followingCount,
      statusesCount: statusesCount,
    );
  }
}

/// Test fixtures for general testing
class TestFixtures {
  /// Create a test post with default or custom values
  static Post createTestPost({
    String id = '123',
    String content = 'Test post content',
    bool favourited = false,
    bool reblogged = false,
    int favouritesCount = 0,
    int reblogsCount = 0,
    int mediaCount = 2,
  }) {
    final mediaAttachments = List.generate(
      mediaCount,
      (index) => MediaAttachment(
        id: 'media_$index',
        type: 'image',
        url: 'https://example.com/media_$index.jpg',
        previewUrl: 'https://example.com/media_${index}_preview.jpg',
        description: 'Test image $index',
      ),
    );

    return Post(
      id: id,
      accountId: 'user123',
      accountUsername: 'testuser',
      accountDisplayName: 'Test User',
      accountAvatar: 'https://example.com/avatar.jpg',
      content: content,
      createdAt: DateTime.now(),
      mediaAttachments: mediaAttachments,
      favourited: favourited,
      reblogged: reblogged,
      favouritesCount: favouritesCount,
      reblogsCount: reblogsCount,
      repliesCount: 0,
    );
  }
}

/// Test fixtures for window testing
class WindowTestFixtures {
  // Common window sizes
  static const Size defaultSize = Size(1280, 720);
  static const Size hdSize = Size(1920, 1080);
  static const Size customSize = Size(1600, 900);
  static const Size smallSize = Size(800, 600);
  static const Size invalidSize = Size(0, 0);
  static const Size negativeSize = Size(-100, -100);
  static const Size offscreenSize = Size(10000, 10000);
  static const Size tooSmallSize = Size(50, 50);

  // Settings maps for testing storage
  static Map<String, dynamic> noSettings() => {};

  static Map<String, dynamic> sizedSettings({
    double width = 1600.0,
    double height = 900.0,
    bool maximized = false,
  }) => {
    StorageKeys.windowWidth: width,
    StorageKeys.windowHeight: height,
    StorageKeys.windowMaximized: maximized,
  };

  static Map<String, dynamic> maximizedSettings() => {
    StorageKeys.windowMaximized: true,
  };

  static Map<String, dynamic> invalidSettings() => {
    StorageKeys.windowWidth: 0.0,
    StorageKeys.windowHeight: 0.0,
    StorageKeys.windowMaximized: false,
  };

  static Map<String, dynamic> partialSettings() => {
    StorageKeys.windowWidth: 1600.0,
    // Missing height and maximized
  };
}
