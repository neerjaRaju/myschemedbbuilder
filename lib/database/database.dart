import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

import '../models/scheme.dart';
import 'schema.dart';

class DatabaseManager {
  late final Database db;

  /// Open or create database
  void open({String path = 'data/output/schemes.db'}) {
    final file = File(path);

    if (!file.parent.existsSync()) {
      file.parent.createSync(recursive: true);
    }

    db = sqlite3.open(p.normalize(path));

    // Create tables
    for (final table in DatabaseSchema.tables) {
      db.execute(table);
    }

    // Create indexes
    for (final index in DatabaseSchema.indexes) {
      db.execute(index);
    }
  }

  /// Insert
  void insertScheme(Scheme scheme) {
    final stmt = db.prepare('''
      INSERT OR REPLACE INTO schemes(
        id,
        title,
        ministry,
        category,
        state,
        description,
        benefits,
        eligibility,
        documents,
        application_process,
        official_url,
        helpline,
        last_updated
      )
      VALUES(
        ?,?,?,?,?,?,?,?,?,?,?,?,?
      );
    ''');

    final m = scheme.toDbMap();

    stmt.execute([
      m['id'],
      m['title'],
      m['ministry'],
      m['category'],
      m['state'],
      m['description'],
      m['benefits'],
      m['eligibility'],
      m['documents'],
      m['application_process'],
      m['official_url'],
      m['helpline'],
      m['last_updated'],
    ]);

    stmt.close();
  }

  /// Get all schemes
  List<Scheme> getAllSchemes() {
    final ResultSet rows = db.select(
      'SELECT * FROM schemes ORDER BY title;',
    );

    return rows.map((e) => Scheme.fromDbMap(e)).toList();
  }

  /// Search by title
  List<Scheme> search(String keyword) {
    final rows = db.select(
      '''
      SELECT *
      FROM schemes
      WHERE title LIKE ?
      ORDER BY title;
      ''',
      ['%$keyword%'],
    );

    return rows.map((e) => Scheme.fromDbMap(e)).toList();
  }

  /// Count rows
  int count() {
    final row = db.select(
      'SELECT COUNT(*) AS total FROM schemes;',
    );

    return row.first['total'] as int;
  }

  /// Delete everything
  void clear() {
    db.execute('DELETE FROM schemes;');
  }

  /// Optimize database
  void optimize() {
    db.execute('VACUUM;');
    db.execute('ANALYZE;');
  }

  /// Close database
  void close() {
    db.close();
  }
}