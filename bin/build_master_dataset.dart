import 'dart:io';

import 'package:government_scheme_db_builder/exporter/json_exporter.dart';
import 'package:government_scheme_db_builder/models/scheme.dart';
import 'package:government_scheme_db_builder/parser/json_parser.dart';
import 'package:government_scheme_db_builder/utils/constants.dart';
import 'package:government_scheme_db_builder/utils/logger.dart';
import 'package:government_scheme_db_builder/validator/duplicate_validator.dart';
import 'package:government_scheme_db_builder/validator/scheme_validator.dart';

/// Merges every generated crawler dataset into the validated, de-duplicated,
/// deterministically sorted master dataset at
/// `data/processed/schemes_master.json`.
void main() {
  const logger = SimpleLogger(name: 'master-dataset');
  final generatedDir = Directory(kGeneratedDir);

  if (!generatedDir.existsSync()) {
    logger.error('Generated data directory "$kGeneratedDir" does not exist.');
    exit(1);
  }

  logger.info('Starting master dataset compiler');

  // 1. Merge every crawler output.
  final allSchemes = <Scheme>[];
  final inputFiles = generatedDir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.json'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  for (final file in inputFiles) {
    final schemes = JsonParser.parseFile(file.path);
    logger.info('Read ${schemes.length} records from ${file.path}');
    allSchemes.addAll(schemes);
  }
  logger.info('Total raw records loaded: ${allSchemes.length}');

  // 2. Validate.
  final errorLog = <String>[];
  final validatedSchemes = allSchemes
      .where((scheme) => SchemeValidator.isValid(scheme, errorLog))
      .toList();

  if (errorLog.isNotEmpty) {
    logger.warn('Validation rejected records (${errorLog.length} issues):');
    for (final error in errorLog.take(15)) {
      logger.warn('  - $error');
    }
    if (errorLog.length > 15) {
      logger.warn('  - ... and ${errorLog.length - 15} more.');
    }
  }
  logger.info('Valid records: ${validatedSchemes.length}');

  // 3. De-duplicate across sources.
  final deduplicationLog = <String>[];
  final uniqueSchemes =
      DuplicateValidator.deduplicate(validatedSchemes, deduplicationLog);

  if (deduplicationLog.isNotEmpty) {
    logger.info('Removed ${deduplicationLog.length} duplicates:');
    for (final entry in deduplicationLog.take(10)) {
      logger.info('  - $entry');
    }
    if (deduplicationLog.length > 10) {
      logger.info('  - ... and ${deduplicationLog.length - 10} more.');
    }
  }

  // 4. Deterministic sort + write (JsonExporter sorts by id).
  JsonExporter.export(kMasterDatasetPath, uniqueSchemes);
  logger.info(
    'Master dataset with ${uniqueSchemes.length} records written to '
    '$kMasterDatasetPath',
  );
}
