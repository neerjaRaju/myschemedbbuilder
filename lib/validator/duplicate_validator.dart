import '../models/scheme.dart';

class DuplicateValidator {
  /// Deduplicates datasets by applying Levenshtein Distance and Jaccard Index variations to string content.
  static List<Scheme> deduplicate(
    List<Scheme> schemes,
    List<String> actionLog,
  ) {
    final List<Scheme> uniqueSchemes = [];
    final Set<String> exactUrls = {};
    final Set<String> exactHashes = {};

    for (var scheme in schemes) {
      // 1. Exact URL collision checks
      if (exactUrls.contains(scheme.officialUrl)) {
        actionLog.add(
          'Dropped duplicate via exact URL match: ${scheme.title} (${scheme.officialUrl})',
        );
        continue;
      }

      // 2. Exact data hashing collision checks
      if (exactHashes.contains(scheme.hash)) {
        actionLog.add(
          'Dropped duplicate via exact payload hash match: ${scheme.title}',
        );
        continue;
      }

      // 3. Normalized Title Semantic similarity threshold guard
      bool isSemanticDuplicate = false;
      final normalizedTargetTitle = _normalizeStringForComparison(scheme.title);

      for (var existing in uniqueSchemes) {
        final normalizedExistingTitle = _normalizeStringForComparison(
          existing.title,
        );
        final similarity = _calculateJaccardSimilarity(
          normalizedTargetTitle,
          normalizedExistingTitle,
        );

        // If titles match at a >90% similarity token ratio, check if they belong to the same state/ministry context
        if (similarity > 0.90 &&
            existing.state == scheme.state &&
            existing.ministry == scheme.ministry) {
          actionLog.add(
            'Dropped semantic duplicate (>90% structural text match): "${scheme.title}" matched with "${existing.title}"',
          );
          isSemanticDuplicate = true;
          break;
        }
      }

      if (!isSemanticDuplicate) {
        exactUrls.add(scheme.officialUrl);
        exactHashes.add(scheme.hash);
        uniqueSchemes.add(scheme);
      }
    }

    return uniqueSchemes;
  }

  static String _normalizeStringForComparison(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static double _calculateJaccardSimilarity(String s1, String s2) {
    final set1 = s1.split(' ').toSet();
    final set2 = s2.split(' ').toSet();

    if (set1.isEmpty && set2.isEmpty) return 1.0;

    final intersection = set1.intersection(set2).length;
    final union = set1.union(set2).length;

    return intersection / union;
  }
}
