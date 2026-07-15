import 'dart:async';
import 'dart:isolate';
import 'package:http/http.dart' as http;
import 'cache_manager.dart';
import 'rate_limiter.dart';

class CrawlerJob {
  final String url;
  final Map<String, String> headers;
  final Duration timeout;

  CrawlerJob({required this.url, required this.headers, required this.timeout});
}

class CrawlerResult {
  final String url;
  final String? content;
  final String? error;

  CrawlerResult({required this.url, this.content, this.error});
}

class ProductionCrawler {
  final CacheManager cache;
  final RateLimiter rateLimiter;
  final Set<String> _visitedUrls = {};
  final List<String> _queue = [];

  ProductionCrawler({required this.cache, required this.rateLimiter});

  void queueUrl(String url) {
    if (!_visitedUrls.contains(url) && !_queue.contains(url)) {
      _queue.add(url);
    }
  }

  Future<void> start({
    required Function(CrawlerResult) onPageDownloaded,
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final standardHeaders =
        headers ??
        {
          'User-Agent':
              'GovSchemeDbBuilder/2.0 (+https://github.com/neerjaRaju/myschemedbbuilder)',
        };

    while (_queue.isNotEmpty) {
      final url = _queue.removeAt(0);
      _visitedUrls.add(url);

      if (cache.has(url)) {
        final cachedContent = cache.get(url);
        onPageDownloaded(CrawlerResult(url: url, content: cachedContent));
        continue;
      }

      await rateLimiter.waitForToken();

      // Spawn an isolate to separate heavy network I/O from the data thread
      final receivePort = ReceivePort();
      final job = CrawlerJob(
        url: url,
        headers: standardHeaders,
        timeout: timeout,
      );

      await Isolate.spawn(_downloadWorker, [receivePort.sendPort, job]);

      final CrawlerResult result = await receivePort.first;

      if (result.content != null) {
        cache.put(url, result.content!);
      }

      onPageDownloaded(result);
    }
  }
}

// Top-level function isolated worker
void _downloadWorker(List<dynamic> args) async {
  final SendPort sendPort = args[0];
  final CrawlerJob job = args[1];

  try {
    final response = await http
        .get(Uri.parse(job.url), headers: job.headers)
        .timeout(job.timeout);
    if (response.statusCode == 200) {
      sendPort.send(CrawlerResult(url: job.url, content: response.body));
    } else {
      sendPort.send(
        CrawlerResult(
          url: job.url,
          error: 'HTTP Status ${response.statusCode}',
        ),
      );
    }
  } catch (e) {
    sendPort.send(CrawlerResult(url: job.url, error: e.toString()));
  }
}
