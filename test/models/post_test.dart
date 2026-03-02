import 'package:flutter_test/flutter_test.dart';
import 'package:darkfeed/models/post.dart';

void main() {
  group('Post', () {
    test('fromJson creates Post from valid JSON', () {
      final json = {
        'id': '123',
        'account': {
          'id': '456',
          'username': 'testuser',
          'display_name': 'Test User',
          'avatar': 'https://example.com/avatar.jpg',
        },
        'content': '<p>Test content</p>',
        'created_at': '2026-02-28T12:00:00.000Z',
        'media_attachments': [],
        'favourited': true,
        'favourites_count': 42,
        'replies_count': 5,
        'reblogged': false,
        'reblogs_count': 10,
      };

      final post = Post.fromJson(json);

      expect(post.id, '123');
      expect(post.accountId, '456');
      expect(post.accountUsername, 'testuser');
      expect(post.accountDisplayName, 'Test User');
      expect(post.accountAvatar, 'https://example.com/avatar.jpg');
      expect(post.content, '<p>Test content</p>');
      expect(post.createdAt, DateTime.parse('2026-02-28T12:00:00.000Z'));
      expect(post.mediaAttachments, isEmpty);
      expect(post.favourited, true);
      expect(post.favouritesCount, 42);
      expect(post.repliesCount, 5);
      expect(post.reblogged, false);
      expect(post.reblogsCount, 10);
    });

    test('fromJson uses username as displayName when displayName is null', () {
      final json = {
        'id': '123',
        'account': {'id': '456', 'username': 'testuser'},
        'created_at': '2026-02-28T12:00:00.000Z',
        'media_attachments': [],
      };

      final post = Post.fromJson(json);

      expect(post.accountDisplayName, 'testuser');
    });

    test('fromJson handles null optional fields with defaults', () {
      final json = {
        'id': '123',
        'account': {'id': '456', 'username': 'testuser'},
        'created_at': '2026-02-28T12:00:00.000Z',
      };

      final post = Post.fromJson(json);

      expect(post.accountAvatar, null);
      expect(post.content, null);
      expect(post.mediaAttachments, isEmpty);
      expect(post.favourited, false);
      expect(post.favouritesCount, 0);
      expect(post.repliesCount, 0);
      expect(post.reblogged, false);
      expect(post.reblogsCount, 0);
    });

    test('fromJson parses media attachments', () {
      final json = {
        'id': '123',
        'account': {'id': '456', 'username': 'testuser'},
        'created_at': '2026-02-28T12:00:00.000Z',
        'media_attachments': [
          {
            'id': '789',
            'type': 'image',
            'url': 'https://example.com/image.jpg',
            'preview_url': 'https://example.com/preview.jpg',
          },
        ],
      };

      final post = Post.fromJson(json);

      expect(post.mediaAttachments.length, 1);
      expect(post.mediaAttachments[0].id, '789');
      expect(post.mediaAttachments[0].type, 'image');
    });

    test('copyWith creates new Post with updated fields', () {
      final original = Post(
        id: '123',
        accountId: '456',
        accountUsername: 'testuser',
        accountDisplayName: 'Test User',
        accountAvatar: 'https://example.com/avatar.jpg',
        content: 'Test content',
        createdAt: DateTime.parse('2026-02-28T12:00:00.000Z'),
        mediaAttachments: [],
        favourited: false,
        favouritesCount: 10,
        repliesCount: 5,
        reblogged: false,
        reblogsCount: 3,
      );

      final updated = original.copyWith(favourited: true, favouritesCount: 11);

      expect(updated.id, original.id);
      expect(updated.accountId, original.accountId);
      expect(updated.favourited, true);
      expect(updated.favouritesCount, 11);
      expect(updated.reblogged, false);
      expect(updated.reblogsCount, 3);
    });

    test('copyWith preserves original values when not specified', () {
      final original = Post(
        id: '123',
        accountId: '456',
        accountUsername: 'testuser',
        accountDisplayName: 'Test User',
        createdAt: DateTime.parse('2026-02-28T12:00:00.000Z'),
        mediaAttachments: [],
        favourited: true,
        favouritesCount: 10,
        repliesCount: 5,
        reblogged: true,
        reblogsCount: 3,
      );

      final updated = original.copyWith();

      expect(updated.favourited, original.favourited);
      expect(updated.favouritesCount, original.favouritesCount);
      expect(updated.reblogged, original.reblogged);
      expect(updated.reblogsCount, original.reblogsCount);
    });
  });

  group('MediaAttachment', () {
    test('fromJson creates MediaAttachment from valid JSON', () {
      final json = {
        'id': '789',
        'type': 'image',
        'url': 'https://example.com/image.jpg',
        'preview_url': 'https://example.com/preview.jpg',
        'description': 'A test image',
      };

      final media = MediaAttachment.fromJson(json);

      expect(media.id, '789');
      expect(media.type, 'image');
      expect(media.url, 'https://example.com/image.jpg');
      expect(media.previewUrl, 'https://example.com/preview.jpg');
      expect(media.description, 'A test image');
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'id': '789',
        'type': 'image',
        'url': 'https://example.com/image.jpg',
      };

      final media = MediaAttachment.fromJson(json);

      expect(media.previewUrl, null);
      expect(media.description, null);
      expect(media.width, null);
      expect(media.height, null);
    });

    test('fromJson extracts dimensions from meta.original', () {
      final json = {
        'id': '789',
        'type': 'image',
        'url': 'https://example.com/image.jpg',
        'meta': {
          'original': {'width': 1920, 'height': 1080},
        },
      };

      final media = MediaAttachment.fromJson(json);

      expect(media.width, 1920);
      expect(media.height, 1080);
    });

    test('fromJson handles missing meta gracefully', () {
      final json = {
        'id': '789',
        'type': 'image',
        'url': 'https://example.com/image.jpg',
        'meta': {},
      };

      final media = MediaAttachment.fromJson(json);

      expect(media.width, null);
      expect(media.height, null);
    });
  });

  group('Comment', () {
    test('fromJson creates Comment from valid JSON', () {
      final json = {
        'id': '321',
        'account': {
          'id': '654',
          'username': 'commenter',
          'display_name': 'The Commenter',
          'avatar': 'https://example.com/avatar2.jpg',
        },
        'content': '<p>Great post!</p>',
        'created_at': '2026-02-28T13:00:00.000Z',
      };

      final comment = Comment.fromJson(json);

      expect(comment.id, '321');
      expect(comment.accountId, '654');
      expect(comment.accountUsername, 'commenter');
      expect(comment.accountDisplayName, 'The Commenter');
      expect(comment.accountAvatar, 'https://example.com/avatar2.jpg');
      expect(comment.content, '<p>Great post!</p>');
      expect(comment.createdAt, DateTime.parse('2026-02-28T13:00:00.000Z'));
    });

    test('fromJson uses username as displayName when displayName is null', () {
      final json = {
        'id': '321',
        'account': {'id': '654', 'username': 'commenter'},
        'created_at': '2026-02-28T13:00:00.000Z',
      };

      final comment = Comment.fromJson(json);

      expect(comment.accountDisplayName, 'commenter');
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'id': '321',
        'account': {'id': '654', 'username': 'commenter'},
        'created_at': '2026-02-28T13:00:00.000Z',
      };

      final comment = Comment.fromJson(json);

      expect(comment.accountAvatar, null);
      expect(comment.content, null);
    });
  });

  group('UserAccount', () {
    test('fromJson creates UserAccount from valid JSON', () {
      final json = {
        'id': '999',
        'username': 'johndoe',
        'display_name': 'John Doe',
        'avatar': 'https://example.com/avatar3.jpg',
        'header': 'https://example.com/header.jpg',
        'note': '<p>Software developer</p>',
        'followers_count': 150,
        'following_count': 75,
        'statuses_count': 342,
      };

      final account = UserAccount.fromJson(json);

      expect(account.id, '999');
      expect(account.username, 'johndoe');
      expect(account.displayName, 'John Doe');
      expect(account.avatar, 'https://example.com/avatar3.jpg');
      expect(account.header, 'https://example.com/header.jpg');
      expect(account.note, '<p>Software developer</p>');
      expect(account.followersCount, 150);
      expect(account.followingCount, 75);
      expect(account.statusesCount, 342);
    });

    test('fromJson uses username as displayName when displayName is null', () {
      final json = {'id': '999', 'username': 'johndoe'};

      final account = UserAccount.fromJson(json);

      expect(account.displayName, 'johndoe');
    });

    test('fromJson handles null optional fields with defaults', () {
      final json = {'id': '999', 'username': 'johndoe'};

      final account = UserAccount.fromJson(json);

      expect(account.avatar, null);
      expect(account.header, null);
      expect(account.note, null);
      expect(account.followersCount, 0);
      expect(account.followingCount, 0);
      expect(account.statusesCount, 0);
    });

    test('fromJson handles zero counts explicitly', () {
      final json = {
        'id': '999',
        'username': 'newuser',
        'followers_count': 0,
        'following_count': 0,
        'statuses_count': 0,
      };

      final account = UserAccount.fromJson(json);

      expect(account.followersCount, 0);
      expect(account.followingCount, 0);
      expect(account.statusesCount, 0);
    });
  });
}
