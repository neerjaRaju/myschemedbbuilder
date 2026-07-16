import 'dart:convert';

import 'package:sqlite3/sqlite3.dart';

import '../models/scheme.dart';
import '../utils/constants.dart';
import 'schema.dart';

/// High-level wrapper around the SQLite schemes database.
///
/// Handles pragmas (WAL, foreign keys), schema creation, batched multi-row
/// inserts via prepared statements, incremental sync, FTS5 search and final
/// optimization (`VACUUM` / `ANALYZE`).
class SchemeDatabase {
  final Database _db;

  SchemeDatabase._(this._db);

  /// Opens (or creates) the database at [path] with production pragmas and
  /// the full schema applied.
  factory SchemeDatabase.open(String path) {
    final db = sqlite3.open(path);
    return SchemeDatabase._(db).._initialize();
  }

  /// Opens an in-memory database — used by unit tests.
  factory SchemeDatabase.inMemory() {
    final db = sqlite3.openInMemory();
    return SchemeDatabase._(db).._initialize();
  }

  void _initialize() {
    _db
      ..execute('PRAGMA journal_mode = WAL;')
      ..execute('PRAGMA synchronous = NORMAL;')
      ..execute('PRAGMA foreign_keys = ON;')
      ..execute(Schema.createSchemesTable)
      ..execute(Schema.createTagsTable)
      ..execute(Schema.createMetaTable)
      ..execute(Schema.createFtsTable)
      ..execute(Schema.createFtsTriggers);
    for (final statement in Schema.createIndices) {
      _db.execute(statement);
    }
    _db.execute(
      "INSERT OR REPLACE INTO meta(key, value) "
      "VALUES ('schema_version', '${Schema.version}');",
    );
  }

  static const int _columnsPerScheme = 17;

  /// Inserts [schemes] using multi-row prepared statements inside a single
  /// transaction. Rows are written in chunks of [batchSize] to stay far below
  /// SQLite's bound-parameter limit while avoiding row-by-row loops.
  void insertSchemes(List<Scheme> schemes, {int batchSize = kInsertBatchSize}) {
    if (schemes.isEmpty) return;

    _db.execute('BEGIN TRANSACTION;');
    try {
      for (var start = 0; start < schemes.length; start += batchSize) {
        final chunk = schemes.sublist(
          start,
          start + batchSize > schemes.length
              ? schemes.length
              : start + batchSize,
        );
        _insertChunk(chunk);
      }
      _db.execute('COMMIT;');
    } catch (_) {
      _db.execute('ROLLBACK;');
      rethrow;
    }
  }

  void _insertChunk(List<Scheme> chunk) {
    final row = '(${List.filled(_columnsPerScheme, '?').join(', ')})';
    final placeholders = List.filled(chunk.length, row).join(',\n');

    final statement = _db.prepare('''
      INSERT OR REPLACE INTO schemes (
        id, title, description, benefits, eligibility, documents,
        application_process, ministry, department, category, tags, state,
        official_url, helpline, faq, last_updated, hash
      ) VALUES
      $placeholders;
    ''');
    try {
      statement.execute([
        for (final scheme in chunk) ..._schemeParams(scheme),
      ]);
    } finally {
      statement.dispose();
    }

    final tagRows = <List<Object>>[
      for (final scheme in chunk)
        for (final tag in scheme.tags.toSet()) [scheme.id, tag],
    ];
    if (tagRows.isEmpty) return;

    final tagStatement = _db.prepare(
      'INSERT OR REPLACE INTO scheme_tags (scheme_id, tag) VALUES '
      '${List.filled(tagRows.length, '(?, ?)').join(', ')};',
    );
    try {
      tagStatement.execute([for (final r in tagRows) ...r]);
    } finally {
      tagStatement.dispose();
    }
  }

  List<Object?> _schemeParams(Scheme scheme) => [
        scheme.id,
        scheme.title,
        scheme.description,
        scheme.benefits,
        scheme.eligibility,
        scheme.requiredDocuments.join('\n'),
        scheme.applicationProcess,
        scheme.ministry,
        scheme.department,
        scheme.category,
        json.encode(scheme.tags),
        scheme.state,
        scheme.officialUrl,
        scheme.helpline,
        json.encode(scheme.faq),
        scheme.lastUpdated,
        scheme.hash,
      ];

  /// Deletes the schemes with the given [ids] (tags cascade automatically).
  void deleteSchemes(List<String> ids) {
    if (ids.isEmpty) return;
    _db.execute('BEGIN TRANSACTION;');
    try {
      final statement = _db.prepare(
        'DELETE FROM schemes WHERE id IN '
        '(${List.filled(ids.length, '?').join(', ')});',
      );
      try {
        statement.execute(ids);
      } finally {
        statement.dispose();
      }
      _db.execute('COMMIT;');
    } catch (_) {
      _db.execute('ROLLBACK;');
      rethrow;
    }
  }

  /// Returns `id -> hash` for every stored scheme, used by incremental sync.
  Map<String, String> existingHashes() {
    final rows = _db.select('SELECT id, hash FROM schemes;');
    return {
      for (final row in rows) row['id'] as String: row['hash'] as String,
    };
  }

  /// Number of schemes stored.
  int count() =>
      _db.select('SELECT COUNT(*) AS c FROM schemes;').first['c'] as int;

  /// Full-text search across title, description, benefits, eligibility,
  /// ministry, category, state and tags.
  List<Map<String, Object?>> search(String query, {int limit = 20}) {
    final statement = _db.prepare('''
      SELECT s.* FROM schemes s
      JOIN schemes_fts f ON f.id = s.id
      WHERE schemes_fts MATCH ?
      ORDER BY rank
      LIMIT ?;
    ''');
    try {
      final rows = statement.select([query, limit]);
      return [for (final row in rows) Map<String, Object?>.from(row)];
    } finally {
      statement.dispose();
    }
  }

  /// Records a metadata key/value pair.
  void setMeta(String key, String value) {
    final statement =
        _db.prepare('INSERT OR REPLACE INTO meta(key, value) VALUES (?, ?);');
    try {
      statement.execute([key, value]);
    } finally {
      statement.dispose();
    }
  }

  /// Compacts and re-analyzes the database, then checkpoints the WAL so the
  /// single `.db` file is self-contained for offline distribution.
  void optimize() {
    _db
      ..execute('ANALYZE;')
      ..execute('VACUUM;')
      ..execute('PRAGMA wal_checkpoint(TRUNCATE);')
      ..execute('PRAGMA optimize;');
  }

  /// Closes the underlying connection.
  void close() => _db.dispose();
}
