import 'dart:isolate';

import '../exporter/json_exporter.dart';
import '../extractor/html_parser.dart';
import '../extractor/scheme_extractor.dart';
import '../models/scheme.dart';
import '../parser/json_parser.dart';
import '../utils/constants.dart';
import '../utils/downloader.dart';
import '../utils/file_utils.dart';
import '../utils/logger.dart';
import '../utils/normalizer.dart';
import 'cache_manager.dart';
import 'crawler.dart';
import 'html_downloader.dart';
import 'queue.dart';
import 'rate_limiter.dart';
import 'robots_checker.dart';
import 'source_config.dart';

/// Runs a complete crawl for one configured source and writes the extracted
/// schemes to `data/generated/<name>_schemes.json`.
///
/// Shared by all crawler entrypoints in `bin/` so URL discovery, resume,
/// extraction and output behavior stay identical across sources.
class CrawlRunner {
  final SourceConfig config;
  final SimpleLogger logger;

  CrawlRunner(this.config)
      : logger = SimpleLogger(name: 'crawl-${config.name}');

  String get _queuePath => '$kCacheDir/${config.name}_queue.json';

  String get outputPath => '$kGeneratedDir/${config.name}_schemes.json';

  /// Executes the crawl and returns the extracted schemes.
  Future<List<Scheme>> run() async {
    FileUtils.ensureDirectoriesExist();

    final cache = CacheManager(
      path: '$kCacheDir/${config.name}',
      cacheDuration: kCacheTtl,
    );
    final queue = CrawlerQueue(storagePath: _queuePath);
    final rateLimiter = RateLimiter(
      maxRequests: config.requestsPerSecond,
      interval: const Duration(seconds: 1),
    );
    final downloader = HtmlDownloader();
    final robotsChecker = RobotsChecker();
    final rawDownloader = Downloader();

    // A non-empty pending set means the previous run was interrupted; merge
    // with the existing output so partially crawled data is not lost.
    final resuming = queue.pendingCount > 0;
    if (resuming) {
      logger.info(
        'Resuming interrupted crawl: ${queue.pendingCount} URLs pending.',
      );
    }

    final crawler = Crawler(
      downloader: downloader,
      cache: cache,
      queue: queue,
      rateLimiter: rateLimiter,
      robotsChecker: robotsChecker,
      logger: logger,
      maxPages: config.maxPages,
    );

    final schemesById = <String, Scheme>{};

    try {
      for (final url in await _discoverSeedUrls(rawDownloader)) {
        crawler.queueUrl(url);
      }

      final stats = await crawler.crawl(
        onPage: (result) async {
          if (!result.isSuccess) return const <String>[];
          return _handlePage(result, schemesById);
        },
      );
      logger.info(
        'Extracted ${schemesById.length} schemes from '
        '${stats.downloaded + stats.cached} pages.',
      );
    } finally {
      rateLimiter.dispose();
      downloader.close();
      robotsChecker.close();
      rawDownloader.close();
    }

    final schemes = _mergeWithPrevious(schemesById, resuming);
    JsonExporter.export(outputPath, schemes);
    logger.info('Wrote ${schemes.length} schemes to $outputPath');

    // The crawl completed; clear resume state so the next run starts fresh
    // (the page cache still makes it incremental).
    queue.clear();

    return schemes;
  }

  /// Seeds from the config plus any URLs discovered through sitemaps.
  Future<List<String>> _discoverSeedUrls(Downloader downloader) async {
    final urls = <String>[...config.seedUrls];

    for (final sitemapUrl in config.sitemapUrls) {
      try {
        final content = await downloader.fetchString(sitemapUrl);
        FileUtils.writeSafeString(
          '$kRawDir/${config.name}_${Uri.parse(sitemapUrl).pathSegments.last}',
          content,
        );
        final locs = parseSitemapLocs(content);
        // Nested sitemap indexes: fetch one extra level.
        for (final loc in locs) {
          if (loc.endsWith('.xml')) {
            try {
              final nested = await downloader.fetchString(loc);
              urls.addAll(parseSitemapLocs(nested));
            } on Exception catch (e) {
              logger.warn('Failed to fetch nested sitemap $loc: $e');
            }
          } else {
            urls.add(loc);
          }
        }
        logger.info('Discovered ${locs.length} URLs from $sitemapUrl');
      } on Exception catch (e) {
        logger.warn('Sitemap fetch failed for $sitemapUrl: $e');
      }
    }

    return urls.where((url) => config.allowRegExp.hasMatch(url)).toList();
  }

  Future<List<String>> _handlePage(
    CrawlerResult result,
    Map<String, Scheme> schemesById,
  ) async {
    final html = result.content!;
    final url = result.url;

    if (config.detailRegExp.hasMatch(url)) {
      // HTML parsing is CPU-bound; run it off the crawl event loop so
      // download workers keep saturating the network.
      final defaultState = config.stateForUrl(url);
      final defaultMinistry = config.defaultMinistry;
      final scheme = await Isolate.run(
        () => SchemeExtractor.extract(
          html: html,
          sourceUrl: url,
          defaultState: defaultState,
          defaultMinistry: defaultMinistry,
        ),
      );
      if (scheme.title.isNotEmpty) {
        schemesById[scheme.id] = scheme;
      } else {
        logger.debug('No extractable scheme content at $url');
      }
    }

    // Discover further crawlable links from every page.
    final parser = HtmlParser(html);
    return parser
        .links(url)
        .where((link) => config.allowRegExp.hasMatch(link))
        .toList();
  }

  List<Scheme> _mergeWithPrevious(
    Map<String, Scheme> schemesById,
    bool resuming,
  ) {
    if (resuming) {
      for (final previous in JsonParser.parseFile(outputPath)) {
        schemesById.putIfAbsent(previous.id, () => previous);
      }
    }
    return schemesById.values.toList();
  }

  /// Extracts `<loc>` entries from sitemap XML.
  static List<String> parseSitemapLocs(String xml) {
    final locPattern = RegExp(r'<loc>\s*([^<\s]+)\s*</loc>');
    return [
      for (final match in locPattern.allMatches(xml))
        Normalizer.normalizeUrl(match.group(1)!),
    ].where((url) => url.isNotEmpty).toList();
  }
}
