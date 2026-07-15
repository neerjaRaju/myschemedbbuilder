class Scheme {
  final String id;
  final String title;
  final String ministry;
  final String category;
  final String state;
  final String description;
  final List<String> benefits;
  final List<String> eligibility;
  final List<String> documents;
  final String applicationProcess;
  final String officialUrl;
  final String helpline;
  final DateTime? lastUpdated;

  Scheme({
    required this.id,
    required this.title,
    required this.ministry,
    required this.category,
    required this.state,
    required this.description,
    required this.benefits,
    required this.eligibility,
    required this.documents,
    required this.applicationProcess,
    required this.officialUrl,
    required this.helpline,
    this.lastUpdated,
  });

  factory Scheme.fromJson(Map<String, dynamic> json) {
    return Scheme(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      ministry: json['ministry'] ?? '',
      category: json['category'] ?? '',
      state: json['state'] ?? '',
      description: json['description'] ?? '',
      benefits: List<String>.from(json['benefits'] ?? []),
      eligibility: List<String>.from(json['eligibility'] ?? []),
      documents: List<String>.from(json['documents'] ?? []),
      applicationProcess: json['applicationProcess'] ?? '',
      officialUrl: json['officialUrl'] ?? '',
      helpline: json['helpline'] ?? '',
      lastUpdated: json['lastUpdated'] == null
          ? null
          : DateTime.tryParse(json['lastUpdated']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'ministry': ministry,
      'category': category,
      'state': state,
      'description': description,
      'benefits': benefits,
      'eligibility': eligibility,
      'documents': documents,
      'applicationProcess': applicationProcess,
      'officialUrl': officialUrl,
      'helpline': helpline,
      'lastUpdated': lastUpdated?.toIso8601String(),
    };
  }

  Map<String, dynamic> toDbMap() {
    return {
      'id': id,
      'title': title,
      'ministry': ministry,
      'category': category,
      'state': state,
      'description': description,
      'benefits': benefits.join('|'),
      'eligibility': eligibility.join('|'),
      'documents': documents.join('|'),
      'application_process': applicationProcess,
      'official_url': officialUrl,
      'helpline': helpline,
      'last_updated': lastUpdated?.toIso8601String(),
    };
  }

  factory Scheme.fromDbMap(Map<String, Object?> map) {
    return Scheme(
      id: map['id'] as String,
      title: map['title'] as String,
      ministry: map['ministry'] as String,
      category: map['category'] as String,
      state: map['state'] as String,
      description: map['description'] as String,
      benefits: (map['benefits'] as String?)?.split('|') ?? [],
      eligibility: (map['eligibility'] as String?)?.split('|') ?? [],
      documents: (map['documents'] as String?)?.split('|') ?? [],
      applicationProcess: map['application_process'] as String? ?? '',
      officialUrl: map['official_url'] as String? ?? '',
      helpline: map['helpline'] as String? ?? '',
      lastUpdated: map['last_updated'] == null
          ? null
          : DateTime.tryParse(map['last_updated'] as String),
    );
  }

  @override
  String toString() => title;
}