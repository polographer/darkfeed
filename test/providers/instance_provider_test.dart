import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:darkfeed/providers/instance_provider.dart';
import 'package:darkfeed/utils/known_instances.dart';

import '../helpers/mock_storage_service.mocks.dart';

void main() {
  group('InstanceProvider', () {
    late InstanceProvider instanceProvider;
    late MockStorageService mockStorageService;

    setUp(() {
      mockStorageService = MockStorageService();
      // Setup default behavior to prevent constructor from failing
      when(mockStorageService.getInstanceUrl()).thenAnswer((_) async => null);

      instanceProvider = InstanceProvider(mockStorageService);
    });

    tearDown(() {
      instanceProvider.dispose();
    });

    group('initialization', () {
      test('constructor triggers loadSavedInstance', () async {
        // Wait a bit for async initialization
        await Future<void>.delayed(const Duration(milliseconds: 50));

        verify(
          mockStorageService.getInstanceUrl(),
        ).called(greaterThanOrEqualTo(1));
      });

      test('loads saved instance on initialization', () async {
        const savedInstance = 'https://pixelfed.social';
        when(
          mockStorageService.getInstanceUrl(),
        ).thenAnswer((_) async => savedInstance);

        // Create new provider to trigger initialization
        final provider = InstanceProvider(mockStorageService);

        // Wait for initialization to complete
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(provider.selectedInstance, savedInstance);
        provider.dispose();
      });

      test('handles missing saved instance', () async {
        when(mockStorageService.getInstanceUrl()).thenAnswer((_) async => null);

        final provider = InstanceProvider(mockStorageService);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(provider.selectedInstance, isNull);
        provider.dispose();
      });

      test('handles storage errors during load', () async {
        when(
          mockStorageService.getInstanceUrl(),
        ).thenThrow(Exception('Storage error'));

        final provider = InstanceProvider(mockStorageService);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(provider.selectedInstance, isNull);
        expect(provider.error, contains('Storage error'));
        provider.dispose();
      });
    });

    group('selectInstance', () {
      test('selects and saves instance', () async {
        const instanceUrl = 'pixelfed.social';
        const fullUrl = 'https://pixelfed.social';

        when(
          mockStorageService.saveInstanceUrl(fullUrl),
        ).thenAnswer((_) async => {});

        await instanceProvider.selectInstance(instanceUrl);

        expect(instanceProvider.selectedInstance, fullUrl);
        verify(mockStorageService.saveInstanceUrl(fullUrl)).called(1);
        expect(instanceProvider.error, isNull);
      });

      test('normalizes instance URL before saving', () async {
        const inputUrl = 'PIXELFED.SOCIAL';
        const normalizedUrl = 'https://pixelfed.social';

        when(
          mockStorageService.saveInstanceUrl(normalizedUrl),
        ).thenAnswer((_) async => {});

        await instanceProvider.selectInstance(inputUrl);

        expect(instanceProvider.selectedInstance, normalizedUrl);
        verify(mockStorageService.saveInstanceUrl(normalizedUrl)).called(1);
      });

      test('notifies listeners on instance selection', () async {
        var notificationCount = 0;
        instanceProvider.addListener(() {
          notificationCount++;
        });

        when(
          mockStorageService.saveInstanceUrl(any),
        ).thenAnswer((_) async => {});

        await instanceProvider.selectInstance('pixelfed.social');

        expect(notificationCount, greaterThan(0));
      });

      test('rejects invalid instance URLs', () async {
        await instanceProvider.selectInstance('invalid');

        expect(instanceProvider.selectedInstance, isNull);
        expect(instanceProvider.error, contains('Invalid instance URL'));
      });

      test('rejects empty instance URLs', () async {
        await instanceProvider.selectInstance('');

        expect(instanceProvider.selectedInstance, isNull);
        expect(instanceProvider.error, contains('Invalid instance URL'));
      });

      test('handles save errors gracefully', () async {
        const instanceUrl = 'pixelfed.social';
        when(
          mockStorageService.saveInstanceUrl(any),
        ).thenThrow(Exception('Save failed'));

        await instanceProvider.selectInstance(instanceUrl);

        expect(instanceProvider.selectedInstance, isNull);
        expect(instanceProvider.error, contains('Save failed'));
      });

      test('sets loading state during selection', () async {
        when(mockStorageService.saveInstanceUrl(any)).thenAnswer((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        });

        final selectFuture = instanceProvider.selectInstance('pixelfed.social');
        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(instanceProvider.isLoading, isTrue);

        await selectFuture;
        expect(instanceProvider.isLoading, isFalse);
      });
    });

    group('selectKnownInstance', () {
      test('selects known instance', () async {
        final testInstance = PixelfedInstance(
          name: 'Test Instance',
          url: 'https://test.social',
          description: 'Test',
        );

        when(
          mockStorageService.saveInstanceUrl(any),
        ).thenAnswer((_) async => {});

        await instanceProvider.selectKnownInstance(testInstance);

        expect(instanceProvider.selectedInstance, contains('test.social'));
        verify(mockStorageService.saveInstanceUrl(any)).called(1);
      });
    });

    group('clearInstance', () {
      test('clears selected instance', () async {
        // First select an instance
        when(
          mockStorageService.saveInstanceUrl(any),
        ).thenAnswer((_) async => {});
        await instanceProvider.selectInstance('pixelfed.social');

        await instanceProvider.clearInstance();

        expect(instanceProvider.selectedInstance, isNull);
        verify(mockStorageService.saveInstanceUrl('')).called(1);
      });

      test('notifies listeners on clear', () async {
        var notificationCount = 0;

        // Setup initial instance
        when(
          mockStorageService.saveInstanceUrl(any),
        ).thenAnswer((_) async => {});
        await instanceProvider.selectInstance('pixelfed.social');

        instanceProvider.addListener(() {
          notificationCount++;
        });

        await instanceProvider.clearInstance();

        expect(notificationCount, greaterThan(0));
      });
    });

    group('error handling', () {
      test('clearError clears error message', () async {
        var notificationCount = 0;
        instanceProvider.addListener(() {
          notificationCount++;
        });

        // Trigger an error
        await instanceProvider.selectInstance('invalid');
        expect(instanceProvider.error, isNotNull);

        instanceProvider.clearError();

        expect(instanceProvider.error, isNull);
        expect(notificationCount, greaterThan(0));
      });

      test('successful operation clears previous error', () async {
        // Trigger an error
        await instanceProvider.selectInstance('invalid');
        expect(instanceProvider.error, isNotNull);

        // Successful operation
        when(
          mockStorageService.saveInstanceUrl(any),
        ).thenAnswer((_) async => {});
        await instanceProvider.selectInstance('pixelfed.social');

        expect(instanceProvider.error, isNull);
      });
    });

    group('getters', () {
      test(
        'hasSelectedInstance returns true when instance is selected',
        () async {
          when(
            mockStorageService.saveInstanceUrl(any),
          ).thenAnswer((_) async => {});

          await instanceProvider.selectInstance('pixelfed.social');

          expect(instanceProvider.hasSelectedInstance, isTrue);
        },
      );

      test('hasSelectedInstance returns false when no instance selected', () {
        expect(instanceProvider.hasSelectedInstance, isFalse);
      });

      test('isLoading returns true during operations', () async {
        when(mockStorageService.saveInstanceUrl(any)).thenAnswer((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        });

        final selectFuture = instanceProvider.selectInstance('pixelfed.social');
        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(instanceProvider.isLoading, isTrue);

        await selectFuture;
        expect(instanceProvider.isLoading, isFalse);
      });
    });

    group('notifyListeners', () {
      test('notifies on instance selection', () async {
        var notificationCount = 0;
        instanceProvider.addListener(() {
          notificationCount++;
        });

        when(
          mockStorageService.saveInstanceUrl(any),
        ).thenAnswer((_) async => {});

        await instanceProvider.selectInstance('pixelfed.social');

        // Should notify for loading start and end
        expect(notificationCount, greaterThanOrEqualTo(2));
      });

      test('notifies on instance clear', () async {
        var notificationCount = 0;

        when(
          mockStorageService.saveInstanceUrl(any),
        ).thenAnswer((_) async => {});
        await instanceProvider.selectInstance('pixelfed.social');

        instanceProvider.addListener(() {
          notificationCount++;
        });

        await instanceProvider.clearInstance();

        expect(notificationCount, equals(1));
      });

      test('notifies on error clear', () {
        var notificationCount = 0;

        instanceProvider.addListener(() {
          notificationCount++;
        });

        instanceProvider.clearError();

        expect(notificationCount, equals(1));
      });
    });
  });
}
