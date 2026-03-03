import 'package:flutter/material.dart';

/// App-wide constants for DarkFeed

// App Information
const String appName = 'DarkFeed';
const String appVersion = '1.0.0';

// OAuth Configuration
const String oauthRedirectUri = 'com.darkfeed://oauth';
const String oauthCustomScheme = 'com.darkfeed';

// API Scopes
const List<String> oauthScopes = ['read', 'write'];

// Color Palette - Dark Gray Theme
class AppColors {
  // Primary background: Dark gray
  static const Color backgroundColor = Color(0xFF1C1C1E);

  // Surface color for cards/overlays
  static const Color surfaceColor = Color(0xFF2C2C2E);

  // Elevated surface (slightly lighter)
  static const Color elevatedColor = Color(0xFF3C3C3E);

  // Primary accent color
  static const Color primaryColor = Color(0xFF0A84FF);

  // Secondary accent color
  static const Color secondaryColor = Color(0xFF5E5CE6);

  // Text colors
  static const Color onBackground = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFFFFFFFF);
  static const Color secondaryText = Color(0xFFAAAAAA);

  // Error color
  static const Color errorColor = Color(0xFFFF453A);

  // Like/heart color
  static const Color likeColor = Color(0xFFFF453A);

  // Success color
  static const Color successColor = Color(0xFF30D158);
}

// Storage Keys
class StorageKeys {
  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
  static const String tokenExpiry = 'token_expiry';
  static const String instanceUrl = 'instance_url';
  static const String userId = 'user_id';
  static const String username = 'username';

  // Window state keys (desktop only)
  static const String windowWidth = 'window_width';
  static const String windowHeight = 'window_height';
  static const String windowMaximized = 'window_maximized';
}

// Pagination
const int timelinePageSize = 20;
const int maxPostsInMemory = 50;

// Image Loading
const int imageCacheMaxAge = 7; // days
const int imageMemCacheSize = 100; // images

// Timeouts
const Duration apiTimeout = Duration(seconds: 30);
const Duration connectionTimeout = Duration(seconds: 10);
