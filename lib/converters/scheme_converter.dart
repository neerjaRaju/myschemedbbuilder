import '../models/scheme.dart';

class SchemeConverter {
  const SchemeConverter();

  /// Convert a source-specific JSON object into the canonical Scheme model.
  /// Adjust the field mappings for each source.
  Scheme fromMap(Map<String, dynamic> map) {
    return Scheme(
      id: (map['id'] ?? '').toString(),
      title: (map['title'] ?? map['scheme_name'] ?? '').toString(),
      ministry: (map['ministry'] ?? '').toString(),
      category: (map['category'] ?? 'General').toString(),
      state: (map['state'] ?? 'All India').toString(),
      description: (map['description'] ?? '').toString(),
      benefits: List<String>.from(map['benefits'] ?? const []),
      eligibility: List<String>.from(map['eligibility'] ?? const []),
      documents: List<String>.from(map['documents'] ?? const []),
      applicationProcess:
          (map['applicationProcess'] ?? '').toString(),
      officialUrl: (map['officialUrl'] ?? '').toString(),
      helpline: (map['helpline'] ?? '').toString(),
      lastUpdated: DateTime.tryParse(
        (map['lastUpdated'] ?? '').toString(),
      ),
    );
  }
}