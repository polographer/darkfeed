import 'package:flutter/foundation.dart';

import 'package:darkfeed/services/storage_service.dart';
import 'package:darkfeed/utils/known_instances.dart';

/// Provider for managing instance selection state

class InstanceProvider with ChangeNotifier {
  final StorageService _storageService;

  String? _selectedInstance;
  bool _isLoading = false;
  String? _error;

  InstanceProvider(this._storageService) {
    _loadSavedInstance();
  }

  // Getters

  String? get selectedInstance => _selectedInstance;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasSelectedInstance => _selectedInstance != null;

  // Methods

  /// Load previously saved instance from storage
  Future<void> _loadSavedInstance() async {
    _isLoading = true;
    notifyListeners();

    try {
      _selectedInstance = await _storageService.getInstanceUrl();
      _error = null;
    } catch (e) {
      _error = 'Failed to load saved instance: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Select an instance
  Future<void> selectInstance(String instanceUrl) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Get full URL with https://
      final fullUrl = getFullInstanceUrl(instanceUrl);

      // Validate URL format (basic check)
      if (fullUrl.isEmpty || !fullUrl.contains('.')) {
        throw Exception('Invalid instance URL');
      }

      // TODO: Optionally validate instance is reachable
      // For now, just save it
      _selectedInstance = fullUrl;
      await _storageService.saveInstanceUrl(fullUrl);
      _error = null;
    } catch (e) {
      _error = 'Failed to select instance: $e';
      _selectedInstance = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Select instance from known instances list
  Future<void> selectKnownInstance(PixelfedInstance instance) async {
    await selectInstance(instance.url);
  }

  /// Clear selected instance
  Future<void> clearInstance() async {
    _selectedInstance = null;
    await _storageService.saveInstanceUrl('');
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
