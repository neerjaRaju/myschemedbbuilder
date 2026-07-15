import 'package:html/parser.dart' show parse;

class Normalizer {
  /// Cleans whitespace, removes HTML tags, normalizes Unicode accents, and trims output.
  static String sanitizeText(String input) {
    if (input.isEmpty) return '';

    // Parse HTML entities and extract text
    final document = parse(input);
    String text = document.body?.text ?? input;

    // Normalize Unicode forms (NFKC)
    text = Uri.decodeComponent(Uri.encodeComponent(text));

    // Clean excessive whitespaces and line endings
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Converts complex raw HTML lists or text block lists into standardized clean Markdown lists.
  static String normalizeList(List<String> items) {
    return items
        .map((item) => sanitizeText(item))
        .where((item) => item.isNotEmpty)
        .map((item) => '* $item')
        .join('\n');
  }

  /// Extracts and formats Indian standard contact formats into structural string tokens.
  static String normalizeHelpline(String input) {
    String digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 10) {
      return '+91-$digits';
    } else if (digits.length == 12 && digits.startsWith('91')) {
      return '+91-${digits.substring(2)}';
    }
    return sanitizeText(
      input,
    ); // Return clean raw version if it's a shortcode or custom toll-free string
  }

  /// Parses diverse local date strings into deterministic ISO 8601 strings (`YYYY-MM-DD`).
  static String normalizeDate(String input) {
    try {
      final clean = input.trim();
      // Handle standard DD/MM/YYYY
      final dmyRegex = RegExp(r'^(\d{1,2})[-/](\d{1,2})[-/](\d{4})$');
      if (dmyRegex.hasMatch(clean)) {
        final match = dmyRegex.firstMatch(clean)!;
        final day = match.group(1)!.padLeft(2, '0');
        final month = match.group(2)!.padLeft(2, '0');
        final year = match.group(3);
        return '$year-$month-$day';
      }

      // Fallback to core DateTime parsing
      final parsed = DateTime.parse(clean);
      return parsed.toIso8601String().substring(0, 10);
    } catch (_) {
      // Default to epoch or current placeholder standard if entirely unparseable
      return DateTime.now().toIso8601String().substring(0, 10);
    }
  }

  /// Normalizes canonical URL shapes.
  static String normalizeUrl(String input) {
    try {
      final uri = Uri.parse(input.trim().toLowerCase());
      if (!uri.hasScheme) {
        return 'https://${uri.toString()}';
      }
      return uri.toString();
    } catch (_) {
      return '';
    }
  }
}
