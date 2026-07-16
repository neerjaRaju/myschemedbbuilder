import 'dart:io';

import 'package:government_scheme_db_builder/crawler/cache_manager.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('cache_test');
  });

  tearDown(() => tempDir.deleteSync(recursive: true));

  group('CacheManager', () {
    test('stores and retrieves content by URL', () {
      final cache = CacheManager(path: '${tempDir.path}/cache');
      cache.put('https://a.gov.in/x', '<html>content</html>');

      expect(cache.has('https://a.gov.in/x'), isTrue);
      expect(cache.get('https://a.gov.in/x'), '<html>content</html>');
    });

    test('misses for unknown URLs', () {
      final cache = CacheManager(path: '${tempDir.path}/cache');
      expect(cache.has('https://a.gov.in/missing'), isFalse);
      expect(cache.get('https://a.gov.in/missing'), isNull);
    });

    test('expires entries older than the TTL', () async {
      final cache = CacheManager(
        path: '${tempDir.path}/cache',
        cacheDuration: const Duration(milliseconds: 20),
      );
      cache.put('https://a.gov.in/x', 'data');
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(cache.has('https://a.gov.in/x'), isFalse);
    });

    test('clear empties the cache directory', () {
      final cache = CacheManager(path: '${tempDir.path}/cache');
      cache.put('https://a.gov.in/x', 'data');
      cache.clear();
      expect(cache.has('https://a.gov.in/x'), isFalse);
    });
  });
}
