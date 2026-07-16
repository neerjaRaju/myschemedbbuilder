import 'dart:io';

import '../database/database.dart';
import '../models/scheme.dart';

/// Builds the distributable SQLite database from a list of schemes.
class SqliteExporter {
  final String dbPath;

  SqliteExporter(this.dbPath);

  /// Writes all [schemes] into a freshly created database at [dbPath].
  ///
  /// Input is sorted by id before insertion so repeated exports of the same
  /// dataset produce identical databases.
  void export(List<Scheme> schemes) {
    final file = File(dbPath);
    if (!file.parent.existsSync()) {
      file.parent.createSync(recursive: true);
    }
    // Remove any previous build (including WAL side files) for a clean,
    // deterministic output.
    for (final suffix in ['', '-wal', '-shm']) {
      final stale = File('$dbPath$suffix');
      if (stale.existsSync()) stale.deleteSync();
    }

    final sorted = List<Scheme>.of(schemes)
      ..sort((a, b) => a.id.compareTo(b.id));

    final db = SchemeDatabase.open(dbPath);
    try {
      db
        ..insertSchemes(sorted)
        ..setMeta('record_count', '${sorted.length}')
        ..optimize();
    } finally {
      db.close();
    }
  }
}
