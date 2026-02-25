import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../utils/constants.dart';

/// Screen for OAuth2 login flow
class LoginScreen extends StatefulWidget {
  final String instanceUrl;

  const LoginScreen({super.key, required this.instanceUrl});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoggingIn = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Automatically start login when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startLogin();
    });
  }

  Future<void> _startLogin() async {
    setState(() {
      _isLoggingIn = true;
      _errorMessage = null;
    });

    final authProvider = context.read<AuthProvider>();

    try {
      final success = await authProvider.login(widget.instanceUrl);

      // Add a delay to let the OAuth webview close properly
      await Future.delayed(const Duration(milliseconds: 500));

      if (success && mounted) {
        // Login successful - pop back to main app
        Navigator.pop(context);
      } else if (mounted) {
        setState(() {
          _isLoggingIn = false;
          _errorMessage = authProvider.error ?? 'Login failed';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoggingIn = false;
          _errorMessage = 'Login failed: $e';
        });
      }
    }
  }

  void _retryLogin() {
    _startLogin();
  }

  void _cancel() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        leading: _isLoggingIn
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _cancel,
              ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Instance info
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.cloud,
                          size: 48,
                          color: AppColors.primaryColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Connecting to',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.secondaryText),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.instanceUrl,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 48),

                // Loading or error state
                if (_isLoggingIn) ...[
                  const CircularProgressIndicator(
                    color: AppColors.primaryColor,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Authenticating...',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    Platform.isLinux
                        ? 'Please complete the login in your browser.\n\nNote: On Linux, you may need to restart the app after authentication due to a known issue.'
                        : 'Please complete the login in your browser',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.secondaryText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ] else if (_errorMessage != null) ...[
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.errorColor,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Login Failed',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.errorColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.secondaryText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _retryLogin,
                    icon: const Icon(Icons.refresh),
                    label: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      child: Text('Retry', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(onPressed: _cancel, child: const Text('Cancel')),
                ],

                const Spacer(),

                // Help text
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'You will be redirected to your instance to authorize DarkFeed',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.secondaryText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
