import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:darkfeed/models/post.dart';
import 'package:darkfeed/services/storage_service.dart';
import 'package:darkfeed/utils/constants.dart';

/// Service for interacting with Pixelfed API
///
/// Uses direct HTTP requests instead of mastodon_api package to handle
/// Pixelfed's JSON response format which differs slightly from Mastodon

class PixelfedService {
  final StorageService _storageService;
  String? _instanceUrl;
  String? _bearerToken;

  PixelfedService(this._storageService);

  /// Initialize the API client with stored credentials
  Future<void> initialize() async {
    final token = await _storageService.getAccessToken();
    final instanceUrl = await _storageService.getInstanceUrl();

    if (token == null || instanceUrl == null) {
      throw PixelfedException('Not authenticated');
    }

    // Store credentials for making requests
    _instanceUrl = instanceUrl;
    _bearerToken = token;
  }

  /// Ensure API is initialized
  void _ensureInitialized() {
    if (_instanceUrl == null || _bearerToken == null) {
      throw PixelfedException('API not initialized. Call initialize() first.');
    }
  }

  /// Make an authenticated GET request to the Pixelfed API
  Future<dynamic> _get(String endpoint) async {
    _ensureInitialized();

    final url = Uri.parse('$_instanceUrl$endpoint');
    debugPrint('PixelfedService: GET $url');

    final response = await http
        .get(
          url,
          headers: {
            'Authorization': 'Bearer $_bearerToken',
            'Accept': 'application/json',
          },
        )
        .timeout(apiTimeout);

    debugPrint('PixelfedService: Response status = ${response.statusCode}');

    if (response.statusCode != 200) {
      throw PixelfedException(
        'API request failed: ${response.statusCode} ${response.reasonPhrase}',
      );
    }

    return jsonDecode(response.body);
  }

  /// Make an authenticated POST request to the Pixelfed API
  Future<dynamic> _post(String endpoint, {Map<String, dynamic>? body}) async {
    _ensureInitialized();

    final url = Uri.parse('$_instanceUrl$endpoint');
    debugPrint('PixelfedService: POST $url');

    final response = await http
        .post(
          url,
          headers: {
            'Authorization': 'Bearer $_bearerToken',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(apiTimeout);

    debugPrint('PixelfedService: Response status = ${response.statusCode}');

    if (response.statusCode != 200) {
      throw PixelfedException(
        'API request failed: ${response.statusCode} ${response.reasonPhrase}',
      );
    }

    return jsonDecode(response.body);
  }

  // Timeline Methods

  /// Get home timeline with optional pagination
  ///
  /// Returns list of posts (Post objects)
  /// Filters for image posts only
  Future<List<Post>> getHomeTimeline({
    String? maxId,
    String? sinceId,
    int limit = timelinePageSize,
  }) async {
    _ensureInitialized();

    try {
      debugPrint('PixelfedService: Fetching home timeline...');

      final queryParams = {
        'limit': limit.toString(),
        ...?maxId != null ? {'max_id': maxId} : null,
        ...?sinceId != null ? {'since_id': sinceId} : null,
      };

      final queryString = queryParams.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final jsonResponse = await _get('/api/v1/timelines/home?$queryString');
      final List<dynamic> postsJson = jsonResponse as List<dynamic>;

      debugPrint('PixelfedService: Received ${postsJson.length} posts');

      // Parse posts and filter for media posts
      final posts = postsJson
          .map((json) => Post.fromJson(json as Map<String, dynamic>))
          .where((post) => post.mediaAttachments.isNotEmpty)
          .toList();

      debugPrint('PixelfedService: Filtered to ${posts.length} media posts');
      return posts;
    } catch (e, stackTrace) {
      debugPrint('PixelfedService error: $e');
      debugPrint('Stack trace: $stackTrace');
      throw PixelfedException('Failed to load timeline: $e');
    }
  }

  /// Get current user's account information
  Future<UserAccount> getCurrentUser() async {
    _ensureInitialized();

    try {
      final jsonResponse = await _get('/api/v1/accounts/verify_credentials');
      return UserAccount.fromJson(jsonResponse as Map<String, dynamic>);
    } catch (e) {
      throw PixelfedException('Failed to get current user: $e');
    }
  }

  // Post Interactions

  /// Like a post
  Future<Post> likePost(String postId) async {
    _ensureInitialized();

    try {
      final jsonResponse = await _post('/api/v1/statuses/$postId/favourite');
      return Post.fromJson(jsonResponse as Map<String, dynamic>);
    } catch (e) {
      throw PixelfedException('Failed to like post: $e');
    }
  }

  /// Unlike a post
  Future<Post> unlikePost(String postId) async {
    _ensureInitialized();

    try {
      final jsonResponse = await _post('/api/v1/statuses/$postId/unfavourite');
      return Post.fromJson(jsonResponse as Map<String, dynamic>);
    } catch (e) {
      throw PixelfedException('Failed to unlike post: $e');
    }
  }

  /// Repost (reblog) a post
  Future<Post> repostPost(String postId) async {
    _ensureInitialized();

    try {
      final jsonResponse = await _post('/api/v1/statuses/$postId/reblog');
      return Post.fromJson(jsonResponse as Map<String, dynamic>);
    } catch (e) {
      throw PixelfedException('Failed to repost post: $e');
    }
  }

  /// Unrepost (unreblog) a post
  Future<Post> unrepostPost(String postId) async {
    _ensureInitialized();

    try {
      final jsonResponse = await _post('/api/v1/statuses/$postId/unreblog');
      return Post.fromJson(jsonResponse as Map<String, dynamic>);
    } catch (e) {
      throw PixelfedException('Failed to unrepost post: $e');
    }
  }

  // Comments

  /// Get comments for a post
  ///
  /// Returns descendants (replies/comments) from the context
  Future<List<Comment>> getComments(String postId) async {
    _ensureInitialized();

    try {
      final jsonResponse = await _get('/api/v1/statuses/$postId/context');
      final contextJson = jsonResponse as Map<String, dynamic>;
      final List<dynamic> descendantsJson =
          contextJson['descendants'] as List<dynamic>;

      return descendantsJson
          .map((json) => Comment.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw PixelfedException('Failed to get comments: $e');
    }
  }

  // User Profile

  /// Get user account information
  Future<UserAccount> getUserProfile(String userId) async {
    _ensureInitialized();

    try {
      final jsonResponse = await _get('/api/v1/accounts/$userId');
      return UserAccount.fromJson(jsonResponse as Map<String, dynamic>);
    } catch (e) {
      throw PixelfedException('Failed to get user profile: $e');
    }
  }

  /// Get user's posts (photos only)
  Future<List<Post>> getUserPosts({
    required String userId,
    String? maxId,
    int limit = timelinePageSize,
  }) async {
    _ensureInitialized();

    try {
      final queryParams = {
        'limit': limit.toString(),
        ...?maxId != null ? {'max_id': maxId} : null,
      };

      final queryString = queryParams.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final jsonResponse = await _get(
        '/api/v1/accounts/$userId/statuses?$queryString',
      );
      final List<dynamic> postsJson = jsonResponse as List<dynamic>;

      // Filter for media posts
      return postsJson
          .map((json) => Post.fromJson(json as Map<String, dynamic>))
          .where((post) => post.mediaAttachments.isNotEmpty)
          .toList();
    } catch (e) {
      throw PixelfedException('Failed to get user posts: $e');
    }
  }

  /// Dispose API client
  void dispose() {
    _instanceUrl = null;
    _bearerToken = null;
  }
}

/// Custom exception for Pixelfed API errors
class PixelfedException implements Exception {
  final String message;

  PixelfedException(this.message);

  @override
  String toString() => message;
}
