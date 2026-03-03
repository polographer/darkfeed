import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_test/flutter_test.dart';

import 'package:darkfeed/utils/platform_utils.dart' as platform_utils;

void main() {
  group('Platform Detection', () {
    group('isWeb', () {
      test('returns kIsWeb value', () {
        expect(platform_utils.isWeb, equals(kIsWeb));
      });

      test('is consistent with kIsWeb', () {
        if (kIsWeb) {
          expect(platform_utils.isWeb, isTrue);
        } else {
          expect(platform_utils.isWeb, isFalse);
        }
      });
    });

    group('Platform-specific getters', () {
      test('isAndroid matches Platform.isAndroid when not web', () {
        if (!kIsWeb) {
          expect(platform_utils.isAndroid, equals(Platform.isAndroid));
        } else {
          expect(platform_utils.isAndroid, isFalse);
        }
      });

      test('isIOS matches Platform.isIOS when not web', () {
        if (!kIsWeb) {
          expect(platform_utils.isIOS, equals(Platform.isIOS));
        } else {
          expect(platform_utils.isIOS, isFalse);
        }
      });

      test('isLinux matches Platform.isLinux when not web', () {
        if (!kIsWeb) {
          expect(platform_utils.isLinux, equals(Platform.isLinux));
        } else {
          expect(platform_utils.isLinux, isFalse);
        }
      });

      test('isMacOS matches Platform.isMacOS when not web', () {
        if (!kIsWeb) {
          expect(platform_utils.isMacOS, equals(Platform.isMacOS));
        } else {
          expect(platform_utils.isMacOS, isFalse);
        }
      });

      test('isWindows matches Platform.isWindows when not web', () {
        if (!kIsWeb) {
          expect(platform_utils.isWindows, equals(Platform.isWindows));
        } else {
          expect(platform_utils.isWindows, isFalse);
        }
      });
    });

    group('Platform categories', () {
      test('isDesktop returns true for Linux, macOS, or Windows', () {
        if (!kIsWeb) {
          final expectedDesktop =
              Platform.isLinux || Platform.isMacOS || Platform.isWindows;
          expect(platform_utils.isDesktop, equals(expectedDesktop));
        } else {
          expect(platform_utils.isDesktop, isFalse);
        }
      });

      test('isMobile returns true for Android or iOS', () {
        if (!kIsWeb) {
          final expectedMobile = Platform.isAndroid || Platform.isIOS;
          expect(platform_utils.isMobile, equals(expectedMobile));
        } else {
          expect(platform_utils.isMobile, isFalse);
        }
      });

      test('exactly one of isDesktop, isMobile, or isWeb is true', () {
        final platforms = [
          platform_utils.isDesktop,
          platform_utils.isMobile,
          platform_utils.isWeb,
        ];

        final trueCount = platforms.where((p) => p).length;
        expect(
          trueCount,
          equals(1),
          reason: 'Exactly one platform category should be true',
        );
      });
    });

    group('Platform exclusivity', () {
      test('platform getters are mutually exclusive', () {
        final platforms = [
          platform_utils.isAndroid,
          platform_utils.isIOS,
          platform_utils.isLinux,
          platform_utils.isMacOS,
          platform_utils.isWindows,
          platform_utils.isWeb,
        ];

        final trueCount = platforms.where((p) => p).length;
        expect(
          trueCount,
          lessThanOrEqualTo(1),
          reason: 'At most one platform should be true',
        );
      });

      test('desktop platforms cannot be mobile', () {
        if (platform_utils.isDesktop) {
          expect(platform_utils.isMobile, isFalse);
        }
      });

      test('mobile platforms cannot be desktop', () {
        if (platform_utils.isMobile) {
          expect(platform_utils.isDesktop, isFalse);
        }
      });

      test('web platform excludes all native platforms', () {
        if (platform_utils.isWeb) {
          expect(platform_utils.isAndroid, isFalse);
          expect(platform_utils.isIOS, isFalse);
          expect(platform_utils.isLinux, isFalse);
          expect(platform_utils.isMacOS, isFalse);
          expect(platform_utils.isWindows, isFalse);
          expect(platform_utils.isDesktop, isFalse);
          expect(platform_utils.isMobile, isFalse);
        }
      });
    });

    group('platformName', () {
      test('returns non-empty string', () {
        expect(platform_utils.platformName, isNotEmpty);
      });

      test('returns expected value for current platform', () {
        final name = platform_utils.platformName;

        if (kIsWeb) {
          expect(name, equals('Web'));
        } else if (Platform.isAndroid) {
          expect(name, equals('Android'));
        } else if (Platform.isIOS) {
          expect(name, equals('iOS'));
        } else if (Platform.isLinux) {
          expect(name, equals('Linux'));
        } else if (Platform.isMacOS) {
          expect(name, equals('macOS'));
        } else if (Platform.isWindows) {
          expect(name, equals('Windows'));
        }
      });

      test('matches a known platform name', () {
        final validNames = [
          'Web',
          'Android',
          'iOS',
          'Linux',
          'macOS',
          'Windows',
          'Unknown',
        ];

        expect(
          validNames.contains(platform_utils.platformName),
          isTrue,
          reason:
              'platformName should be one of the known platform names, got: ${platform_utils.platformName}',
        );
      });

      test('platformName consistency with boolean getters', () {
        final name = platform_utils.platformName;

        if (name == 'Web') {
          expect(platform_utils.isWeb, isTrue);
        } else if (name == 'Android') {
          expect(platform_utils.isAndroid, isTrue);
        } else if (name == 'iOS') {
          expect(platform_utils.isIOS, isTrue);
        } else if (name == 'Linux') {
          expect(platform_utils.isLinux, isTrue);
        } else if (name == 'macOS') {
          expect(platform_utils.isMacOS, isTrue);
        } else if (name == 'Windows') {
          expect(platform_utils.isWindows, isTrue);
        }
      });
    });

    group('Cross-platform compatibility', () {
      test('calling all getters does not throw', () {
        expect(() => platform_utils.isWeb, returnsNormally);
        expect(() => platform_utils.isDesktop, returnsNormally);
        expect(() => platform_utils.isMobile, returnsNormally);
        expect(() => platform_utils.isAndroid, returnsNormally);
        expect(() => platform_utils.isIOS, returnsNormally);
        expect(() => platform_utils.isLinux, returnsNormally);
        expect(() => platform_utils.isMacOS, returnsNormally);
        expect(() => platform_utils.isWindows, returnsNormally);
        expect(() => platform_utils.platformName, returnsNormally);
      });

      test('getters return boolean values', () {
        expect(platform_utils.isWeb, isA<bool>());
        expect(platform_utils.isDesktop, isA<bool>());
        expect(platform_utils.isMobile, isA<bool>());
        expect(platform_utils.isAndroid, isA<bool>());
        expect(platform_utils.isIOS, isA<bool>());
        expect(platform_utils.isLinux, isA<bool>());
        expect(platform_utils.isMacOS, isA<bool>());
        expect(platform_utils.isWindows, isA<bool>());
      });

      test('platformName returns String', () {
        expect(platform_utils.platformName, isA<String>());
      });
    });

    group('Current platform verification', () {
      test('current platform is detected correctly', () {
        // This test verifies the current test environment
        // ignore: avoid_print
        print('Running tests on: ${platform_utils.platformName}');
        // ignore: avoid_print
        print('isWeb: ${platform_utils.isWeb}');
        // ignore: avoid_print
        print('isDesktop: ${platform_utils.isDesktop}');
        // ignore: avoid_print
        print('isMobile: ${platform_utils.isMobile}');

        // At least one should be true
        final anyPlatform =
            platform_utils.isWeb ||
            platform_utils.isDesktop ||
            platform_utils.isMobile;
        expect(anyPlatform, isTrue);
      });

      test('platform detection is consistent', () {
        // Call getters multiple times to ensure consistency
        final web1 = platform_utils.isWeb;
        final web2 = platform_utils.isWeb;
        expect(web1, equals(web2));

        final desktop1 = platform_utils.isDesktop;
        final desktop2 = platform_utils.isDesktop;
        expect(desktop1, equals(desktop2));

        final name1 = platform_utils.platformName;
        final name2 = platform_utils.platformName;
        expect(name1, equals(name2));
      });
    });

    group('Logical consistency', () {
      test('if isAndroid is true, then isMobile must be true', () {
        if (platform_utils.isAndroid) {
          expect(platform_utils.isMobile, isTrue);
        }
      });

      test('if isIOS is true, then isMobile must be true', () {
        if (platform_utils.isIOS) {
          expect(platform_utils.isMobile, isTrue);
        }
      });

      test('if isLinux is true, then isDesktop must be true', () {
        if (platform_utils.isLinux) {
          expect(platform_utils.isDesktop, isTrue);
        }
      });

      test('if isMacOS is true, then isDesktop must be true', () {
        if (platform_utils.isMacOS) {
          expect(platform_utils.isDesktop, isTrue);
        }
      });

      test('if isWindows is true, then isDesktop must be true', () {
        if (platform_utils.isWindows) {
          expect(platform_utils.isDesktop, isTrue);
        }
      });

      test('if isDesktop is true, one desktop platform must be true', () {
        if (platform_utils.isDesktop) {
          final anyDesktop =
              platform_utils.isLinux ||
              platform_utils.isMacOS ||
              platform_utils.isWindows;
          expect(anyDesktop, isTrue);
        }
      });

      test('if isMobile is true, one mobile platform must be true', () {
        if (platform_utils.isMobile) {
          final anyMobile = platform_utils.isAndroid || platform_utils.isIOS;
          expect(anyMobile, isTrue);
        }
      });
    });
  });
}
