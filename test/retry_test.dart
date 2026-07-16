import 'package:government_scheme_db_builder/crawler/retry.dart';
import 'package:test/test.dart';

void main() {
  group('RetryOptions', () {
    test('returns result on first success', () async {
      const options = RetryOptions(maxAttempts: 3);
      var calls = 0;
      final result = await options.retry(() async {
        calls++;
        return 42;
      });
      expect(result, 42);
      expect(calls, 1);
    });

    test('retries until success', () async {
      const options = RetryOptions(
        maxAttempts: 3,
        delayFactor: Duration(milliseconds: 1),
      );
      var calls = 0;
      final result = await options.retry(() async {
        calls++;
        if (calls < 3) throw Exception('transient');
        return 'ok';
      });
      expect(result, 'ok');
      expect(calls, 3);
    });

    test('rethrows after max attempts', () async {
      const options = RetryOptions(
        maxAttempts: 2,
        delayFactor: Duration(milliseconds: 1),
      );
      var calls = 0;
      await expectLater(
        options.retry<void>(() async {
          calls++;
          throw Exception('always');
        }),
        throwsException,
      );
      expect(calls, 2);
    });

    test('does not retry when retryIf rejects the error', () async {
      const options = RetryOptions(
        maxAttempts: 5,
        delayFactor: Duration(milliseconds: 1),
      );
      var calls = 0;
      await expectLater(
        options.retry<void>(
          () async {
            calls++;
            throw const FormatException('permanent');
          },
          retryIf: (e) => e is! FormatException,
        ),
        throwsFormatException,
      );
      expect(calls, 1);
    });
  });
}
