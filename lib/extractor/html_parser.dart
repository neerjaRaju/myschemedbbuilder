import 'package:html/dom.dart';
import 'package:html/parser.dart' show parse;

import '../utils/normalizer.dart';

/// Thin, null-safe wrapper around an HTML DOM with normalization applied to
/// every extracted string.
class HtmlParser {
  final Document document;

  HtmlParser(String htmlContent) : document = parse(htmlContent);

  /// Selects a single element's text safely and normalizes it.
  String selectText(String selector, {String fallback = ''}) {
    final element = document.querySelector(selector);
    if (element == null) return fallback;
    final text = Normalizer.sanitizeText(element.text);
    return text.isEmpty ? fallback : text;
  }

  /// Selects all text from elements matching a selector and joins them.
  String selectTextJoined(String selector, {String separator = '\n'}) {
    final elements = document.querySelectorAll(selector);
    return elements
        .map((el) => Normalizer.sanitizeText(el.text))
        .where((text) => text.isNotEmpty)
        .join(separator);
  }

  /// Extracts list elements (e.g. `<ul>`/`<ol>` items) as clean strings.
  List<String> selectList(String selector) {
    final elements = document.querySelectorAll(selector);
    return elements
        .map((el) => Normalizer.sanitizeText(el.text))
        .where((text) => text.isNotEmpty)
        .toList();
  }

  /// Safely extracts an attribute value from the first element matching a
  /// CSS selector.
  String? selectAttribute(String selector, String attribute) {
    final element = document.querySelector(selector);
    return element?.attributes[attribute];
  }

  /// Returns the raw text of `<script id="...">`, used to read embedded
  /// JSON payloads such as Next.js `__NEXT_DATA__`.
  String? scriptContent(String id) {
    final element = document.querySelector('script#$id');
    return element?.text;
  }

  /// Collects all hyperlinks on the page, resolved against [baseUrl] and
  /// normalized. Non-HTTP links (mailto, javascript, anchors) are dropped.
  List<String> links(String baseUrl) {
    final base = Uri.tryParse(baseUrl);
    if (base == null) return const [];

    final found = <String>{};
    for (final anchor in document.querySelectorAll('a[href]')) {
      final href = anchor.attributes['href']?.trim() ?? '';
      if (href.isEmpty ||
          href.startsWith('#') ||
          href.startsWith('mailto:') ||
          href.startsWith('tel:') ||
          href.startsWith('javascript:')) {
        continue;
      }
      final resolved = base.resolve(href).toString();
      final normalized = Normalizer.normalizeUrl(resolved);
      if (normalized.isNotEmpty) found.add(normalized);
    }
    return found.toList();
  }
}
