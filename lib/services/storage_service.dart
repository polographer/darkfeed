import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:darkfeed/utils/constants.dart';

/// Service for persisting data securely and in shared preferences
///
/// On Linux, flutter_secure_storage has known issues. This service falls back
/// to SharedPreferences for token storage on Linux (less secure but functional).

class StorageService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  SharedPreferences? _prefs;
  bool _useSecureStorage = true;
  bool _hasCheckedSecureStorage = false;

  /// Initialize shared preferences
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    // Check if secure storage is working on first use
    if (!_hasCheckedSecureStorage && Platform.isLinux) {
      try {
        await _secureStorage.read(key: 'test_key');
        _useSecureStorage = true;
        debugPrint('StorageService: Secure storage is working on Linux');
      } catch (e) {
        _useSecureStorage = false;
        debugPrint(
          'StorageService: Secure storage failed on Linux, using SharedPreferences fallback',
        );
        debugPrint(
          'StorageService: WARNING - Tokens will be stored less securely!',
        );
      }
      _hasCheckedSecureStorage = true;
    }
  }

  // OAuth Token Management (Secure Storage with SharedPreferences fallback)

  /// Save OAuth access token
  Future<void> saveAccessToken(String token) async {
    if (_prefs == null) await init();

    if (_useSecureStorage) {
      try {
        await _secureStorage.write(key: StorageKeys.accessToken, value: token);
        return;
      } catch (e) {
        debugPrint(
          'StorageService: Secure storage write failed, falling back to SharedPreferences',
        );
        _useSecureStorage = false;
      }
    }

    // Fallback to SharedPreferences
    await _prefs!.setString(StorageKeys.accessToken, token);
  }

  /// Get OAuth access token
  Future<String?> getAccessToken() async {
    if (_prefs == null) await init();

    if (_useSecureStorage) {
      try {
        return await _secureStorage.read(key: StorageKeys.accessToken);
      } catch (e) {
        debugPrint(
          'StorageService: Secure storage read failed, falling back to SharedPreferences',
        );
        _useSecureStorage = false;
      }
    }

    // Fallback to SharedPreferences
    return _prefs!.getString(StorageKeys.accessToken);
  }

  /// Save OAuth refresh token
  Future<void> saveRefreshToken(String token) async {
    if (_prefs == null) await init();

    if (_useSecureStorage) {
      try {
        await _secureStorage.write(key: StorageKeys.refreshToken, value: token);
        return;
      } catch (e) {
        _useSecureStorage = false;
      }
    }

    await _prefs!.setString(StorageKeys.refreshToken, token);
  }

  /// Get OAuth refresh token
  Future<String?> getRefreshToken() async {
    if (_prefs == null) await init();

    if (_useSecureStorage) {
      try {
        return await _secureStorage.read(key: StorageKeys.refreshToken);
      } catch (e) {
        _useSecureStorage = false;
      }
    }

    return _prefs!.getString(StorageKeys.refreshToken);
  }

  /// Save token expiry timestamp
  Future<void> saveTokenExpiry(int timestamp) async {
    if (_prefs == null) await init();

    if (_useSecureStorage) {
      try {
        await _secureStorage.write(
          key: StorageKeys.tokenExpiry,
          value: timestamp.toString(),
        );
        return;
      } catch (e) {
        _useSecureStorage = false;
      }
    }

    await _prefs!.setString(StorageKeys.tokenExpiry, timestamp.toString());
  }

  /// Get token expiry timestamp
  Future<int?> getTokenExpiry() async {
    if (_prefs == null) await init();

    String? expiryStr;

    if (_useSecureStorage) {
      try {
        expiryStr = await _secureStorage.read(key: StorageKeys.tokenExpiry);
      } catch (e) {
        _useSecureStorage = false;
      }
    }

    expiryStr ??= _prefs!.getString(StorageKeys.tokenExpiry);

    return expiryStr != null ? int.tryParse(expiryStr) : null;
  }

  /// Check if token is expired
  Future<bool> isTokenExpired() async {
    final expiry = await getTokenExpiry();
    if (expiry == null) return true;
    return DateTime.now().millisecondsSinceEpoch >= expiry;
  }

  // Instance URL Management (Shared Preferences)

  /// Save selected instance URL
  Future<void> saveInstanceUrl(String url) async {
    if (_prefs == null) await init();
    await _prefs!.setString(StorageKeys.instanceUrl, url);
  }

  /// Get saved instance URL
  Future<String?> getInstanceUrl() async {
    if (_prefs == null) await init();
    return _prefs!.getString(StorageKeys.instanceUrl);
  }

  // User Information (Secure Storage with SharedPreferences fallback)

  /// Save user ID
  Future<void> saveUserId(String userId) async {
    if (_prefs == null) await init();

    if (_useSecureStorage) {
      try {
        await _secureStorage.write(key: StorageKeys.userId, value: userId);
        return;
      } catch (e) {
        _useSecureStorage = false;
      }
    }

    await _prefs!.setString(StorageKeys.userId, userId);
  }

  /// Get user ID
  Future<String?> getUserId() async {
    if (_prefs == null) await init();

    if (_useSecureStorage) {
      try {
        return await _secureStorage.read(key: StorageKeys.userId);
      } catch (e) {
        _useSecureStorage = false;
      }
    }

    return _prefs!.getString(StorageKeys.userId);
  }

  /// Save username
  Future<void> saveUsername(String username) async {
    if (_prefs == null) await init();

    if (_useSecureStorage) {
      try {
        await _secureStorage.write(key: StorageKeys.username, value: username);
        return;
      } catch (e) {
        _useSecureStorage = false;
      }
    }

    await _prefs!.setString(StorageKeys.username, username);
  }

  /// Get username
  Future<String?> getUsername() async {
    if (_prefs == null) await init();

    if (_useSecureStorage) {
      try {
        return await _secureStorage.read(key: StorageKeys.username);
      } catch (e) {
        _useSecureStorage = false;
      }
    }

    return _prefs!.getString(StorageKeys.username);
  }

  // Clear All Data

  /// Clear all OAuth tokens and user data (logout)
  Future<void> clearAuthData() async {
    if (_prefs == null) await init();

    if (_useSecureStorage) {
      try {
        await _secureStorage.delete(key: StorageKeys.accessToken);
        await _secureStorage.delete(key: StorageKeys.refreshToken);
        await _secureStorage.delete(key: StorageKeys.tokenExpiry);
        await _secureStorage.delete(key: StorageKeys.userId);
        await _secureStorage.delete(key: StorageKeys.username);
        return;
      } catch (e) {
        _useSecureStorage = false;
      }
    }

    // Fallback: clear from SharedPreferences
    await _prefs!.remove(StorageKeys.accessToken);
    await _prefs!.remove(StorageKeys.refreshToken);
    await _prefs!.remove(StorageKeys.tokenExpiry);
    await _prefs!.remove(StorageKeys.userId);
    await _prefs!.remove(StorageKeys.username);
  }

  /// Clear all data including instance
  Future<void> clearAllData() async {
    await clearAuthData();
    if (_prefs == null) await init();
    await _prefs!.remove(StorageKeys.instanceUrl);
  }

  /// Check if user is authenticated (has valid token)
  Future<bool> isAuthenticated() async {
    final token = await getAccessToken();
    debugPrint('StorageService: Access token exists = ${token != null}');
    if (token == null) return false;

    final expired = await isTokenExpired();
    debugPrint('StorageService: Token expired = $expired');
    return !expired;
  }
}
