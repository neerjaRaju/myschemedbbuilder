/// SQL schema for the offline schemes database.
///
/// Layout notes:
/// * `schemes` holds one row per scheme; `tags` and `faq` are stored as JSON
///   text so consumers can decode them without extra joins.
/// * `scheme_tags` is a normalized side table (with a foreign key back to
///   `schemes`) enabling indexed tag lookups.
/// * `schemes_fts` is an FTS5 index kept in sync by triggers.
class Schema {
  Schema._();

  /// Current schema version, recorded in the `meta` table.
  static const int version = 2;

  static const String createSchemesTable = '''
    CREATE TABLE IF NOT EXISTS schemes (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      description TEXT NOT NULL DEFAULT '',
      benefits TEXT NOT NULL DEFAULT '',
      eligibility TEXT NOT NULL DEFAULT '',
      documents TEXT NOT NULL DEFAULT '',
      application_process TEXT NOT NULL DEFAULT '',
      ministry TEXT NOT NULL DEFAULT '',
      department TEXT NOT NULL DEFAULT '',
      category TEXT NOT NULL DEFAULT '',
      tags TEXT NOT NULL DEFAULT '[]',
      state TEXT NOT NULL DEFAULT '',
      official_url TEXT NOT NULL UNIQUE,
      helpline TEXT NOT NULL DEFAULT '',
      faq TEXT NOT NULL DEFAULT '{}',
      last_updated TEXT NOT NULL DEFAULT '',
      hash TEXT NOT NULL
    );
  ''';

  static const String createTagsTable = '''
    CREATE TABLE IF NOT EXISTS scheme_tags (
      scheme_id TEXT NOT NULL,
      tag TEXT NOT NULL,
      PRIMARY KEY (scheme_id, tag),
      FOREIGN KEY (scheme_id) REFERENCES schemes(id) ON DELETE CASCADE
    );
  ''';

  static const String createMetaTable = '''
    CREATE TABLE IF NOT EXISTS meta (
      key TEXT PRIMARY KEY,
      value TEXT NOT NULL
    );
  ''';

  static const String createFtsTable = '''
    CREATE VIRTUAL TABLE IF NOT EXISTS schemes_fts USING fts5(
      id UNINDEXED,
      title,
      description,
      benefits,
      eligibility,
      ministry,
      category,
      state,
      tags
    );
  ''';

  static const List<String> createIndices = [
    'CREATE INDEX IF NOT EXISTS idx_schemes_title ON schemes(title);',
    'CREATE INDEX IF NOT EXISTS idx_schemes_ministry ON schemes(ministry);',
    'CREATE INDEX IF NOT EXISTS idx_schemes_category ON schemes(category);',
    'CREATE INDEX IF NOT EXISTS idx_schemes_state ON schemes(state);',
    'CREATE INDEX IF NOT EXISTS idx_scheme_tags_tag ON scheme_tags(tag);',
  ];

  static const String createFtsTriggers = '''
    CREATE TRIGGER IF NOT EXISTS after_scheme_insert AFTER INSERT ON schemes BEGIN
      INSERT INTO schemes_fts(id, title, description, benefits, eligibility, ministry, category, state, tags)
      VALUES (new.id, new.title, new.description, new.benefits, new.eligibility, new.ministry, new.category, new.state, new.tags);
    END;

    CREATE TRIGGER IF NOT EXISTS after_scheme_delete AFTER DELETE ON schemes BEGIN
      DELETE FROM schemes_fts WHERE id = old.id;
    END;

    CREATE TRIGGER IF NOT EXISTS after_scheme_update AFTER UPDATE ON schemes BEGIN
      DELETE FROM schemes_fts WHERE id = old.id;
      INSERT INTO schemes_fts(id, title, description, benefits, eligibility, ministry, category, state, tags)
      VALUES (new.id, new.title, new.description, new.benefits, new.eligibility, new.ministry, new.category, new.state, new.tags);
    END;
  ''';
}
