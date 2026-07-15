import 'dart:io';
import '../lib/parser/json_parser.dart';
import '../lib/exporter/sqlite_exporter.dart';

void main() {
  final String masterDatasetPath = 'data/processed/schemes_master.json';
  final String dbOutputPath = 'data/output/schemes.db';

  print('==================================================');
  print('Starting SQLite Database Builder');
  print('==================================================');

  final File masterFile = File(masterDatasetPath);
  if (!masterFile.existsSync()) {
    print('Error: Master dataset file does not exist at "$masterDatasetPath".');
    print('Please run bin/build_master_dataset.dart first.');
    exit(1);
  }

  print('Loading master schemes...');
  final schemes = JsonParser.parseFile(masterDatasetPath);
  print('Loaded ${schemes.length} schemes.');

  if (schemes.isEmpty) {
    print('Warning: No records found to build into the SQLite database.');
    exit(0);
  }

  // Ensure old output database file is replaced cleanly
  final File dbFile = File(dbOutputPath);
  if (dbFile.existsSync()) {
    print('Removing existing database at "$dbOutputPath" for clean build...');
    dbFile.deleteSync();
  }

  print(
    'Exporting to SQLite (applying transaction batching, indexing, WAL & FTS5 search)...',
  );
  final exporter = SqliteExporter(dbOutputPath);

  try {
    final stopwatch = Stopwatch()..start();
    exporter.export(schemes);
    stopwatch.stop();

    print(
      'Export finished successfully in ${stopwatch.elapsedMilliseconds} ms.',
    );
    print('SQLite Database created at: $dbOutputPath');
  } catch (e) {
    print('Error: Database export pipeline failed: $e');
    exit(1);
  }
}
