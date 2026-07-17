import '../logic/categories.dart';
import '../logic/filters.dart';
import '../models/scheme.dart';
import 'database_service.dart';

/// All read queries against the offline schemes database.
class SchemeRepository {
  final DatabaseService _dbService;

  SchemeRepository(this._dbService);

  static const String _columns = 'id, title, description, benefits, '
      'eligibility, documents, application_process, ministry, department, '
      'category, tags, state, official_url, helpline, faq, last_updated';

  List<Scheme> _query(String sql, [List<Object?> args = const []]) {
    final rows = _dbService.db.select(sql, args);
    return [for (final row in rows) Scheme.fromRow(Map.of(row))];
  }

  int count() =>
      _dbService.db.select('SELECT COUNT(*) c FROM schemes').first['c'] as int;

  List<String> allIds() => [
        for (final row in _dbService.db.select('SELECT id FROM schemes'))
          row['id'] as String,
      ];

  /// Distinct state names (excluding central) for filter dropdowns.
  List<String> states() => [
        for (final row in _dbService.db.select(
          "SELECT DISTINCT state FROM schemes "
          "WHERE state NOT IN ('', 'Central', 'All India') ORDER BY state",
        ))
          row['state'] as String,
      ];

  Scheme? byId(String id) {
    final result = _query('SELECT $_columns FROM schemes WHERE id = ?', [id]);
    return result.isEmpty ? null : result.first;
  }

  List<Scheme> byIds(List<String> ids) {
    if (ids.isEmpty) return const [];
    final placeholders = List.filled(ids.length, '?').join(',');
    return _query(
      'SELECT $_columns FROM schemes WHERE id IN ($placeholders)',
      ids,
    );
  }

  /// Flagship national schemes shown in the "Featured" rail; falls back to
  /// the richest records when none of the well-known slugs are present.
  List<Scheme> featured({int limit = 10}) {
    const flagshipSlugs = [
      'pm-kisan',
      'pmjay',
      'pmay-g',
      'pmayu',
      'pmsym',
      'pmfby',
      'pmjjby',
      'pmsby',
      'apy',
      'pmegp',
      'nsp',
      'pmuy',
    ];
    final placeholders = flagshipSlugs
        .map((s) => "official_url LIKE '%/schemes/' || ?")
        .toList();
    final known = _query(
      'SELECT $_columns FROM schemes WHERE ${placeholders.join(' OR ')} '
      'LIMIT ?',
      [...flagshipSlugs, limit],
    );
    if (known.length >= 5) return known;
    return _query(
      'SELECT $_columns FROM schemes '
      'ORDER BY LENGTH(benefits) + LENGTH(description) DESC LIMIT ?',
      [limit],
    );
  }

  /// Most recently updated schemes. The builder stores ISO dates when the
  /// source provides them; otherwise the newest rows serve as "recent".
  List<Scheme> recentlyUpdated({int limit = 10}) {
    final dated = _query(
      "SELECT $_columns FROM schemes WHERE last_updated != '' "
      'ORDER BY last_updated DESC LIMIT ?',
      [limit],
    );
    if (dated.isNotEmpty) return dated;
    return _query(
      'SELECT $_columns FROM schemes ORDER BY rowid DESC LIMIT ?',
      [limit],
    );
  }

  /// Daily-rotating selection so the rail changes every day but stays
  /// stable within a day (deterministic, seeded by the date).
  List<Scheme> trending({int limit = 10, DateTime? now}) {
    final date = now ?? DateTime.now();
    final seed = date.year * 10000 + date.month * 100 + date.day;
    return _query(
      'SELECT $_columns FROM schemes '
      'ORDER BY (rowid * 2654435761 + ?) % 4294967296 LIMIT ?',
      [seed, limit],
    );
  }

  /// Schemes matching one of the home categories.
  List<Scheme> byCategory(SchemeCategory category, {int limit = 200}) {
    final clauses = <String>[];
    final args = <Object?>[];
    for (final keyword in category.keywords) {
      clauses.add(
        '(category LIKE ? OR tags LIKE ? OR title LIKE ? OR description LIKE ?)',
      );
      final like = '%$keyword%';
      args.addAll([like, like, like, like]);
    }
    args.add(limit);
    return _query(
      'SELECT $_columns FROM schemes WHERE ${clauses.join(' OR ')} '
      'ORDER BY title LIMIT ?',
      args,
    );
  }

  /// Full-text search across title, description, benefits, eligibility,
  /// ministry, category, state and tags, ranked by relevance.
  List<Scheme> search(String query, {int limit = 100}) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];

    // Quote each term so user punctuation cannot break FTS syntax.
    final ftsQuery = trimmed
        .split(RegExp(r'\s+'))
        .map((term) => '"${term.replaceAll('"', '')}"*')
        .join(' ');
    try {
      return _query(
        'SELECT ${_columns.split(', ').map((c) => 's.$c').join(', ')} '
        'FROM schemes s JOIN schemes_fts f ON f.id = s.id '
        'WHERE schemes_fts MATCH ? ORDER BY rank LIMIT ?',
        [ftsQuery, limit],
      );
    } on Object {
      final like = '%$trimmed%';
      return _query(
        'SELECT $_columns FROM schemes '
        'WHERE title LIKE ? OR ministry LIKE ? OR description LIKE ? '
        'OR benefits LIKE ? ORDER BY title LIMIT ?',
        [like, like, like, like, limit],
      );
    }
  }

  /// Applies [filters] in Dart on top of a candidate list (eligibility text
  /// is unstructured, so structured SQL filtering is not possible).
  List<Scheme> applyFilters(List<Scheme> candidates, SmartFilters filters) {
    if (filters.isEmpty) return candidates;
    return candidates.where(filters.matches).toList();
  }

  /// Schemes similar to [scheme]: same category/ministry, then shared tags.
  List<Scheme> related(Scheme scheme, {int limit = 6}) {
    final results = _query(
      'SELECT $_columns FROM schemes '
      'WHERE id != ? AND (category = ? OR ministry = ?) '
      'ORDER BY (category = ?) DESC, title LIMIT ?',
      [scheme.id, scheme.category, scheme.ministry, scheme.category, limit],
    );
    if (results.isNotEmpty || scheme.tags.isEmpty) return results;
    final like = '%${scheme.tags.first}%';
    return _query(
      'SELECT $_columns FROM schemes WHERE id != ? AND tags LIKE ? '
      'ORDER BY title LIMIT ?',
      [scheme.id, like, limit],
    );
  }
}
