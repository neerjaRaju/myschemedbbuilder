import 'dart:async';
import 'dart:math';

class RetryOptions {
  final int maxAttempts;
  final Duration delayFactor;
  final double randomizationFactor;
  final Duration maxDelay;

  const RetryOptions({
    this.maxAttempts = 3,
    this.delayFactor = const Duration(milliseconds: 500),
    this.randomizationFactor = 0.25,
    this.maxDelay = const Duration(seconds: 10),
  });

  /// Executes [fn] up to [maxAttempts] times, backing off exponentially on failure.
  Future<T> retry<T>(Future<T> Function() fn, {bool Function(Exception)? retryIf}) async {
    int attempt = 0;
    while (true) {
      attempt++;
      try {
        return await fn();
      } on Exception catch (e) {
        if (attempt >= maxAttempts || (retryIf != null && !retryIf(e))) {
          rethrow;
        }

        // Calculate exponential backoff: delayFactor * 2^(attempt - 1)
        num delayMs = delayFactor.inMilliseconds * pow(2, attempt - 1);
        
        // Add random jitter
        final double jitter = (Random().nextDouble() * 2 - 1) * randomizationFactor * delayMs;
        int targetDelayMs = (delayMs + jitter).round();
        
        // Cap delay
        if (targetDelayMs > maxDelay.inMilliseconds) {
          targetDelayMs = maxDelay.inMilliseconds;
        }

        await Future.delayed(Duration(milliseconds: targetDelayMs));
      }
    }
  }
}