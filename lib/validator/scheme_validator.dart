import '../models/scheme.dart';

/// Validates individual scheme records before they enter the master dataset.
class SchemeValidator {
  SchemeValidator._();

  static final RegExp _isoDate = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  /// Returns `true` when [scheme] satisfies every constraint; failures are
  /// appended to [errorLog].
  static bool isValid(Scheme scheme, List<String> errorLog) {
    var valid = true;

    if (scheme.id.trim().isEmpty) {
      errorLog.add('Scheme ID is empty.');
      valid = false;
    }
    if (scheme.title.trim().isEmpty) {
      errorLog.add('[ID: ${scheme.id}] Scheme title is empty.');
      valid = false;
    }
    if (!_isValidUrl(scheme.officialUrl)) {
      errorLog.add(
        '[ID: ${scheme.id}] Official URL "${scheme.officialUrl}" is invalid.',
      );
      valid = false;
    }
    if (!_hasContent(scheme)) {
      errorLog.add(
        '[ID: ${scheme.id}] Record has no descriptive content '
        '(description, benefits and eligibility are all empty).',
      );
      valid = false;
    }
    if (scheme.lastUpdated.isNotEmpty && !_isValidDate(scheme.lastUpdated)) {
      errorLog.add(
        '[ID: ${scheme.id}] Last-updated date "${scheme.lastUpdated}" '
        'is not a valid ISO date.',
      );
      valid = false;
    }

    return valid;
  }

  /// A record must carry at least one piece of descriptive content to be
  /// useful offline.
  static bool _hasContent(Scheme scheme) {
    return scheme.description.trim().isNotEmpty ||
        scheme.benefits.trim().isNotEmpty ||
        scheme.eligibility.trim().isNotEmpty;
  }

  static bool _isValidUrl(String url) {
    final uri = Uri.tryParse(url.trim());
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  static bool _isValidDate(String value) {
    if (!_isoDate.hasMatch(value)) return false;
    final parsed = DateTime.tryParse(value);
    return parsed != null;
  }
}
