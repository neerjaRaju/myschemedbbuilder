import 'dart:io';
import 'package:sqlite3/sqlite3.dart';
import '../models/scheme.dart';
import '../database/schema.dart';

class SqliteExporter {

  final String dbPath;

  SqliteExporter(this.dbPath);

  void export(List<Scheme> schemes) {
    final file = File(dbPath);
    if (!file.parent.existsSync()) {
      file.parent.createSync(recursive: true);
    }

    final db = sqlite3.open(dbPath);

    try {
      // Performance optimization pragmas
      db.execute('PRAGMA journal_mode = WAL;');
      db.execute('PRAGMA synchronous = NORMAL;');
      db.execute('PRAGMA foreign_keys = ON;');

      // Initialize Database Schema
      db.execute(Schema.createSchemesTable);
      db.execute(Schema.createFtsTable);
      db.execute(Schema.createIndices);
      db.execute(Schema.createFtsTriggers);

      // Execute inside a single transactional batch
      db.execute('BEGIN TRANSACTION;');

      final stmt = db.prepare('''
        INSERT OR REPLACE INTO schemes (
          id, title, description, benefits, eligibility, documents, 
          application_process, ministry, department, category, state, 
          official_url, helpline, last_updated, hash
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
      ''');

      for (var scheme in schemes) {
        stmt.execute([
          scheme.id,
          scheme.title,
          scheme.description,
          scheme.benefits,
          scheme.eligibility,
          scheme.requiredDocuments?.join('\n'),
          scheme.applicationProcess,
          scheme.ministry,
          scheme.department,
          scheme.category,
          scheme.state,
          scheme.officialUrl,
          scheme.helpline,
          scheme.lastUpdated,
          scheme.hash,
        ]);
      }
      stmt.dispose();
      db.execute('COMMIT;');
      db.execute('VACUUM;');
      db.execute('ANALYZE;');
    } catch (e) {
      db.execute('ROLLBACK;');
      rethrow;
    } finally {
      db.dispose();
    }
  }
}
