import 'dart:convert';

import '../exporter/json_exporter.dart';
import '../extractor/scheme_extractor.dart';
import '../models/scheme.dart';
import '../utils/constants.dart';
import '../utils/downloader.dart';
import '../utils/file_utils.dart';
import '../utils/logger.dart';
import 'cache_manager.dart';
import 'rate_limiter.dart';

/// Configuration for the official MyScheme public API
/// (`api.myscheme.gov.in`), read from the `api` block of
/// `sources/myscheme.json`.
///
/// The API key is the public key embedded in the myscheme.gov.in web
/// application bundle; requests are the same ones the official site makes.
class MySchemeApiConfig {
  final String baseUrl;
  final String apiKey;
  final String searchPath;
  final String detailPath;
  final int pageSize;
  final int requestsPerSecond;

  const MySchemeApiConfig({
    required this.baseUrl,
    required this.apiKey,
    this.searchPath = '/search/v6/schemes',
    this.detailPath = '/schemes/v5/public/schemes',
    this.pageSize = 100,
    this.requestsPerSecond = 4,
  });

  factory MySchemeApiConfig.fromJson(Map<String, dynamic> json) {
    return MySchemeApiConfig(
      baseUrl: json['base_url'] as String,
      apiKey: json['api_key'] as String,
      searchPath: json['search_path'] as String? ?? '/search/v6/schemes',
      detailPath:
          json['detail_path'] as String? ?? '/schemes/v5/public/schemes',
      pageSize: json['page_size'] as int? ?? 100,
      requestsPerSecond: json['requests_per_second'] as int? ?? 4,
    );
  }
}

/// Client for the MyScheme public API with retrying transport and
/// browser-equivalent headers.
class MySchemeApiClient {
  final MySchemeApiConfig config;
  final Downloader _downloader;

  MySchemeApiClient(this.config, {Downloader? downloader})
      : _downloader = downloader ?? Downloader();

  /// Headers matching the requests the official myscheme.gov.in web app
  /// makes to its API (User-Agent included, as the gateway may filter it).
  Map<String, String> get _headers => {
        'Accept': 'application/json, text/plain, */*',
        'Origin': 'https://www.myscheme.gov.in',
        'Referer': 'https://www.myscheme.gov.in/',
        'User-Agent': 'Mozilla/5.0',
        'x-api-key': config.apiKey,
      };

  /// Fetches one page of the scheme search index.
  Future<Object?> fetchSearchPage(int from, int size) async {
    final url = '${config.baseUrl}${config.searchPath}'
        '?lang=en&q=%5B%5D&keyword=&sort=&from=$from&size=$size';
    final body = await _downloader.fetchString(url, extraHeaders: _headers);
    return json.decode(body);
  }

  /// Fetches the raw detail payload for one scheme [slug].
  Future<String> fetchDetailRaw(String slug) {
    final url = '${config.baseUrl}${config.detailPath}?slug=$slug&lang=en';
    return _downloader.fetchString(url, extraHeaders: _headers);
  }

  /// Enumerates every scheme slug by paginating the search index.
  ///
  /// The response is traversed defensively (any `slug` string anywhere in
  /// the payload is collected) so minor API version changes do not break
  /// enumeration.
  Future<List<String>> fetchAllSlugs({int maxPages = 200}) async {
    final slugs = <String>{};
    var from = 0;

    for (var page = 0; page < maxPages; page++) {
      final decoded = await fetchSearchPage(from, config.pageSize);
      final found = collectSlugs(decoded);
      final before = slugs.length;
      slugs.addAll(found);

      final total = findTotal(decoded);
      from += config.pageSize;

      final exhausted = slugs.length == before || found.isEmpty;
      final reachedTotal = total != null && from >= total;
      if (exhausted || reachedTotal) break;
    }

    return slugs.toList()..sort();
  }

  /// Recursively collects every string value stored under a `slug` key.
  static List<String> collectSlugs(Object? node) {
    final result = <String>[];
    void walk(Object? current) {
      if (current is Map) {
        final slug = current['slug'];
        if (slug is String && slug.isNotEmpty) result.add(slug);
        current.values.forEach(walk);
      } else if (current is List) {
        current.forEach(walk);
      }
    }

    walk(node);
    return result;
  }

  /// Finds the reported total number of schemes in a search response.
  static int? findTotal(Object? node) {
    int? result;
    void walk(Object? current) {
      if (result != null) return;
      if (current is Map) {
        final total = current['total'];
        if (total is int) {
          result = total;
          return;
        }
        current.values.forEach(walk);
      } else if (current is List) {
        current.forEach(walk);
      }
    }

    walk(node);
    return result;
  }

  void close() => _downloader.close();
}

/// Crawls MyScheme through its official API and writes
/// `data/generated/myscheme_schemes.json`.
///
/// Detail responses are cached on disk, so repeat runs only download
/// schemes whose cache entries have expired.
class MySchemeApiRunner {
  final MySchemeApiConfig config;
  final String outputPath;
  final SimpleLogger logger;

  MySchemeApiRunner(
    this.config, {
    this.outputPath = '$kGeneratedDir/myscheme_schemes.json',
    this.logger = const SimpleLogger(name: 'myscheme-api'),
  });

  Future<List<Scheme>> run() async {
    FileUtils.ensureDirectoriesExist();

    final cache = CacheManager(
      path: '$kCacheDir/myscheme_api',
      cacheDuration: kCacheTtl,
    );
    final rateLimiter = RateLimiter(
      maxRequests: config.requestsPerSecond,
      interval: const Duration(seconds: 1),
    );
    final client = MySchemeApiClient(config);

    final schemes = <Scheme>[];
    var failed = 0;

    try {
      logger.info('Enumerating schemes from the MyScheme search API...');
      await rateLimiter.waitForToken();
      final slugs = await client.fetchAllSlugs();
      logger.info('Discovered ${slugs.length} scheme slugs.');

      for (var i = 0; i < slugs.length; i++) {
        final slug = slugs[i];
        final cacheKey = '${config.baseUrl}${config.detailPath}?slug=$slug';

        String body;
        final cached = cache.get(cacheKey);
        if (cached != null) {
          body = cached;
        } else {
          await rateLimiter.waitForToken();
          try {
            body = await client.fetchDetailRaw(slug);
            cache.put(cacheKey, body);
          } on Exception catch (e) {
            failed++;
            logger.error('Detail fetch failed for "$slug": $e');
            continue;
          }
        }

        try {
          final scheme = SchemeExtractor.fromApiJson(
            json.decode(body),
            slug: slug,
            defaultState: 'Central',
            defaultMinistry: '',
          );
          if (scheme != null) {
            schemes.add(scheme);
          } else {
            logger.warn('No extractable scheme in API payload for "$slug".');
          }
        } on FormatException catch (e) {
          failed++;
          logger.error('Invalid JSON for "$slug": $e');
        }

        if ((i + 1) % kProgressInterval == 0) {
          logger.info(
            'Progress: ${i + 1}/${slugs.length} '
            '(${schemes.length} extracted, $failed failed)',
          );
        }
      }
    } finally {
      rateLimiter.dispose();
      client.close();
    }

    JsonExporter.export(outputPath, schemes);
    logger.info(
      'Wrote ${schemes.length} schemes to $outputPath ($failed failures).',
    );
    return schemes;
  }
}
