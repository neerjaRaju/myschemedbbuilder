import 'package:html/parser.dart' show parse;

/// Text, date, URL and phone-number normalization used by the extractor,
/// validators and dataset builder.
class Normalizer {
  Normalizer._();

  static final RegExp _whitespace = RegExp(r'\s+');
  static final RegExp _bulletChars =
      RegExp('[\\u2022\\u25cf\\u25aa\\u2043\\u00b7]');
  static final RegExp _invisibleChars =
      RegExp('[\\u200b\\u200c\\u200d\\ufeff\\u00ad]');
  static final RegExp _isoDate = RegExp(r'^(\d{4})-(\d{2})-(\d{2})');
  static final RegExp _dmyDate =
      RegExp(r'^(\d{1,2})[-/.](\d{1,2})[-/.](\d{4})$');
  static final RegExp _monthNameDate = RegExp(
    r'^(\d{1,2})(?:st|nd|rd|th)?\s+([A-Za-z]+)[,]?\s+(\d{4})$',
  );
  static final RegExp _nameMonthDate =
      RegExp(r'^([A-Za-z]+)\s+(\d{1,2})(?:st|nd|rd|th)?[,]?\s+(\d{4})$');
  static final RegExp _trackingParam = RegExp(r'^(utm_|fbclid|gclid)');

  static const Map<String, int> _months = {
    'jan': 1,
    'january': 1,
    'feb': 2,
    'february': 2,
    'mar': 3,
    'march': 3,
    'apr': 4,
    'april': 4,
    'may': 5,
    'jun': 6,
    'june': 6,
    'jul': 7,
    'july': 7,
    'aug': 8,
    'august': 8,
    'sep': 9,
    'sept': 9,
    'september': 9,
    'oct': 10,
    'october': 10,
    'nov': 11,
    'november': 11,
    'dec': 12,
    'december': 12,
  };

  /// Strips HTML markup and entities, removes invisible unicode characters,
  /// replaces non-breaking spaces and bullet glyphs, and collapses whitespace.
  static String sanitizeText(String input) {
    if (input.isEmpty) return '';

    // Decode HTML entities and drop tags.
    final document = parse(input);
    var text = document.body?.text ?? input;

    text = text
        .replaceAll(' ', ' ')
        .replaceAll(_invisibleChars, '')
        .replaceAll(_bulletChars, ' ');

    return text.replaceAll(_whitespace, ' ').trim();
  }

  /// Converts raw list items into a deterministic Markdown bullet list.
  static String normalizeList(List<String> items) {
    return items
        .map(sanitizeText)
        .where((item) => item.isNotEmpty)
        .map((item) => '* $item')
        .join('\n');
  }

  /// Formats Indian phone numbers as `+91-XXXXXXXXXX`; other values
  /// (short codes, toll-free strings, text) are returned sanitized.
  ///
  /// Only inputs consisting purely of digits and phone separators are
  /// reformatted, so surrounding prose is never mangled.
  static String normalizeHelpline(String input) {
    final clean = sanitizeText(input);
    final isPhoneLike = RegExp(r'^[\d\s()+-]+$').hasMatch(clean);
    if (isPhoneLike) {
      final digits = clean.replaceAll(RegExp(r'\D'), '');
      if (digits.length == 10) {
        return '+91-$digits';
      }
      if (digits.length == 12 && digits.startsWith('91')) {
        return '+91-${digits.substring(2)}';
      }
    }
    return clean;
  }

  /// Parses common Indian-government date formats into ISO 8601
  /// (`YYYY-MM-DD`). Returns an empty string when the input cannot be parsed
  /// so downstream output stays deterministic.
  static String normalizeDate(String input) {
    final clean = sanitizeText(input);
    if (clean.isEmpty) return '';

    final iso = _isoDate.firstMatch(clean);
    if (iso != null) {
      return _validated(iso.group(1)!, iso.group(2)!, iso.group(3)!);
    }

    final dmy = _dmyDate.firstMatch(clean);
    if (dmy != null) {
      return _validated(dmy.group(3)!, dmy.group(2)!, dmy.group(1)!);
    }

    final dMonY = _monthNameDate.firstMatch(clean);
    if (dMonY != null) {
      final month = _months[dMonY.group(2)!.toLowerCase()];
      if (month != null) {
        return _validated(dMonY.group(3)!, '$month', dMonY.group(1)!);
      }
    }

    final monDY = _nameMonthDate.firstMatch(clean);
    if (monDY != null) {
      final month = _months[monDY.group(1)!.toLowerCase()];
      if (month != null) {
        return _validated(monDY.group(3)!, '$month', monDY.group(2)!);
      }
    }

    final parsed = DateTime.tryParse(clean);
    if (parsed != null) {
      return parsed.toIso8601String().substring(0, 10);
    }
    return '';
  }

  static String _validated(String year, String month, String day) {
    final y = int.parse(year);
    final m = int.parse(month);
    final d = int.parse(day);
    if (m < 1 || m > 12 || d < 1 || d > 31) return '';
    final mm = '$m'.padLeft(2, '0');
    final dd = '$d'.padLeft(2, '0');
    return '$y-$mm-$dd';
  }

  /// Canonicalizes a URL for de-duplication: lowercases the scheme and host,
  /// removes fragments, tracking parameters, default ports and trailing
  /// slashes. Returns an empty string for unusable input.
  static String normalizeUrl(String input) {
    final raw = input.trim();
    if (raw.isEmpty) return '';

    var candidate = raw;
    if (!candidate.contains('://')) {
      candidate = 'https://$candidate';
    }

    final uri = Uri.tryParse(candidate);
    if (uri == null || uri.host.isEmpty) return '';

    final query = Map.of(uri.queryParameters)
      ..removeWhere((key, _) => _trackingParam.hasMatch(key));

    var path = uri.path;
    if (path.length > 1 && path.endsWith('/')) {
      path = path.substring(0, path.length - 1);
    }

    final normalized = Uri(
      scheme: uri.scheme.toLowerCase(),
      host: uri.host.toLowerCase(),
      port: uri.hasPort &&
              !((uri.scheme == 'https' && uri.port == 443) ||
                  (uri.scheme == 'http' && uri.port == 80))
          ? uri.port
          : null,
      path: path,
      queryParameters: query.isEmpty ? null : query,
    );
    return normalized.toString();
  }
}
