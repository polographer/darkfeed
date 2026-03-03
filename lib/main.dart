import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import 'providers/auth_provider.dart';
import 'providers/instance_provider.dart';
import 'providers/timeline_provider.dart';
import 'screens/instance_selector_screen.dart';
import 'screens/timeline_screen.dart';
import 'services/oauth_service.dart';
import 'services/pixelfed_service.dart';
import 'services/storage_service.dart';
import 'services/window_manager_impl.dart';
import 'services/window_service.dart';
import 'utils/constants.dart';
import 'utils/platform_utils.dart' as platform_utils;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Suppress known Flutter Linux desktop mouse tracker assertion errors
  // This is a workaround for: https://github.com/flutter/flutter/issues/
  FlutterError.onError = (FlutterErrorDetails details) {
    // Check if this is the mouse tracker assertion error
    if (details.exception.toString().contains('mouse_tracker.dart') ||
        details.exception.toString().contains('PointerAddedEvent')) {
      // Log the error but don't crash
      debugPrint('Suppressed mouse tracker error: ${details.exception}');
      return;
    }
    // For other errors, use default handling
    FlutterError.presentError(details);
  };

  // Initialize services
  final storageService = StorageService();
  await storageService.init();

  final oauthService = OAuthService(storageService);
  final pixelfedService = PixelfedService(storageService);

  // Initialize window management for desktop platforms
  if (platform_utils.isDesktop) {
    await windowManager.ensureInitialized();
    final windowService = WindowService(storageService, WindowManagerImpl());
    await windowService.initialize();
  }

  // Set system UI overlay style for immersive experience
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => InstanceProvider(storageService)),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(oauthService, pixelfedService),
        ),
        ChangeNotifierProxyProvider<AuthProvider, TimelineProvider>(
          create: (_) => TimelineProvider(pixelfedService),
          update: (_, auth, previous) =>
              previous ?? TimelineProvider(pixelfedService),
        ),
      ],
      child: const DarkFeedApp(),
    ),
  );
}

class DarkFeedApp extends StatelessWidget {
  const DarkFeedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DarkFeed',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.backgroundColor,
        colorScheme: ColorScheme.dark(
          primary: AppColors.primaryColor,
          surface: AppColors.surfaceColor,
          onPrimary: Colors.white,
          onSurface: Colors.white,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.surfaceColor,
          elevation: 0,
          centerTitle: true,
        ),
        cardTheme: CardThemeData(color: AppColors.surfaceColor, elevation: 0),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surfaceColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: const AppNavigator(),
    );
  }
}

/// Main navigation logic - determines initial screen based on auth state
class AppNavigator extends StatefulWidget {
  const AppNavigator({super.key});

  @override
  State<AppNavigator> createState() => _AppNavigatorState();
}

class _AppNavigatorState extends State<AppNavigator> {
  @override
  void initState() {
    super.initState();
    // Defer auth check until after first build to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthStatus();
    });
  }

  Future<void> _checkAuthStatus() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.checkAuthStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isLoading) {
          // Show loading screen while checking auth
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primaryColor),
            ),
          );
        }

        if (authProvider.isAuthenticated) {
          // User is authenticated - show timeline
          return const TimelineScreen();
        } else {
          // User not authenticated - show instance selector
          return const InstanceSelectorScreen();
        }
      },
    );
  }
}
