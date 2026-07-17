import 'dart:convert';

/// One government scheme, as stored in `schemes.db`.
class Scheme {
  final String id;
  final String title;
  final String description;
  final String benefits;
  final String eligibility;
  final List<String> documents;
  final String applicationProcess;
  final String ministry;
  final String department;
  final String category;
  final List<String> tags;
  final String state;
  final String officialUrl;
  final String helpline;
  final Map<String, String> faq;
  final String lastUpdated;

  const Scheme({
    required this.id,
    required this.title,
    required this.description,
    required this.benefits,
    required this.eligibility,
    required this.documents,
    required this.applicationProcess,
    required this.ministry,
    required this.department,
    required this.category,
    required this.tags,
    required this.state,
    required this.officialUrl,
    required this.helpline,
    required this.faq,
    required this.lastUpdated,
  });

  /// Whether this is a central (all-India) scheme rather than a state one.
  bool get isCentral =>
      state.isEmpty || state.toLowerCase() == 'central' || state == 'All India';

  factory Scheme.fromRow(Map<String, Object?> row) {
    List<String> stringList(Object? value) {
      if (value is! String || value.isEmpty) return const [];
      try {
        final decoded = json.decode(value);
        if (decoded is List) {
          return decoded.map((e) => '$e').toList();
        }
      } on FormatException {
        // Fall through to newline splitting.
      }
      return value
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    Map<String, String> stringMap(Object? value) {
      if (value is! String || value.isEmpty) return const {};
      try {
        final decoded = json.decode(value);
        if (decoded is Map) {
          return decoded.map((k, v) => MapEntry('$k', '$v'));
        }
      } on FormatException {
        // Ignore malformed FAQ payloads.
      }
      return const {};
    }

    return Scheme(
      id: row['id'] as String? ?? '',
      title: row['title'] as String? ?? '',
      description: row['description'] as String? ?? '',
      benefits: row['benefits'] as String? ?? '',
      eligibility: row['eligibility'] as String? ?? '',
      documents: stringList(row['documents']),
      applicationProcess: row['application_process'] as String? ?? '',
      ministry: row['ministry'] as String? ?? '',
      department: row['department'] as String? ?? '',
      category: row['category'] as String? ?? '',
      tags: stringList(row['tags']),
      state: row['state'] as String? ?? '',
      officialUrl: row['official_url'] as String? ?? '',
      helpline: row['helpline'] as String? ?? '',
      faq: stringMap(row['faq']),
      lastUpdated: row['last_updated'] as String? ?? '',
    );
  }

  /// Text blob used by keyword-based matching (filters, eligibility).
  String get searchBlob =>
      '$title $description $benefits $eligibility $category '
              '${tags.join(' ')} $ministry'
          .toLowerCase();
}
