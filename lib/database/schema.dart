class Schema {
  static const String createSchemesTable = '''
    CREATE TABLE IF NOT EXISTS schemes (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      description TEXT,
      benefits TEXT,
      eligibility TEXT,
      documents TEXT,
      application_process TEXT,
      ministry TEXT,
      department TEXT,
      category TEXT,
      state TEXT,
      official_url TEXT UNIQUE,
      helpline TEXT,
      last_updated TEXT,
      hash TEXT NOT NULL
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
      state
    );
  ''';

  static const String createIndices = '''
    CREATE INDEX IF NOT EXISTS idx_schemes_ministry ON schemes(ministry);
    CREATE INDEX IF NOT EXISTS idx_schemes_category ON schemes(category);
    CREATE INDEX IF NOT EXISTS idx_schemes_state ON schemes(state);
  ''';

  static const String createFtsTriggers = '''
    CREATE TRIGGER IF NOT EXISTS after_scheme_insert AFTER INSERT ON schemes BEGIN
      INSERT INTO schemes_fts(id, title, description, benefits, eligibility, ministry, category, state)
      VALUES (new.id, new.title, new.description, new.benefits, new.eligibility, new.ministry, new.category, new.state);
    END;

    CREATE TRIGGER IF NOT EXISTS after_scheme_delete AFTER DELETE ON schemes BEGIN
      DELETE FROM schemes_fts WHERE id = old.id;
    END;

    CREATE TRIGGER IF NOT EXISTS after_scheme_update AFTER UPDATE ON schemes BEGIN
      UPDATE schemes_fts SET
        title = new.title,
        description = new.description,
        benefits = new.benefits,
        eligibility = new.eligibility,
        ministry = new.ministry,
        category = new.category,
        state = new.state
      WHERE id = old.id;
    END;
  ''';
}
