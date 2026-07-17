import 'dart:convert';

import '../models/scheme.dart';
import '../utils/crypto_utils.dart';
import '../utils/normalizer.dart';

/// Builds [Scheme] records from MyScheme API detail payloads
/// (`/schemes/v5/public/schemes?slug=...`).
///
/// Fields that cannot be found are left empty; the validator later rejects
/// records without meaningful content, so no fabricated values ever enter
/// the dataset.
class SchemeExtractor {
  SchemeExtractor._();

  /// Builds a [Scheme] from a decoded API detail response. Returns `null`
  /// when the payload carries no scheme (missing or empty title).
  static Scheme? fromApiJson(
    Object? apiResponse, {
    required String slug,
    required String defaultState,
    required String defaultMinistry,
  }) {
    final fields = _fieldsFromSchemeData(
      _dig(apiResponse, ['data']) ?? _dig(apiResponse, ['data', 'schemeData']),
    );
    if (fields == null) return null;

    final normalizedUrl = Normalizer.normalizeUrl(
      'https://www.myscheme.gov.in/schemes/$slug',
    );
    final id = sha256Hash(normalizedUrl).substring(0, 16);

    Map<String, String> faq;
    try {
      faq = Map<String, String>.from(json.decode(fields['faq'] ?? '{}') as Map);
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

  /// Maps a decoded `schemeData`-shaped payload to normalized field values.
  static Map<String, String?>? _fieldsFromSchemeData(Object? schemeData) {
    final localized = _dig(schemeData, ['en']) ?? schemeData;
    if (localized is! Map) return null;

    final basic = _dig(localized, ['basicDetails']);
    final content = _dig(localized, ['schemeContent']);
    final eligibility = _dig(localized, ['eligibilityCriteria']);

    final title = _plainText(_dig(basic, ['schemeName']));
    if (title.isEmpty) return null;

    final documents = _multilineText(
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

  /// Like [_plainText] but preserves item boundaries as newlines, for
  /// values that represent lists (e.g. required documents).
  static String _multilineText(Object? value) {
    if (value == null) return '';
    if (value is String) {
      return value
          .split('\n')
          .map(Normalizer.sanitizeText)
          .where((line) => line.isNotEmpty)
          .join('\n');
    }
    if (value is List) {
      return value.map(_plainText).where((line) => line.isNotEmpty).join('\n');
    }
    return _plainText(value);
  }

  static List<String> _stringList(Object? value) {
    if (value is! List) return const [];
    return value.map(_plainText).where((item) => item.isNotEmpty).toList();
  }

  static String _firstNonEmpty(List<String> candidates) {
    for (final candidate in candidates) {
      if (candidate.isNotEmpty) return candidate;
    }
    return '';
  }
}
