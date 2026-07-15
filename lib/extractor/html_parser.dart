import 'package:html/dom.dart';
import 'package:html/parser.dart' show parse;
import '../utils/normalizer.dart';

class HtmlParser {
  final Document document;

  HtmlParser(String htmlContent) : document = parse(htmlContent);

  /// Selects a single element's text safely and normalizes it.
  String selectText(String selector, {String fallback = ''}) {
    final element = document.querySelector(selector);
    if (element == null) return fallback;
    return Normalizer.sanitizeText(element.text);
  }

  /// Selects all text from elements matching a selector and joins them.
  String selectTextJoined(String selector, {String separator = '\n'}) {
    final elements = document.querySelectorAll(selector);
    return elements
        .map((el) => Normalizer.sanitizeText(el.text))
        .where((text) => text.isNotEmpty)
        .join(separator);
  }

  /// Extracts structured list elements (e.g., inside <ul>, <ol> or custom classes) into a clean list of strings.
  List<String> selectList(String selector) {
    final elements = document.querySelectorAll(selector);
    return elements
        .map((el) => Normalizer.sanitizeText(el.text))
        .where((text) => text.isNotEmpty)
        .toList();
  }

  /// Safely extracts attribute values from a specific tag matching a CSS selector.
  String? selectAttribute(String selector, String attribute) {
    final element = document.querySelector(selector);
    return element?.attributes[attribute];
  }
}
