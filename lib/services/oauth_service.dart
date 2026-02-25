import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

import 'package:darkfeed/services/storage_service.dart';
import 'package:darkfeed/utils/constants.dart';
import 'package:darkfeed/utils/known_instances.dart';

/// Service for handling OAuth2 authentication with Pixelfed

class OAuthService {
  final StorageService _storageService;

  OAuthService(this._storageService);

  /// Get the appropriate callback URL for the current platform
  String _getCallbackUrl() {
    // On Linux with system browser, we need to use localhost with specific port
    if (Platform.isLinux) {
      return 'http://localhost:8080/callback';
    }
    // On other platforms, use custom scheme
    return oauthRedirectUri;
  }

  /// Get the callback URL scheme for the current platform
  /// On Linux, this is the full callback URL base (http://localhost:port)
  /// On other platforms, this is just the scheme (e.g., 'com.darkfeed')
  String _getCallbackScheme() {
    // On Linux with system browser, we need to pass the full localhost URL with port
    // flutter_web_auth_2 expects http://localhost:{port} format
    if (Platform.isLinux) {
      return 'http://localhost:8080';
    }
    // On other platforms, use custom scheme
    return oauthCustomScheme;
  }

  /// Execute OAuth2 authentication flow
  ///
  /// Returns the access token on success, throws exception on failure
  Future<String> authenticate(String instanceUrl) async {
    debugPrint('OAuth: Starting authentication for $instanceUrl');
    try {
      // Normalize instance URL and ensure it has https://
      final normalizedUrl = getFullInstanceUrl(instanceUrl);
      debugPrint('OAuth: Normalized URL = $normalizedUrl');

      // Step 1: Register OAuth application with Pixelfed instance
      debugPrint('OAuth: Registering app...');
      final callbackUrl = _getCallbackUrl();
      debugPrint('OAuth: Using callback URL = $callbackUrl');
      final appCredentials = await _registerApp(normalizedUrl, callbackUrl);
      debugPrint(
        'OAuth: App registered, client_id = ${appCredentials['client_id']}',
      );

      // Step 2: Build authorization URL
      final authUrl = Uri.parse('$normalizedUrl/oauth/authorize').replace(
        queryParameters: {
          'client_id': appCredentials['client_id'],
          'redirect_uri': callbackUrl,
          'response_type': 'code',
          'scope': oauthScopes.join(' '),
        },
      );
      debugPrint('OAuth: Authorization URL = $authUrl');

      // Step 3: Launch web auth to get authorization code
      debugPrint('OAuth: Launching browser for authorization...');
      String? result;
      String? code;

      // On Linux, use system browser instead of webview to avoid crashes
      final useSystemBrowser = Platform.isLinux;
      final callbackScheme = _getCallbackScheme();
      debugPrint('OAuth: Using system browser = $useSystemBrowser');
      debugPrint('OAuth: Callback scheme = $callbackScheme');

      try {
        result = await FlutterWebAuth2.authenticate(
          url: authUrl.toString(),
          callbackUrlScheme: callbackScheme,
          options: FlutterWebAuth2Options(
            preferEphemeral: true,
            useWebview: !useSystemBrowser,
          ),
        );
        debugPrint('OAuth: Browser returned, result = $result');

        // Step 4: Extract authorization code IMMEDIATELY
        // This ensures we have the code even if the webview crashes
        debugPrint('OAuth: Extracting authorization code from result...');
        code = Uri.parse(result).queryParameters['code'];
        if (code == null) {
          debugPrint('OAuth: ERROR - No authorization code in result');
          throw OAuthException('No authorization code received');
        }
        debugPrint('OAuth: Got authorization code (length: ${code.length})');
      } catch (webAuthError) {
        debugPrint('OAuth: WebAuth error: $webAuthError');
        // If we already extracted the code before the crash, continue
        // Otherwise rethrow
        if (code == null) {
          debugPrint(
            'OAuth: No authorization code extracted, rethrowing error',
          );
          rethrow;
        }
        debugPrint('OAuth: Webview crashed but we have code, continuing...');
      }

      // NO DELAY - proceed immediately to token exchange to avoid crash window
      debugPrint('OAuth: Proceeding immediately to token exchange...');

      // Step 5: Exchange authorization code for access token
      debugPrint('OAuth: Exchanging code for access token...');
      final tokenResponse = await http.post(
        Uri.parse('$normalizedUrl/oauth/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'authorization_code',
          'code': code,
          'client_id': appCredentials['client_id']!,
          'client_secret': appCredentials['client_secret']!,
          'redirect_uri': callbackUrl,
          'scope': oauthScopes.join(' '),
        },
      );

      debugPrint('OAuth: Token response status = ${tokenResponse.statusCode}');
      if (tokenResponse.statusCode != 200) {
        final errorBody = jsonDecode(tokenResponse.body);
        debugPrint('OAuth: Token exchange failed: $errorBody');
        throw OAuthException(
          'Token exchange failed: ${errorBody['error_description'] ?? errorBody['error'] ?? 'Unknown error'}',
        );
      }

      final tokenData = jsonDecode(tokenResponse.body);
      final accessToken = tokenData['access_token'] as String;

      debugPrint(
        'OAuth: Received access token (length: ${accessToken.length})',
      );

      // Save access token to secure storage
      try {
        debugPrint('OAuth: Saving access token...');
        await _storageService.saveAccessToken(accessToken);
        debugPrint('OAuth: Access token saved successfully');

        // Verify it was saved
        final verify = await _storageService.getAccessToken();
        debugPrint(
          'OAuth: Token verification = ${verify != null} (length: ${verify?.length ?? 0})',
        );
      } catch (e) {
        debugPrint('OAuth: ERROR saving token: $e');
        rethrow;
      }

      // Save token expiry (default to 1 year if not provided)
      final expiresIn = tokenData['expires_in'] as int? ?? 31536000; // 1 year
      final expiryTimestamp =
          DateTime.now().millisecondsSinceEpoch + (expiresIn * 1000);
      await _storageService.saveTokenExpiry(expiryTimestamp);
      debugPrint('OAuth: Token expiry saved: $expiryTimestamp');

      // Save instance URL (with https://)
      await _storageService.saveInstanceUrl(normalizedUrl);
      debugPrint('OAuth: Instance URL saved: $normalizedUrl');

      debugPrint('OAuth: Authentication completed successfully!');
      return accessToken;
    } catch (e, stackTrace) {
      debugPrint('OAuth: EXCEPTION during authentication: $e');
      debugPrint('OAuth: Stack trace: $stackTrace');
      throw OAuthException('OAuth authentication failed: $e');
    }
  }

  /// Register OAuth application with Pixelfed instance
  Future<Map<String, String>> _registerApp(
    String instanceUrl,
    String redirectUri,
  ) async {
    final response = await http.post(
      Uri.parse('$instanceUrl/api/v1/apps'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'client_name': appName,
        'redirect_uris': redirectUri,
        'scopes': oauthScopes.join(' '),
        'website': 'https://github.com/yourusername/darkfeed',
      },
    );

    if (response.statusCode != 200) {
      throw OAuthException('Failed to register app: ${response.body}');
    }

    final data = jsonDecode(response.body);
    return {
      'client_id': data['client_id'] as String,
      'client_secret': data['client_secret'] as String,
    };
  }

  /// Check if user is currently authenticated
  Future<bool> isAuthenticated() async {
    return await _storageService.isAuthenticated();
  }

  /// Logout user by clearing all auth data
  Future<void> logout() async {
    await _storageService.clearAuthData();
  }

  /// Get current access token
  Future<String?> getAccessToken() async {
    return await _storageService.getAccessToken();
  }

  /// Get current instance URL
  Future<String?> getInstanceUrl() async {
    return await _storageService.getInstanceUrl();
  }
}

/// Custom exception for OAuth errors
class OAuthException implements Exception {
  final String message;

  OAuthException(this.message);

  @override
  String toString() => message;
}
