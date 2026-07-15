import 'dart:async';

import 'package:government_scheme_db_builder/database/database.dart';
import 'package:government_scheme_db_builder/importers/master_importer.dart';
import 'package:government_scheme_db_builder/utils/logger.dart';

Future<void> main() async {
  Logger.section("Government Scheme Database Builder");

  final db = DatabaseManager();

  try {
    Logger.info("Opening database...");
    db.open();

    Logger.info("Clearing existing data...");
    db.clear();

    Logger.info("Starting import...");

    final importer = MasterImporter(db);

    await importer.import(
      "data/processed/schemes_master.json",
    );

    Logger.info("Optimizing database...");
    db.optimize();

    Logger.success(
      "Database build completed successfully!",
    );

    Logger.info("Total schemes: ${db.count()}");
  } catch (e, stackTrace) {
    Logger.error("Database build failed.");
    Logger.error(e.toString());

    print(stackTrace);
  } finally {
    Logger.info("Closing database...");
    db.close();
  }
}