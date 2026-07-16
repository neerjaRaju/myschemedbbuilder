import 'package:government_scheme_db_builder/crawler/rate_limiter.dart';
import 'package:test/test.dart';

void main() {
  group('RateLimiter', () {
    test('grants tokens immediately when under the limit', () async {
      final limiter = RateLimiter(
        maxRequests: 2,
        interval: const Duration(seconds: 1),
      );
      final stopwatch = Stopwatch()..start();
      await limiter.waitForToken();
      await limiter.waitForToken();
      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, lessThan(500));
      limiter.dispose();
    });

    test('delays requests beyond the limit until refill', () async {
      final limiter = RateLimiter(
        maxRequests: 1,
        interval: const Duration(milliseconds: 100),
      );
      await limiter.waitForToken();
      final stopwatch = Stopwatch()..start();
      await limiter.waitForToken();
      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(50));
      limiter.dispose();
    });
  });
}
