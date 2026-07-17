import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../crawler/retry.dart';
import 'constants.dart';
import 'file_utils.dart';

/// Error thrown for non-success HTTP responses.
///
/// Carries the status code so callers can decide whether a retry makes
/// sense (5xx / 429) or the failure is permanent (4xx).
class HttpStatusException implements Exception {
  final int statusCode;
  final Uri uri;

  HttpStatusException(this.statusCode, this.uri);

  /// Whether retrying the request may succeed.
  bool get isTransient => statusCode == 429 || statusCode >= 500;

  @override
  String toString() => 'HttpStatusException: HTTP $statusCode for $uri';
}

/// Low-level HTTP downloader with timeout and exponential-backoff retries.
///
/// The MyScheme API client builds on top of this class so retry and
/// timeout behavior is defined in exactly one place.
class Downloader {
  final String userAgent;
  final Duration timeout;
  final RetryOptions retryOptions;
  final http.Client _client;

  Downloader({
    this.userAgent = kUserAgent,
    this.timeout = kHttpTimeout,
    this.retryOptions = const RetryOptions(),
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// Fetches [url] and returns the response body as a string.
  ///
  /// Retries transient failures (timeouts, connection errors, HTTP 429/5xx)
  /// with exponential backoff; permanent HTTP errors are thrown immediately.
  Future<String> fetchString(
    String url, {
    Map<String, String>? extraHeaders,
  }) async {
    final uri = Uri.parse(url);
    final headers = {'User-Agent': userAgent, ...?extraHeaders};

    return retryOptions.retry<String>(() async {
      final response =
          await _client.get(uri, headers: headers).timeout(timeout);
      if (response.statusCode == 200) {
        return response.body;
      }
      throw HttpStatusException(response.statusCode, uri);
    }, retryIf: isTransientError);
  }

  /// Downloads [url] into [filePath], creating parent directories as needed.
  Future<void> downloadToFile(String url, String filePath) async {
    final content = await fetchString(url);
    FileUtils.writeSafeString(filePath, content);
  }

  /// Releases the underlying HTTP client.
  void close() => _client.close();

  /// Whether [error] is worth retrying.
  static bool isTransientError(Exception error) {
    if (error is TimeoutException) return true;
    if (error is SocketException) return true;
    if (error is HttpException) return true;
    if (error is http.ClientException) return true;
    if (error is HttpStatusException) return error.isTransient;
    return false;
  }
}
