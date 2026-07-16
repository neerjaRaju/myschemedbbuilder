import 'dart:io';

import 'package:government_scheme_db_builder/crawler/cache_manager.dart';
import 'package:government_scheme_db_builder/crawler/crawler.dart';
import 'package:government_scheme_db_builder/crawler/html_downloader.dart';
import 'package:government_scheme_db_builder/crawler/queue.dart';
import 'package:government_scheme_db_builder/crawler/rate_limiter.dart';
import 'package:test/test.dart';

/// Serves canned pages without touching the network.
class FakeDownloader extends HtmlDownloader {
  final Map<String, String> pages;
  final List<String> requested = [];

  FakeDownloader(this.pages);

  @override
  Future<String> download(String url) async {
    requested.add(url);
    final page = pages[url];
    if (page == null) {
      throw Exception('HTTP 404 for $url');
    }
    return page;
  }
}

void main() {
  late Directory tempDir;
  late CacheManager cache;
  late CrawlerQueue queue;
  late RateLimiter rateLimiter;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('crawler_test');
    cache = CacheManager(path: '${tempDir.path}/cache');
    queue = CrawlerQueue(storagePath: '${tempDir.path}/queue.json');
    rateLimiter = RateLimiter(
      maxRequests: 100,
      interval: const Duration(seconds: 1),
    );
  });

  tearDown(() {
    rateLimiter.dispose();
    tempDir.deleteSync(recursive: true);
  });

  Crawler makeCrawler(FakeDownloader downloader, {int? maxPages}) {
    return Crawler(
      downloader: downloader,
      cache: cache,
      queue: queue,
      rateLimiter: rateLimiter,
      concurrency: 2,
      maxPages: maxPages,
    );
  }

  test('crawls seeds and follows discovered links', () async {
    final downloader = FakeDownloader({
      'https://a.gov.in/list': '<html>listing</html>',
      'https://a.gov.in/detail-1': '<html>one</html>',
      'https://a.gov.in/detail-2': '<html>two</html>',
    });
    final crawler = makeCrawler(downloader);
    crawler.queueUrl('https://a.gov.in/list');

    final visited = <String>[];
    final stats = await crawler.crawl(
      onPage: (result) {
        visited.add(result.url);
        if (result.url.endsWith('/list')) {
          return ['https://a.gov.in/detail-1', 'https://a.gov.in/detail-2'];
        }
        return const <String>[];
      },
    );

    expect(stats.downloaded, 3);
    expect(visited, hasLength(3));
    expect(queue.completedCount, 3);
  });

  test('duplicate URLs are fetched only once', () async {
    final downloader = FakeDownloader({
      'https://a.gov.in/x': '<html>x</html>',
    });
    final crawler = makeCrawler(downloader);
    crawler.queueUrl('https://a.gov.in/x');
    crawler.queueUrl('https://a.gov.in/x/');
    crawler.queueUrl('https://a.gov.in/x#frag');

    final stats = await crawler.crawl(onPage: (_) => const <String>[]);
    expect(stats.downloaded, 1);
    expect(downloader.requested, hasLength(1));
  });

  test('serves cached pages without re-downloading', () async {
    cache.put('https://a.gov.in/x', '<html>cached</html>');
    final downloader = FakeDownloader({});
    final crawler = makeCrawler(downloader);
    crawler.queueUrl('https://a.gov.in/x');

    CrawlerResult? seen;
    final stats = await crawler.crawl(
      onPage: (result) {
        seen = result;
        return const <String>[];
      },
    );

    expect(stats.cached, 1);
    expect(stats.downloaded, 0);
    expect(seen!.fromCache, isTrue);
    expect(downloader.requested, isEmpty);
  });

  test('failed downloads are reported and left retryable', () async {
    final downloader = FakeDownloader({});
    final crawler = makeCrawler(downloader);
    crawler.queueUrl('https://a.gov.in/missing');

    final errors = <String>[];
    final stats = await crawler.crawl(
      onPage: (result) {
        if (result.error != null) errors.add(result.error!);
        return const <String>[];
      },
    );

    expect(stats.failed, 1);
    expect(errors, hasLength(1));
    expect(queue.completedCount, 0);
  });

  test('maxPages caps the crawl and preserves the queue', () async {
    final downloader = FakeDownloader({
      for (var i = 0; i < 10; i++)
        'https://a.gov.in/page-$i': '<html>$i</html>',
    });
    final crawler = makeCrawler(downloader, maxPages: 3);
    for (var i = 0; i < 10; i++) {
      crawler.queueUrl('https://a.gov.in/page-$i');
    }

    final stats = await crawler.crawl(onPage: (_) => const <String>[]);
    expect(stats.processed, lessThanOrEqualTo(4));
    expect(queue.pendingCount, greaterThan(0));
  });
}
