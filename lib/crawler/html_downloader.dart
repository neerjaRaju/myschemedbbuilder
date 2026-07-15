import 'dart:async';
import 'package:http/http.dart' as http;
import 'retry.dart';

class HtmlDownloader {
  final String userAgent;
  final Duration timeout;
  final RetryOptions retryOptions;

  HtmlDownloader({
    this.userAgent =
        'GovSchemeDbBuilder/2.0 (+https://github.com/neerjaRaju/myschemedbbuilder)',
    this.timeout = const Duration(seconds: 15),
    this.retryOptions = const RetryOptions(),
  });

  /// Downloads raw HTML from [url] with built-in timeouts and backoff retries.
  Future<String> download(String url) async {
    final uri = Uri.parse(url);
    final headers = {
      'User-Agent': userAgent,
      'Accept':
          'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    };

    return await retryOptions.retry<String>(
      () async {
        final response = await http.get(uri, headers: headers).timeout(timeout);
        if (response.statusCode == 200) {
          return response.body;
        } else {
          throw http.ClientException(
            'Failed to load page. HTTP Status: ${response.statusCode}',
            uri,
          );
        }
      },
      retryIf: (e) =>
          e is TimeoutException ||
          e is http.ClientException ||
          e is SocketException,
    );
  }
}

// Minimal fallback helper if SocketException is thrown
class SocketException implements Exception {
  final String message;
  SocketException([this.message = 'Network connection failed']);
  @override
  String toString() => 'SocketException: $message';
}
