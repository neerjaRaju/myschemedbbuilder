import '../models/scheme.dart';
import '../utils/normalizer.dart';

class SchemeValidator {
  /// Validates a scheme model instance against exact non-empty constraints.
  static bool isValid(Scheme scheme, List<String> errorLog) {
    bool valid = true;

    if (scheme.id.trim().isEmpty) {
      errorLog.add('Scheme ID is empty.');
      valid = false;
    }
    if (scheme.title.trim().isEmpty) {
      errorLog.add('[ID: ${scheme.id}] Scheme title is empty.');
      valid = false;
    }
    if (scheme.description.trim().isEmpty) {
      errorLog.add('[ID: ${scheme.id}] Description is empty.');
      valid = false;
    }
    if (scheme.officialUrl.trim().isEmpty ||
        Normalizer.normalizeUrl(scheme.officialUrl).isEmpty) {
      errorLog.add(
        '[ID: ${scheme.id}] Official URL "${scheme.officialUrl}" is invalid.',
      );
      valid = false;
    }
    if (scheme.ministry.trim().isEmpty) {
      errorLog.add('[ID: ${scheme.id}] Ministry designation field missing.');
      valid = false;
    }

    return valid;
  }
}
