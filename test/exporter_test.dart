import 'dart:io';

import 'package:government_scheme_db_builder/exporter/json_exporter.dart';
import 'package:government_scheme_db_builder/exporter/sqlite_exporter.dart';
import 'package:government_scheme_db_builder/parser/json_parser.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('exporter_test');
  });

  tearDown(() => tempDir.deleteSync(recursive: true));

  group('JsonExporter + JsonParser', () {
    test('round trip preserves schemes', () {
      final path = '${tempDir.path}/schemes.json';
      final schemes = [
        makeScheme(id: 'b', officialUrl: 'https://b.gov.in/2'),
        makeScheme(id: 'a', officialUrl: 'https://a.gov.in/1'),
      ];

      JsonExporter.export(path, schemes);
      final restored = JsonParser.parseFile(path);

      expect(restored, hasLength(2));
      // Deterministic: sorted by id.
      expect(restored.first.id, 'a');
      expect(restored.last.id, 'b');
    });

    test('export is byte-identical across runs (deterministic)', () {
      final pathA = '${tempDir.path}/a.json';
      final pathB = '${tempDir.path}/b.json';
      final schemes = [
        makeScheme(id: 'x', officialUrl: 'https://x.gov.in/1'),
        makeScheme(id: 'y', officialUrl: 'https://y.gov.in/2'),
      ];

      JsonExporter.export(pathA, schemes);
      JsonExporter.export(pathB, schemes.reversed.toList());

      expect(
        File(pathA).readAsStringSync(),
        File(pathB).readAsStringSync(),
      );
    });

    test('parseFile tolerates missing and malformed files', () {
      expect(JsonParser.parseFile('${tempDir.path}/missing.json'), isEmpty);

      final bad = '${tempDir.path}/bad.json';
      File(bad).writeAsStringSync('{not valid json}');
      expect(JsonParser.parseFile(bad), isEmpty);
    });
  });

  group('SqliteExporter', () {
    test('creates a queryable database file', () {
      final dbPath = '${tempDir.path}/schemes.db';
      SqliteExporter(dbPath).export([
        makeScheme(id: 'a', officialUrl: 'https://a.gov.in/1'),
        makeScheme(
          id: 'b',
          title: 'Another Scheme',
          officialUrl: 'https://b.gov.in/2',
        ),
      ]);

      expect(File(dbPath).existsSync(), isTrue);
      // WAL side files must be checkpointed away for offline distribution.
      expect(File('$dbPath-wal').existsSync(), isFalse);
    });
  });
}
