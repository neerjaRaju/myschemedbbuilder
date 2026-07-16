import 'dart:convert';
import 'dart:io';

/// Declarative crawl configuration for one official source portal, loaded
/// from a JSON file in the top-level `sources/` directory.
class SourceConfig {
  /// Machine name; also used for cache/queue/output file names.
  final String name;

  /// URLs queued at the start of every crawl.
  final List<String> seedUrls;

  /// Sitemap URLs whose `<loc>` entries are used for URL discovery.
  final List<String> sitemapUrls;

  /// Regex a discovered URL must match to be crawled.
  final String urlAllowPattern;

  /// Regex a URL must match to be treated as a scheme detail page and
  /// extracted (listing pages are crawled for links only).
  final String detailUrlPattern;

  /// Fallback state recorded when a page does not declare one.
  final String defaultState;

  /// Fallback ministry recorded when a page does not declare one.
  final String defaultMinistry;

  /// Maximum requests per second against this source.
  final int requestsPerSecond;

  /// Upper bound of pages fetched per run; `null` means unlimited.
  final int? maxPages;

  /// Maps a host substring to the state it belongs to, e.g.
  /// `"rajasthan.gov.in": "Rajasthan"`. Used to resolve the state for
  /// multi-portal sources.
  final Map<String, String> stateByDomain;

  /// Optional API access block for sources exposing an official JSON API
  /// (see `MySchemeApiConfig`); `null` when the source is HTML-only.
  final Map<String, dynamic>? api;

  const SourceConfig({
    required this.name,
    required this.seedUrls,
    this.sitemapUrls = const [],
    this.urlAllowPattern = '.*',
    this.detailUrlPattern = '.*',
    this.defaultState = '',
    this.defaultMinistry = '',
    this.requestsPerSecond = 2,
    this.maxPages,
    this.stateByDomain = const {},
    this.api,
  });

  factory SourceConfig.fromJson(Map<String, dynamic> json) {
    return SourceConfig(
      name: json['name'] as String,
      seedUrls: List<String>.from(json['seed_urls'] as List),
      sitemapUrls: json['sitemap_urls'] is List
          ? List<String>.from(json['sitemap_urls'] as List)
          : const [],
      urlAllowPattern: json['url_allow_pattern'] as String? ?? '.*',
      detailUrlPattern: json['detail_url_pattern'] as String? ?? '.*',
      defaultState: json['default_state'] as String? ?? '',
      defaultMinistry: json['default_ministry'] as String? ?? '',
      requestsPerSecond: json['requests_per_second'] as int? ?? 2,
      maxPages: json['max_pages'] as int?,
      stateByDomain: json['state_by_domain'] is Map
          ? Map<String, String>.from(json['state_by_domain'] as Map)
          : const {},
      api: json['api'] is Map
          ? Map<String, dynamic>.from(json['api'] as Map)
          : null,
    );
  }

  /// Resolves the default state for [url] using [stateByDomain], falling
  /// back to [defaultState].
  String stateForUrl(String url) {
    final host = Uri.tryParse(url)?.host ?? '';
    for (final entry in stateByDomain.entries) {
      if (host.contains(entry.key)) return entry.value;
    }
    return defaultState;
  }

  /// Loads a configuration file such as `sources/myscheme.json`.
  static SourceConfig loadFromFile(String path) {
    final content = File(path).readAsStringSync();
    return SourceConfig.fromJson(json.decode(content) as Map<String, dynamic>);
  }

  RegExp get allowRegExp => RegExp(urlAllowPattern);

  RegExp get detailRegExp => RegExp(detailUrlPattern);
}
