import 'dart:async';

import '../utils/constants.dart';
import '../utils/logger.dart';
import '../utils/normalizer.dart';
import 'cache_manager.dart';
import 'html_downloader.dart';
import 'queue.dart';
import 'rate_limiter.dart';
import 'robots_checker.dart';

/// Result of fetching a single page.
class CrawlerResult {
  final String url;
  final String? content;
  final String? error;

  /// Whether the content came from the local cache instead of the network.
  final bool fromCache;

  const CrawlerResult({
    required this.url,
    this.content,
    this.error,
    this.fromCache = false,
  });

  bool get isSuccess => content != null;
}

/// Summary statistics for one crawl run.
class CrawlStats {
  int downloaded = 0;
  int cached = 0;
  int failed = 0;
  int skippedByRobots = 0;

  int get processed => downloaded + cached + failed + skippedByRobots;

  @override
  String toString() => 'downloaded=$downloaded cached=$cached failed=$failed '
      'robotsSkipped=$skippedByRobots';
}

/// Callback invoked for each fetched page. Returned URLs are enqueued for
/// crawling, which is how listing pages feed detail pages into the queue.
typedef PageHandler = FutureOr<List<String>> Function(CrawlerResult result);

/// Production crawler combining a persistent resumable queue, an on-disk
/// cache, robots.txt compliance, token-bucket rate limiting, retrying
/// downloads and a pool of concurrent workers.
///
/// Downloading is I/O-bound, so parallelism uses async workers on the event
/// loop rather than isolates; CPU-heavy extraction is offloaded to isolates
/// by the crawler entrypoints instead (see `bin/`).
class Crawler {
  final HtmlDownloader downloader;
  final CacheManager cache;
  final CrawlerQueue queue;
  final RateLimiter rateLimiter;
  final RobotsChecker? robotsChecker;
  final SimpleLogger logger;

  /// Number of concurrent download workers.
  final int concurrency;

  /// Safety limit on pages processed per run; `null` means unlimited.
  final int? maxPages;

  final Set<String> _seenThisRun = {};

  Crawler({
    required this.downloader,
    required this.cache,
    required this.queue,
    required this.rateLimiter,
    this.robotsChecker,
    this.logger = const SimpleLogger(name: 'crawler'),
    this.concurrency = kDefaultConcurrency,
    this.maxPages,
  });

  /// Queues [url] after normalization, dropping duplicates.
  void queueUrl(String url) {
    final normalized = Normalizer.normalizeUrl(url);
    if (normalized.isEmpty || _seenThisRun.contains(normalized)) return;
    _seenThisRun.add(normalized);
    queue.add(normalized);
  }

  /// Crawls until the queue is exhausted (or [maxPages] is reached), invoking
  /// [onPage] for every page and enqueueing any URLs it returns.
  Future<CrawlStats> crawl({required PageHandler onPage}) async {
    final stats = CrawlStats();
    var inFlight = 0;
    var stopped = false;

    Future<void> worker() async {
      while (!stopped) {
        final url = queue.next();
        if (url == null) {
          // Queue drained; if peers are still downloading they may discover
          // new links, so wait briefly before checking again.
          if (inFlight == 0) return;
          await Future<void>.delayed(const Duration(milliseconds: 50));
          continue;
        }

        if (maxPages != null && stats.processed >= maxPages!) {
          // Return the URL so a future run can resume with it.
          queue.add(url);
          stopped = true;
          return;
        }

        inFlight++;
        try {
          await _processUrl(url, onPage, stats);
        } finally {
          inFlight--;
        }

        if (stats.processed % kProgressInterval == 0) {
          logger.info(
            'Progress: ${stats.processed} pages ($stats), '
            '${queue.pendingCount} pending',
          );
        }
      }
    }

    await Future.wait(List.generate(concurrency, (_) => worker()));

    logger.info('Crawl finished: $stats');
    return stats;
  }

  Future<void> _processUrl(
    String url,
    PageHandler onPage,
    CrawlStats stats,
  ) async {
    CrawlerResult result;

    final cachedContent = cache.get(url);
    if (cachedContent != null) {
      stats.cached++;
      result = CrawlerResult(url: url, content: cachedContent, fromCache: true);
    } else {
      final robots = robotsChecker;
      if (robots != null && !await robots.canCrawl(url)) {
        stats.skippedByRobots++;
        queue.complete(url);
        logger.debug('Skipped by robots.txt: $url');
        return;
      }

      await rateLimiter.waitForToken();
      try {
        final content = await downloader.download(url);
        cache.put(url, content);
        stats.downloaded++;
        result = CrawlerResult(url: url, content: content);
      } on Exception catch (e) {
        stats.failed++;
        queue.fail(url);
        logger.error('Download failed [$url]: $e');
        await onPage(CrawlerResult(url: url, error: e.toString()));
        return;
      }
    }

    queue.complete(url);

    final discovered = await onPage(result);
    for (final link in discovered) {
      queueUrl(link);
    }
  }
}
