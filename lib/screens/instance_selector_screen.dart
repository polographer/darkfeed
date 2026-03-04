import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/instance_provider.dart';
import '../utils/constants.dart';
import '../utils/known_instances.dart';
import 'login_screen.dart';

/// Screen for selecting a Pixelfed instance
class InstanceSelectorScreen extends StatefulWidget {
  const InstanceSelectorScreen({super.key});

  @override
  State<InstanceSelectorScreen> createState() => _InstanceSelectorScreenState();
}

class _InstanceSelectorScreenState extends State<InstanceSelectorScreen> {
  final TextEditingController _instanceController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _instanceController.dispose();
    super.dispose();
  }

  Future<void> _selectInstance(String instanceUrl) async {
    setState(() {
      _errorMessage = null;
    });

    // Validate instance URL (basic check)
    final normalized = instanceUrl.trim();
    if (normalized.isEmpty || !normalized.contains('.')) {
      setState(() {
        _errorMessage = 'Please enter a valid instance URL';
      });
      return;
    }

    final instanceProvider = context.read<InstanceProvider>();
    final authProvider = context.read<AuthProvider>();

    // Set the instance
    await instanceProvider.selectInstance(instanceUrl);

    // Navigate to login screen
    if (mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LoginScreen(instanceUrl: instanceUrl),
        ),
      );

      // Check if user logged in successfully
      if (authProvider.isAuthenticated && mounted) {
        Navigator.pop(context); // Go back to main app (will show timeline)
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Instance')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 32),
                  // App title/logo
                  Text(
                    appName,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'A Pixelfed client',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.secondaryText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // Custom instance input
                  TextField(
                    controller: _instanceController,
                    decoration: InputDecoration(
                      labelText: 'Instance URL',
                      hintText: 'pixelfed.social',
                      prefixIcon: const Icon(Icons.language),
                      errorText: _errorMessage,
                    ),
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.go,
                    onSubmitted: (value) {
                      if (value.isNotEmpty) {
                        _selectInstance(value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Connect button
                  ElevatedButton(
                    onPressed: () {
                      final instance = _instanceController.text.trim();
                      if (instance.isNotEmpty) {
                        _selectInstance(instance);
                      }
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Text('Connect', style: TextStyle(fontSize: 16)),
                    ),
                  ),

                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Popular instances list
                  Text(
                    'Popular Instances',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Instance list
                  Expanded(
                    child: ListView.builder(
                      itemCount: knownInstances.length,
                      itemBuilder: (context, index) {
                        final instance = knownInstances[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primaryColor,
                              child: Text(
                                instance.name[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              instance.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              instance.url,
                              style: TextStyle(color: AppColors.secondaryText),
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                            ),
                            onTap: () => _selectInstance(instance.url),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
