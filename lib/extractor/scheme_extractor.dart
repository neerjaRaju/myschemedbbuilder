import 'dart:convert';

import '../models/scheme.dart';
import '../utils/crypto_utils.dart';
import '../utils/normalizer.dart';
import 'html_parser.dart';

/// Extracts [Scheme] records from downloaded pages.
///
/// Two strategies are attempted in order:
///
/// 1. Embedded JSON — MyScheme is a Next.js site whose pages embed their
///    data in a `__NEXT_DATA__` script tag; when a populated payload is
///    present it is far more reliable than CSS selectors.
/// 2. CSS selectors — a broad selector profile covering the markup used by
///    india.gov.in and common state portal templates.
///
/// Fields that cannot be found are left empty; the validator later rejects
/// records without meaningful content, so no fabricated values ever enter
/// the dataset.
class SchemeExtractor {
  SchemeExtractor._();

  /// Extracts a fully formed [Scheme] from a raw HTML string.
  static Scheme extract({
    required String html,
    required String sourceUrl,
    required String defaultState,
    required String defaultMinistry,
  }) {
    final parser = HtmlParser(html);
    final normalizedUrl = Normalizer.normalizeUrl(sourceUrl);

    final fromJson = _extractFromNextData(parser);

    final title =
        fromJson?['title'] ?? parser.selectText('h1, .scheme-title, #scheme-name');
    final description = fromJson?['description'] ??
        parser.selectText(
          'div.description, .scheme-details, p.about-scheme',
          fallback: parser.selectAttribute(
                'meta[name="description"]',
                'content',
              ) ??
              '',
        );
    final benefits = fromJson?['benefits'] ??
        parser.selectText('div.benefits, #benefits, .scheme-benefits');
    final eligibility = fromJson?['eligibility'] ??
        parser.selectText('div.eligibility, #eligibility, .scheme-eligibility');
    final applicationProcess = fromJson?['applicationProcess'] ??
        parser.selectText(
          'div.application-process, #how-to-apply, .apply-steps',
        );
    final ministry = fromJson?['ministry'] ??
        parser.selectText(
          '.ministry-name, span.ministry, div.authority',
          fallback: defaultMinistry,
        );
    final category = fromJson?['category'] ??
        parser.selectText('.scheme-category, .category-badge, a.category');
    final state = fromJson?['state'] ??
        parser.selectText('.state-name, span.state', fallback: defaultState);

    final documents = fromJson != null && fromJson['documents'] != null
        ? (fromJson['documents'] as String)
            .split('\n')
            .where((d) => d.trim().isNotEmpty)
            .toList()
        : parser.selectList(
            'div.documents li, ul.required-docs li, .documents-list li',
          );

    final tags = fromJson != null && fromJson['tags'] != null
        ? (fromJson['tags'] as String)
            .split('\n')
            .where((t) => t.trim().isNotEmpty)
            .toList()
        : parser.selectList('.tag, .badge, .keywords li');

    final faq = _extractFaq(parser, fromJson);

    final helpline = Normalizer.normalizeHelpline(
      parser.selectText('.helpline, .toll-free, a[href^="tel:"]'),
    );

    final lastUpdated = Normalizer.normalizeDate(
      parser.selectText('.last-updated, .updated-on, time'),
    );

    final department =
        parser.selectText('.department-name, span.department');

    // Deterministic ID derived from the normalized URL.
    final id = sha256Hash(normalizedUrl).substring(0, 16);

    return Scheme(
      id: id,
      title: Normalizer.sanitizeText(title),
      description: Normalizer.sanitizeText(description),
      benefits: Normalizer.sanitizeText(benefits),
      eligibility: Normalizer.sanitizeText(eligibility),
      requiredDocuments: documents.map(Normalizer.sanitizeText).toList(),
      applicationProcess: Normalizer.sanitizeText(applicationProcess),
      ministry: Normalizer.sanitizeText(
        ministry.isEmpty ? defaultMinistry : ministry,
      ),
      department: department,
      category: Normalizer.sanitizeText(category),
      tags: tags.map(Normalizer.sanitizeText).toList(),
      state: Normalizer.sanitizeText(state.isEmpty ? defaultState : state),
      officialUrl: normalizedUrl,
      helpline: helpline,
      faq: faq,
      lastUpdated: lastUpdated,
    );
  }

  /// Reads a populated Next.js `__NEXT_DATA__` payload when present.
  static Map<String, String?>? _extractFromNextData(HtmlParser parser) {
    final raw = parser.scriptContent('__NEXT_DATA__');
    if (raw == null || raw.trim().isEmpty) return null;

    Object? decoded;
    try {
      decoded = json.decode(raw);
    } on FormatException {
      return null;
    }

    return _fieldsFromSchemeData(
      _dig(decoded, ['props', 'pageProps', 'schemeData']),
    );
  }

  /// Builds a [Scheme] from a MyScheme API detail response
  /// (`/schemes/v5/public/schemes?slug=...`). Returns `null` when the
  /// payload carries no scheme (missing or empty title).
  ///
  /// The API payload nests the same structure the website embeds in
  /// `__NEXT_DATA__`, so both paths share [_fieldsFromSchemeData].
  static Scheme? fromApiJson(
    Object? apiResponse, {
    required String slug,
    required String defaultState,
    required String defaultMinistry,
  }) {
    final fields = _fieldsFromSchemeData(_dig(apiResponse, ['data']) ??
        _dig(apiResponse, ['data', 'schemeData']));
    if (fields == null) return null;

    final normalizedUrl =
        Normalizer.normalizeUrl('https://www.myscheme.gov.in/schemes/$slug');
    final id = sha256Hash(normalizedUrl).substring(0, 16);

    Map<String, String> faq;
    try {
      faq = Map<String, String>.from(
        json.decode(fields['faq'] ?? '{}') as Map,
      );
    } on FormatException {
      faq = const {};
    }

    List<String> split(String? value) => (value ?? '')
        .split('\n')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    final ministry = fields['ministry'] ?? '';
    final state = fields['state'] ?? '';

    return Scheme(
      id: id,
      title: fields['title'] ?? '',
      description: fields['description'] ?? '',
      benefits: fields['benefits'] ?? '',
      eligibility: fields['eligibility'] ?? '',
      requiredDocuments: split(fields['documents']),
      applicationProcess: fields['applicationProcess'] ?? '',
      ministry: ministry.isEmpty ? defaultMinistry : ministry,
      department: '',
      category: fields['category'] ?? '',
      tags: split(fields['tags']),
      state: state.isEmpty ? defaultState : state,
      officialUrl: normalizedUrl,
      helpline: '',
      faq: faq,
      lastUpdated: '',
    );
  }

  /// Maps a decoded `schemeData`-shaped payload (as found in both
  /// `__NEXT_DATA__` and API detail responses) to normalized field values.
  static Map<String, String?>? _fieldsFromSchemeData(Object? schemeData) {
    final localized = _dig(schemeData, ['en']) ?? schemeData;
    if (localized is! Map) return null;

    final basic = _dig(localized, ['basicDetails']);
    final content = _dig(localized, ['schemeContent']);
    final eligibility = _dig(localized, ['eligibilityCriteria']);

    final title = _plainText(_dig(basic, ['schemeName']));
    if (title.isEmpty) return null;

    final documents = _plainText(
      _dig(localized, ['applicationProcess', 0, 'requiredDocuments']) ??
          _dig(content, ['requiredDocuments']),
    );

    return {
      'title': title,
      'description': _firstNonEmpty([
        _plainText(_dig(content, ['detailedDescription_md'])),
        _plainText(_dig(content, ['detailedDescription'])),
        _plainText(_dig(basic, ['briefDescription'])),
      ]),
      'benefits': _firstNonEmpty([
        _plainText(_dig(content, ['benefits_md'])),
        _plainText(_dig(content, ['benefits'])),
      ]),
      'eligibility': _firstNonEmpty([
        _plainText(_dig(eligibility, ['eligibilityDescription_md'])),
        _plainText(_dig(eligibility, ['eligibilityDescription'])),
      ]),
      'applicationProcess': _plainText(
        _dig(localized, ['applicationProcess', 0, 'process']),
      ),
      'ministry': _firstNonEmpty([
        _plainText(_dig(basic, ['nodalMinistryName', 'label'])),
        _plainText(_dig(basic, ['nodalMinistryName'])),
      ]),
      'category': _plainText(_dig(basic, ['schemeCategory', 0])),
      'state': _firstNonEmpty([
        _plainText(_dig(basic, ['state', 'label'])),
        _plainText(_dig(basic, ['state'])),
      ]),
      'tags': _stringList(_dig(basic, ['tags'])).join('\n'),
      'documents': documents,
      'faq': json.encode(_faqPairs(_dig(localized, ['faqs']))),
    };
  }

  static Map<String, String> _extractFaq(
    HtmlParser parser,
    Map<String, String?>? fromJson,
  ) {
    final encoded = fromJson?['faq'];
    if (encoded != null && encoded.isNotEmpty && encoded != '{}') {
      try {
        return Map<String, String>.from(json.decode(encoded) as Map);
      } on FormatException {
        // Fall through to selector-based extraction.
      }
    }

    final faq = <String, String>{};
    final questions = parser.selectList('.faq-question, dt.question');
    final answers = parser.selectList('.faq-answer, dd.answer');
    for (var i = 0; i < questions.length && i < answers.length; i++) {
      faq[questions[i]] = answers[i];
    }
    return faq;
  }

  static Map<String, String> _faqPairs(Object? value) {
    final result = <String, String>{};
    if (value is List) {
      for (final item in value) {
        if (item is Map) {
          final question = _plainText(item['question']);
          final answer = _plainText(item['answer']);
          if (question.isNotEmpty && answer.isNotEmpty) {
            result[question] = answer;
          }
        }
      }
    }
    return result;
  }

  /// Walks a decoded JSON structure by map keys and list indexes, returning
  /// `null` whenever a step is missing.
  static Object? _dig(Object? node, List<Object> path) {
    var current = node;
    for (final step in path) {
      if (current is Map && step is String) {
        current = current[step];
      } else if (current is List && step is int && step < current.length) {
        current = current[step];
      } else {
        return null;
      }
    }
    return current;
  }

  /// Flattens strings, numbers and Slate-style rich-text trees
  /// (`[{children: [{text: ...}]}]`) into normalized plain text.
  static String _plainText(Object? value) {
    if (value == null) return '';
    if (value is String) return Normalizer.sanitizeText(value);
    if (value is num || value is bool) return '$value';

    final buffer = StringBuffer();
    void walk(Object? node) {
      if (node is String) {
        buffer
          ..write(node)
          ..write(' ');
      } else if (node is Map) {
        if (node['text'] is String) {
          buffer
            ..write(node['text'])
            ..write(' ');
        }
        walk(node['children']);
      } else if (node is List) {
        node.forEach(walk);
      }
    }

    walk(value);
    return Normalizer.sanitizeText(buffer.toString());
  }

  static List<String> _stringList(Object? value) {
    if (value is! List) return const [];
    return value
        .map(_plainText)
        .where((item) => item.isNotEmpty)
        .toList();
  }

  static String _firstNonEmpty(List<String> candidates) {
    for (final candidate in candidates) {
      if (candidate.isNotEmpty) return candidate;
    }
    return '';
  }
}
