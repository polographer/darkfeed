/// List of popular Pixelfed instances
library;

class PixelfedInstance {
  final String url;
  final String name;
  final String description;

  const PixelfedInstance({
    required this.url,
    required this.name,
    required this.description,
  });
}

/// Popular Pixelfed instances for quick selection
const List<PixelfedInstance> knownInstances = [
  PixelfedInstance(
    url: 'pixelfed.social',
    name: 'Pixelfed.social',
    description: 'The flagship Pixelfed instance',
  ),
  PixelfedInstance(
    url: 'pixey.org',
    name: 'Pixey',
    description: 'A friendly Pixelfed community',
  ),
  PixelfedInstance(
    url: 'pxlmo.com',
    name: 'Pxlmo',
    description: 'Pixelfed instance for everyone',
  ),
  PixelfedInstance(
    url: 'pixelfed.de',
    name: 'Pixelfed.de',
    description: 'German Pixelfed instance',
  ),
  PixelfedInstance(
    url: 'pixelfed.uno',
    name: 'Pixelfed.uno',
    description: 'International Pixelfed community',
  ),
];

/// Validate instance URL format
String normalizeInstanceUrl(String url) {
  String normalized = url.trim().toLowerCase();

  // Remove http:// or https:// if present
  normalized = normalized.replaceAll(RegExp(r'^https?://'), '');

  // Remove trailing slash
  normalized = normalized.replaceAll(RegExp(r'/$'), '');

  // Remove www. prefix if present
  normalized = normalized.replaceAll(RegExp(r'^www\.'), '');

  return normalized;
}

/// Get full URL with https://
String getFullInstanceUrl(String url) {
  final normalized = normalizeInstanceUrl(url);
  return 'https://$normalized';
}
