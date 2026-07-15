import '../models/scheme.dart';

class Normalizer {
  const Normalizer();

  Scheme normalize(Scheme scheme) {
    return Scheme(
      id: scheme.id.trim().toUpperCase(),
      title: scheme.title.trim(),
      ministry: scheme.ministry.trim(),
      category: scheme.category.trim(),
      state: scheme.state.trim(),
      description: scheme.description.trim(),
      benefits: scheme.benefits.map((e) => e.trim()).toList(),
      eligibility: scheme.eligibility.map((e) => e.trim()).toList(),
      documents: scheme.documents.map((e) => e.trim()).toList(),
      applicationProcess: scheme.applicationProcess.trim(),
      officialUrl: scheme.officialUrl.trim(),
      helpline: scheme.helpline.trim(),
      lastUpdated: scheme.lastUpdated,
    );
  }
}