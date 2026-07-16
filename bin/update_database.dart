import 'dart:io';

import 'package:government_scheme_db_builder/database/database.dart';
import 'package:government_scheme_db_builder/exporter/sqlite_exporter.dart';
import 'package:government_scheme_db_builder/parser/json_parser.dart';
import 'package:government_scheme_db_builder/utils/constants.dart';
import 'package:government_scheme_db_builder/utils/logger.dart';

/// Incrementally syncs an existing `schemes.db` with the current master
/// dataset: inserts new records, updates changed ones (detected via content
/// hash) and deletes records that disappeared from the dataset.
///
/// Falls back to a full build when no database exists yet.
void main() {
  const logger = SimpleLogger(name: 'update-database');
  logger.info('Starting incremental database sync');

  if (!File(kMasterDatasetPath).existsSync()) {
    logger.error('Master dataset not found at "$kMasterDatasetPath".');
    exit(1);
  }

  final incomingSchemes = JsonParser.parseFile(kMasterDatasetPath);
  logger.info('Incoming schemes: ${incomingSchemes.length}');

  if (!File(kDatabasePath).existsSync()) {
    logger.warn('No database at "$kDatabasePath"; running a full build.');
    SqliteExporter(kDatabasePath).export(incomingSchemes);
    logger.info('Full build complete: ${incomingSchemes.length} schemes.');
    return;
  }

  final db = SchemeDatabase.open(kDatabasePath);
  try {
    final existing = db.existingHashes();
    final incomingIds = incomingSchemes.map((s) => s.id).toSet();

    final toDelete =
        existing.keys.where((id) => !incomingIds.contains(id)).toList();
    final toUpsert = incomingSchemes
        .where((scheme) => existing[scheme.id] != scheme.hash)
        .toList();

    if (toUpsert.isEmpty && toDelete.isEmpty) {
      logger.info('Database already up to date; no changes needed.');
      return;
    }

    if (toDelete.isNotEmpty) {
      logger.info('Deleting ${toDelete.length} removed records...');
      db.deleteSchemes(toDelete);
    }
    if (toUpsert.isNotEmpty) {
      logger.info('Upserting ${toUpsert.length} new/changed records...');
      db.insertSchemes(toUpsert);
    }

    db.setMeta('record_count', '${db.count()}');
    db.optimize();

    logger.info('Sync complete: +${toUpsert.length} / -${toDelete.length}.');
  } on Exception catch (e) {
    logger.error('Incremental sync failed: $e');
    exit(1);
  } finally {
    db.close();
  }
}
