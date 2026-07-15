class DatabaseSchema {
  static const int version = 1;

  static const String createSchemesTable = '''
CREATE TABLE IF NOT EXISTS schemes(
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    ministry TEXT,
    category TEXT,
    state TEXT,
    description TEXT,
    benefits TEXT,
    eligibility TEXT,
    documents TEXT,
    application_process TEXT,
    official_url TEXT,
    helpline TEXT,
    last_updated TEXT
);
''';

  static const List<String> indexes = [
    '''
    CREATE INDEX IF NOT EXISTS idx_title
    ON schemes(title);
    ''',

    '''
    CREATE INDEX IF NOT EXISTS idx_category
    ON schemes(category);
    ''',

    '''
    CREATE INDEX IF NOT EXISTS idx_ministry
    ON schemes(ministry);
    ''',

    '''
    CREATE INDEX IF NOT EXISTS idx_state
    ON schemes(state);
    ''',
  ];

  static const List<String> tables = [
    createSchemesTable,
  ];
}