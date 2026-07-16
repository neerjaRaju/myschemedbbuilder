import '../utils/crypto_utils.dart';

/// Immutable data model for one government scheme.
///
/// The [hash] fingerprints the record's content (URL, title, description)
/// and drives duplicate detection and incremental database sync.
class Scheme {
  final String id;
  final String title;
  final String description;
  final String benefits;
  final String eligibility;
  final List<String> requiredDocuments;
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
  final String hash;

  Scheme({
    required this.id,
    required this.title,
    required this.description,
    required this.benefits,
    required this.eligibility,
    required this.requiredDocuments,
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
    String? hash,
  }) : hash = hash ?? _computeHash(officialUrl, title, description);

  static String _computeHash(String url, String title, String desc) {
    final payload = '$url|$title|$desc';
    return sha256Hash(
      payload,
    ); // Implement standard crypto SHA-256 string helper
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'benefits': benefits,
      'eligibility': eligibility,
      'required_documents': requiredDocuments,
      'application_process': applicationProcess,
      'ministry': ministry,
      'department': department,
      'category': category,
      'tags': tags,
      'state': state,
      'official_url': officialUrl,
      'helpline': helpline,
      'faq': faq,
      'last_updated': lastUpdated,
      'hash': hash,
    };
  }

  factory Scheme.fromJson(Map<String, dynamic> json) {
    return Scheme(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      benefits: json['benefits'] as String,
      eligibility: json['eligibility'] as String,
      requiredDocuments: List<String>.from(
        json['required_documents'] as Iterable,
      ),
      applicationProcess: json['application_process'] as String,
      ministry: json['ministry'] as String,
      department: json['department'] as String,
      category: json['category'] as String,
      tags: List<String>.from(json['tags'] as Iterable),
      state: json['state'] as String,
      officialUrl: json['official_url'] as String,
      helpline: json['helpline'] as String,
      faq: Map<String, String>.from(json['faq'] as Map),
      lastUpdated: json['last_updated'] as String,
      hash: json['hash'] as String,
    );
  }
}
