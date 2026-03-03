import 'package:flutter_test/flutter_test.dart';

import 'package:darkfeed/utils/known_instances.dart';

void main() {
  group('PixelfedInstance', () {
    test('creates instance with required fields', () {
      const instance = PixelfedInstance(
        url: 'pixelfed.social',
        name: 'Pixelfed Social',
        description: 'Test description',
      );

      expect(instance.url, 'pixelfed.social');
      expect(instance.name, 'Pixelfed Social');
      expect(instance.description, 'Test description');
    });
  });

  group('knownInstances', () {
    test('contains popular instances', () {
      expect(knownInstances, isNotEmpty);
      expect(knownInstances.length, greaterThanOrEqualTo(5));
    });

    test('includes pixelfed.social', () {
      final pixelfedSocial = knownInstances.firstWhere(
        (instance) => instance.url == 'pixelfed.social',
      );

      expect(pixelfedSocial, isNotNull);
      expect(pixelfedSocial.name, isNotEmpty);
      expect(pixelfedSocial.description, isNotEmpty);
    });

    test('all instances have required fields', () {
      for (final instance in knownInstances) {
        expect(instance.url, isNotEmpty);
        expect(instance.name, isNotEmpty);
        expect(instance.description, isNotEmpty);
      }
    });

    test('instance URLs do not include protocol', () {
      for (final instance in knownInstances) {
        expect(instance.url, isNot(startsWith('http://')));
        expect(instance.url, isNot(startsWith('https://')));
      }
    });
  });

  group('normalizeInstanceUrl', () {
    test('trims whitespace', () {
      expect(normalizeInstanceUrl('  pixelfed.social  '), 'pixelfed.social');
    });

    test('converts to lowercase', () {
      expect(normalizeInstanceUrl('PIXELFED.SOCIAL'), 'pixelfed.social');
      expect(normalizeInstanceUrl('PixelFed.Social'), 'pixelfed.social');
    });

    test('removes http:// prefix', () {
      expect(normalizeInstanceUrl('http://pixelfed.social'), 'pixelfed.social');
    });

    test('removes https:// prefix', () {
      expect(
        normalizeInstanceUrl('https://pixelfed.social'),
        'pixelfed.social',
      );
    });

    test('removes trailing slash', () {
      expect(normalizeInstanceUrl('pixelfed.social/'), 'pixelfed.social');
      expect(
        normalizeInstanceUrl('https://pixelfed.social/'),
        'pixelfed.social',
      );
    });

    test('removes www. prefix', () {
      expect(normalizeInstanceUrl('www.pixelfed.social'), 'pixelfed.social');
      expect(
        normalizeInstanceUrl('https://www.pixelfed.social'),
        'pixelfed.social',
      );
    });

    test('handles complex URLs', () {
      expect(
        normalizeInstanceUrl('  HTTPS://WWW.PIXELFED.SOCIAL/  '),
        'pixelfed.social',
      );
    });

    test('preserves subdomain', () {
      expect(
        normalizeInstanceUrl('sub.pixelfed.social'),
        'sub.pixelfed.social',
      );
    });

    test('handles empty string', () {
      expect(normalizeInstanceUrl(''), '');
    });

    test('handles URL with path', () {
      expect(
        normalizeInstanceUrl('https://pixelfed.social/path'),
        'pixelfed.social/path',
      );
    });
  });

  group('getFullInstanceUrl', () {
    test('adds https:// prefix', () {
      expect(getFullInstanceUrl('pixelfed.social'), 'https://pixelfed.social');
    });

    test('normalizes before adding prefix', () {
      expect(getFullInstanceUrl('PIXELFED.SOCIAL'), 'https://pixelfed.social');
    });

    test('removes existing protocol', () {
      expect(
        getFullInstanceUrl('http://pixelfed.social'),
        'https://pixelfed.social',
      );
      expect(
        getFullInstanceUrl('https://pixelfed.social'),
        'https://pixelfed.social',
      );
    });

    test('removes trailing slash', () {
      expect(getFullInstanceUrl('pixelfed.social/'), 'https://pixelfed.social');
    });

    test('removes www. prefix', () {
      expect(
        getFullInstanceUrl('www.pixelfed.social'),
        'https://pixelfed.social',
      );
    });

    test('handles complex URLs', () {
      expect(
        getFullInstanceUrl('  HTTP://WWW.PIXELFED.SOCIAL/  '),
        'https://pixelfed.social',
      );
    });

    test('preserves subdomain', () {
      expect(
        getFullInstanceUrl('sub.pixelfed.social'),
        'https://sub.pixelfed.social',
      );
    });

    test('handles empty string', () {
      expect(getFullInstanceUrl(''), 'https://');
    });
  });

  group('URL validation edge cases', () {
    test('handles URLs with port numbers', () {
      expect(
        normalizeInstanceUrl('pixelfed.social:8080'),
        'pixelfed.social:8080',
      );
      expect(
        getFullInstanceUrl('pixelfed.social:8080'),
        'https://pixelfed.social:8080',
      );
    });

    test('handles localhost', () {
      expect(normalizeInstanceUrl('localhost:3000'), 'localhost:3000');
      expect(getFullInstanceUrl('localhost:3000'), 'https://localhost:3000');
    });

    test('handles IP addresses', () {
      expect(normalizeInstanceUrl('192.168.1.1'), '192.168.1.1');
      expect(getFullInstanceUrl('192.168.1.1'), 'https://192.168.1.1');
    });

    test('handles multiple slashes', () {
      expect(normalizeInstanceUrl('pixelfed.social//'), 'pixelfed.social/');
    });

    test('handles unicode domains', () {
      expect(normalizeInstanceUrl('пиксельфед.рф'), 'пиксельфед.рф');
    });
  });
}
