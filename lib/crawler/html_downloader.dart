import '../utils/constants.dart';
import '../utils/downloader.dart';
import 'retry.dart';

/// Downloads HTML pages with browser-like `Accept` headers.
///
/// Delegates transport, timeout and retry behavior to [Downloader].
class HtmlDownloader {
  final Downloader _downloader;

  HtmlDownloader({
    String userAgent = kUserAgent,
    Duration timeout = kHttpTimeout,
    RetryOptions retryOptions = const RetryOptions(),
    Downloader? downloader,
  }) : _downloader = downloader ??
            Downloader(
              userAgent: userAgent,
              timeout: timeout,
              retryOptions: retryOptions,
            );

  /// Downloads raw HTML from [url] with built-in timeouts and backoff retries.
  Future<String> download(String url) {
    return _downloader.fetchString(
      url,
      extraHeaders: {
        'Accept':
            'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      },
    );
  }

  /// Releases the underlying HTTP client.
  void close() => _downloader.close();
}
