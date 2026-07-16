import 'dart:io';

import 'package:government_scheme_db_builder/crawler/queue.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;
  late String statePath;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('queue_test');
    statePath = '${tempDir.path}/queue.json';
  });

  tearDown(() => tempDir.deleteSync(recursive: true));

  group('CrawlerQueue', () {
    test('add / next / complete lifecycle', () {
      final queue = CrawlerQueue(storagePath: statePath);
      queue.add('https://a.gov.in/1');
      queue.add('https://a.gov.in/2');
      expect(queue.pendingCount, 2);

      final url = queue.next();
      expect(url, isNotNull);
      queue.complete(url!);
      expect(queue.completedCount, 1);
      expect(queue.pendingCount, 1);
    });

    test('ignores duplicates and completed URLs', () {
      final queue = CrawlerQueue(storagePath: statePath);
      queue.add('https://a.gov.in/1');
      queue.add('https://a.gov.in/1');
      expect(queue.pendingCount, 1);

      queue.complete(queue.next()!);
      queue.add('https://a.gov.in/1');
      expect(queue.pendingCount, 0);
    });

    test('addAll enqueues a batch', () {
      final queue = CrawlerQueue(storagePath: statePath);
      queue.addAll(['https://a.gov.in/1', 'https://a.gov.in/2']);
      expect(queue.pendingCount, 2);
    });

    test('persists state across instances (resume)', () {
      final first = CrawlerQueue(storagePath: statePath);
      first.add('https://a.gov.in/1');
      first.add('https://a.gov.in/2');
      first.complete(first.next()!);

      final resumed = CrawlerQueue(storagePath: statePath);
      expect(resumed.pendingCount, 1);
      expect(resumed.completedCount, 1);
    });

    test('failed URLs can be retried on a later run', () {
      final first = CrawlerQueue(storagePath: statePath);
      first.add('https://a.gov.in/1');
      first.fail(first.next()!);

      final resumed = CrawlerQueue(storagePath: statePath);
      resumed.add('https://a.gov.in/1');
      expect(resumed.pendingCount, 1);
    });

    test('recovers from corrupted state file', () {
      File(statePath).writeAsStringSync('{not json');
      final queue = CrawlerQueue(storagePath: statePath);
      expect(queue.pendingCount, 0);
      queue.add('https://a.gov.in/1');
      expect(queue.pendingCount, 1);
    });

    test('clear removes state file', () {
      final queue = CrawlerQueue(storagePath: statePath);
      queue.add('https://a.gov.in/1');
      queue.clear();
      expect(File(statePath).existsSync(), isFalse);
      expect(queue.isEmpty, isTrue);
    });
  });
}
