import '../database/database.dart';
import '../models/scheme.dart';
import '../parsers/json_parser.dart';
import '../utils/logger.dart';
import '../utils/normalizer.dart';
import '../validators/duplicate_validator.dart';
import '../validators/scheme_validator.dart';

class MasterImporter {
    
  final DatabaseManager database;

  final JsonParser _parser = const JsonParser();
  final Normalizer _normalizer = const Normalizer();
  final SchemeValidator _validator = const SchemeValidator();
  final DuplicateValidator _duplicateValidator =
      const DuplicateValidator();

  MasterImporter(this.database);

  Future<void> import(String jsonFile) async {
    Logger.info("Reading dataset...");

    List<Scheme> schemes =
        await _parser.parseFile(jsonFile);

    Logger.info(
      "Loaded ${schemes.length} records",
    );

    schemes = schemes
        .map(_normalizer.normalize)
        .toList();

    schemes =
        _duplicateValidator.removeDuplicates(schemes);

    Logger.info(
      "After duplicate removal: ${schemes.length}",
    );

    int imported = 0;
    int skipped = 0;

    for (int i = 0; i < schemes.length; i++) {
      final scheme = schemes[i];

      if (!_validator.isValid(scheme)) {
        skipped++;
        continue;
      }

      database.insertScheme(scheme);

      imported++;

      if ((i + 1) % 100 == 0 || i + 1 == schemes.length) {
        Logger.info(
          "Imported ${i + 1}/${schemes.length}",
        );
      }
    }

    Logger.success("Import completed");

    Logger.info("Imported : $imported");

    Logger.info("Skipped  : $skipped");
  }
}