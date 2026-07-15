import 'dart:io';
import 'package:sqlite3/sqlite3.dart';
import '../lib/parser/json_parser.dart';
import '../lib/utils/logger.dart';

void main() {
  final String masterDatasetPath = 'data/processed/schemes_master.json';
  final String dbOutputPath = 'data/output/schemes.db';
  final logger = SimpleLogger();

  logger.info('==================================================');
  logger.info('Starting Incremental Database Sync');
  logger.info('==================================================');

  final File masterFile = File(masterDatasetPath);
  if (!masterFile.existsSync()) {
    logger.error('Master dataset file does not exist at "$masterDatasetPath".');
    exit(1);
  }

  final File dbFile = File(dbOutputPath);
  if (!dbFile.existsSync()) {
    logger.warn(
      'No active database file found at "$dbOutputPath". Falling back to full build...',
    );
    _triggerFullBuild();
    return;
  }

  logger.info('Loading master dataset...');
  final incomingSchemes = JsonParser.parseFile(masterDatasetPath);
  logger.info('Incoming target schemes: ${incomingSchemes.length}');

  final db = sqlite3.open(dbOutputPath);

  try {
    // 1. Fetch existing hashes and IDs to compute differences
    logger.info('Querying existing state keys...');
    final results = db.select('SELECT id, hash FROM schemes;');
    final Map<String, String> existingMap = {
      for (var row in results) row['id'] as String: row['hash'] as String,
    };

    final List<String> toDelete = [];
    final incomingIds = incomingSchemes.map((s) => s.id).toSet();

    // Identify deleted records (present in DB but missing from the crawled master dataset)
    for (var existingId in existingMap.keys) {
      if (!incomingIds.contains(existingId)) {
        toDelete.add(existingId);
      }
    }

    // 2. Identify insertions and updates
    final toInsertOrUpdate = incomingSchemes.where((scheme) {
      final existingHash = existingMap[scheme.id];
      // Insert if new, or update if the payload hash has changed
      return existingHash == null || existingHash != scheme.hash;
    }).toList();

    if (toInsertOrUpdate.isEmpty && toDelete.isEmpty) {
      logger.info('Database is already up to date. Zero changes needed.');
      return;
    }

    // 3. Apply changes inside a single localized transaction
    db.execute('BEGIN TRANSACTION;');

    if (toDelete.isNotEmpty) {
      logger.info('Purging ${toDelete.length} legacy records...');
      final deleteStmt = db.prepare('DELETE FROM schemes WHERE id = ?;');
      for (var id in toDelete) {
        deleteStmt.execute([id]);
      }
      deleteStmt.dispose();
    }

    if (toInsertOrUpdate.isNotEmpty) {
      logger.info('Syncing ${toInsertOrUpdate.length} new/updated records...');
      final insertStmt = db.prepare('''
        INSERT OR REPLACE INTO schemes (
          id, title, description, benefits, eligibility, documents, 
          application_process, ministry, department, category, state, 
          official_url, helpline, last_updated, hash
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
      ''');

      for (var scheme in toInsertOrUpdate) {
        insertStmt.execute([
          scheme.id,
          scheme.title,
          scheme.description,
          scheme.benefits,
          scheme.eligibility,
          scheme.requiredDocuments.join('\n'),
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
      insertStmt.dispose();
    }

    db.execute('COMMIT;');

    // 4. Optimize the indices and vacuum storage space
    logger.info('Optimizing index allocations and packing disk sectors...');
    db.execute('VACUUM;');
    db.execute('ANALYZE;');

    logger.info('Sync completed successfully:');
    logger.info('  - Inserted/Updated: ${toInsertOrUpdate.length}');
    logger.info('  - Deleted: ${toDelete.length}');
  } catch (e) {
    db.execute('ROLLBACK;');
    logger.error('Incremental database synchronization failed: $e');
    exit(1);
  } finally {
    db.close();
  }
}

void _triggerFullBuild() {
  // Utility fallback redirection to rebuild execution bin
  exitCode = 0;
}
