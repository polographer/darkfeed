import 'package:flutter/foundation.dart';

import 'package:darkfeed/models/post.dart';
import 'package:darkfeed/services/oauth_service.dart';
import 'package:darkfeed/services/pixelfed_service.dart';

/// Authentication states
enum AuthState { initial, loading, authenticated, unauthenticated, error }

/// Provider for managing authentication state

class AuthProvider with ChangeNotifier {
  final OAuthService _oauthService;
  final PixelfedService _pixelfedService;

  AuthState _state = AuthState.initial;
  UserAccount? _currentUser;
  String? _error;

  AuthProvider(this._oauthService, this._pixelfedService) {
    _checkAuthStatus();
  }

  // Getters

  AuthState get state => _state;
  UserAccount? get currentUser => _currentUser;
  String? get error => _error;
  bool get isAuthenticated => _state == AuthState.authenticated;
  bool get isLoading => _state == AuthState.loading;

  // Methods

  /// Check if user is already authenticated (public)
  Future<void> checkAuthStatus() => _checkAuthStatus();

  /// Check if user is already authenticated (internal)
  Future<void> _checkAuthStatus() async {
    _setState(AuthState.loading);

    try {
      debugPrint('AuthProvider: Checking auth status...');
      final isAuth = await _oauthService.isAuthenticated();
      debugPrint('AuthProvider: isAuthenticated = $isAuth');

      if (isAuth) {
        debugPrint(
          'AuthProvider: User is authenticated, initializing service...',
        );
        // Initialize Pixelfed service and get current user
        await _pixelfedService.initialize();
        debugPrint(
          'AuthProvider: Service initialized, getting current user...',
        );
        _currentUser = await _pixelfedService.getCurrentUser();
        debugPrint(
          'AuthProvider: Current user loaded: ${_currentUser?.username}',
        );
        _setState(AuthState.authenticated);
      } else {
        debugPrint('AuthProvider: User not authenticated');
        _setState(AuthState.unauthenticated);
      }
    } catch (e, stackTrace) {
      _error = 'Failed to check auth status: $e';
      debugPrint('AuthProvider: Error checking auth - $e');
      debugPrint('Stack trace: $stackTrace');
      _setState(AuthState.unauthenticated);
    }
  }

  /// Login with OAuth2
  Future<bool> login(String instanceUrl) async {
    debugPrint('AuthProvider: Starting login for $instanceUrl');
    _setState(AuthState.loading);
    _error = null;

    try {
      // Execute OAuth flow
      debugPrint('AuthProvider: Calling OAuth authenticate...');
      await _oauthService.authenticate(instanceUrl);
      debugPrint('AuthProvider: OAuth authenticate completed successfully');

      // Initialize Pixelfed service
      debugPrint('AuthProvider: Initializing Pixelfed service...');
      await _pixelfedService.initialize();
      debugPrint('AuthProvider: Pixelfed service initialized');

      // Get current user info
      try {
        debugPrint('AuthProvider: Getting current user...');
        _currentUser = await _pixelfedService.getCurrentUser();
        debugPrint('AuthProvider: Got user: ${_currentUser?.username}');
      } catch (userError) {
        // If getting user fails, still consider auth successful
        // User info can be fetched later
        debugPrint(
          'AuthProvider: Warning - Failed to get user info: $userError',
        );
        _currentUser = null;
      }

      debugPrint('AuthProvider: Login successful');
      _setState(AuthState.authenticated);
      return true;
    } catch (e, stackTrace) {
      _error = 'Login failed: $e';
      debugPrint('AuthProvider: Login error: $e');
      debugPrint('AuthProvider: Stack trace: $stackTrace');
      _setState(AuthState.error);
      return false;
    }
  }

  /// Logout user
  Future<void> logout() async {
    _setState(AuthState.loading);

    try {
      await _oauthService.logout();
      _currentUser = null;
      _pixelfedService.dispose();
      _setState(AuthState.unauthenticated);
    } catch (e) {
      _error = 'Logout failed: $e';
      _setState(AuthState.error);
    }
  }

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Set state and notify listeners
  void _setState(AuthState newState) {
    _state = newState;
    notifyListeners();
  }
}
