import 'dart:io';

import 'package:government_scheme_db_builder/exporter/sqlite_exporter.dart';
import 'package:government_scheme_db_builder/parser/json_parser.dart';
import 'package:government_scheme_db_builder/utils/constants.dart';
import 'package:government_scheme_db_builder/utils/logger.dart';

/// Builds the offline SQLite database `data/output/schemes.db` from the
/// master dataset produced by `build_master_dataset.dart`.
void main() {
  const logger = SimpleLogger(name: 'build-database');
  logger.info('Starting SQLite database builder');

  if (!File(kMasterDatasetPath).existsSync()) {
    logger.error('Master dataset not found at "$kMasterDatasetPath".');
    logger.error('Run `dart run bin/build_master_dataset.dart` first.');
    exit(1);
  }

  final schemes = JsonParser.parseFile(kMasterDatasetPath);
  logger.info('Loaded ${schemes.length} schemes from master dataset.');

  if (schemes.isEmpty) {
    logger.warn('No records found; writing an empty (schema-only) database.');
  }

  try {
    final stopwatch = Stopwatch()..start();
    SqliteExporter(kDatabasePath).export(schemes);
    stopwatch.stop();

    logger.info(
      'Exported ${schemes.length} schemes in '
      '${stopwatch.elapsedMilliseconds} ms.',
    );
    logger.info('SQLite database created at: $kDatabasePath');
  } on Exception catch (e) {
    logger.error('Database export failed: $e');
    exit(1);
  }
}
