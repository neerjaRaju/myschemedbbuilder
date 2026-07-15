import '../database/database.dart';
import '../models/scheme.dart';
import '../sources/source.dart';
import '../utils/logger.dart';
import '../utils/normalizer.dart';
import '../validators/duplicate_validator.dart';
import '../validators/scheme_validator.dart';

class Pipeline {
  final DatabaseManager database;
  final SchemeSource source;

  final SchemeValidator validator = const SchemeValidator();
  final DuplicateValidator duplicateValidator =
      const DuplicateValidator();
  final Normalizer normalizer = const Normalizer();

  Pipeline({
    required this.database,
    required this.source,
  });

  Future<void> run() async {
    Logger.section(source.name);

    Logger.info("Loading source...");

    var schemes = await source.fetchSchemes();

    Logger.info("${schemes.length} records loaded");

    schemes = schemes
        .map(normalizer.normalize)
        .toList();

    schemes =
        duplicateValidator.removeDuplicates(schemes);

    Logger.info(
      "${schemes.length} after duplicate removal",
    );

    int imported = 0;

    for (final scheme in schemes) {
      if (!validator.isValid(scheme)) {
        continue;
      }

      database.insertScheme(scheme);

      imported++;
    }

    Logger.success("$imported imported");
  }
}