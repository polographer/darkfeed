/// Minimal post model for DarkFeed
///
/// This is a simplified model that extracts only the data we need from
/// Pixelfed's API responses, avoiding parsing issues with mastodon_api package
library;

class Post {
  final String id;
  final String accountId;
  final String accountUsername;
  final String accountDisplayName;
  final String? accountAvatar;
  final String? content;
  final DateTime createdAt;
  final List<MediaAttachment> mediaAttachments;
  final bool favourited;
  final int favouritesCount;
  final int repliesCount;
  final bool reblogged;
  final int reblogsCount;

  Post({
    required this.id,
    required this.accountId,
    required this.accountUsername,
    required this.accountDisplayName,
    this.accountAvatar,
    this.content,
    required this.createdAt,
    required this.mediaAttachments,
    required this.favourited,
    required this.favouritesCount,
    required this.repliesCount,
    required this.reblogged,
    required this.reblogsCount,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    final account = json['account'] as Map<String, dynamic>;
    final mediaList = (json['media_attachments'] as List<dynamic>?) ?? [];

    return Post(
      id: json['id'] as String,
      accountId: account['id'] as String,
      accountUsername: account['username'] as String,
      accountDisplayName:
          account['display_name'] as String? ?? account['username'] as String,
      accountAvatar: account['avatar'] as String?,
      content: json['content'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      mediaAttachments: mediaList
          .map((m) => MediaAttachment.fromJson(m as Map<String, dynamic>))
          .toList(),
      favourited: json['favourited'] as bool? ?? false,
      favouritesCount: json['favourites_count'] as int? ?? 0,
      repliesCount: json['replies_count'] as int? ?? 0,
      reblogged: json['reblogged'] as bool? ?? false,
      reblogsCount: json['reblogs_count'] as int? ?? 0,
    );
  }

  /// Create a copy with updated fields
  Post copyWith({
    bool? favourited,
    int? favouritesCount,
    bool? reblogged,
    int? reblogsCount,
  }) {
    return Post(
      id: id,
      accountId: accountId,
      accountUsername: accountUsername,
      accountDisplayName: accountDisplayName,
      accountAvatar: accountAvatar,
      content: content,
      createdAt: createdAt,
      mediaAttachments: mediaAttachments,
      favourited: favourited ?? this.favourited,
      favouritesCount: favouritesCount ?? this.favouritesCount,
      repliesCount: repliesCount,
      reblogged: reblogged ?? this.reblogged,
      reblogsCount: reblogsCount ?? this.reblogsCount,
    );
  }
}

class MediaAttachment {
  final String id;
  final String type;
  final String url;
  final String? previewUrl;
  final String? description;
  final int? width;
  final int? height;

  MediaAttachment({
    required this.id,
    required this.type,
    required this.url,
    this.previewUrl,
    this.description,
    this.width,
    this.height,
  });

  factory MediaAttachment.fromJson(Map<String, dynamic> json) {
    // Try to extract dimensions from meta if available
    int? width;
    int? height;

    final meta = json['meta'];
    if (meta != null && meta is Map) {
      final original = meta['original'];
      if (original != null && original is Map) {
        width = original['width'] as int?;
        height = original['height'] as int?;
      }
    }

    return MediaAttachment(
      id: json['id'] as String,
      type: json['type'] as String,
      url: json['url'] as String,
      previewUrl: json['preview_url'] as String?,
      description: json['description'] as String?,
      width: width,
      height: height,
    );
  }
}

class Comment {
  final String id;
  final String accountId;
  final String accountUsername;
  final String accountDisplayName;
  final String? accountAvatar;
  final String? content;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.accountId,
    required this.accountUsername,
    required this.accountDisplayName,
    this.accountAvatar,
    this.content,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    final account = json['account'] as Map<String, dynamic>;

    return Comment(
      id: json['id'] as String,
      accountId: account['id'] as String,
      accountUsername: account['username'] as String,
      accountDisplayName:
          account['display_name'] as String? ?? account['username'] as String,
      accountAvatar: account['avatar'] as String?,
      content: json['content'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class UserAccount {
  final String id;
  final String username;
  final String displayName;
  final String? avatar;
  final String? header;
  final String? note;
  final int followersCount;
  final int followingCount;
  final int statusesCount;

  UserAccount({
    required this.id,
    required this.username,
    required this.displayName,
    this.avatar,
    this.header,
    this.note,
    required this.followersCount,
    required this.followingCount,
    required this.statusesCount,
  });

  factory UserAccount.fromJson(Map<String, dynamic> json) {
    return UserAccount(
      id: json['id'] as String,
      username: json['username'] as String,
      displayName:
          json['display_name'] as String? ?? json['username'] as String,
      avatar: json['avatar'] as String?,
      header: json['header'] as String?,
      note: json['note'] as String?,
      followersCount: json['followers_count'] as int? ?? 0,
      followingCount: json['following_count'] as int? ?? 0,
      statusesCount: json['statuses_count'] as int? ?? 0,
    );
  }
}
