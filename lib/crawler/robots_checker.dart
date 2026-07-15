import 'package:http/http.dart' as http;
import '../utils/normalizer.dart';

class RobotsChecker {
  final Map<String, List<RegExp>> _disallowedRulesCache = {};
  final String userAgent;

  RobotsChecker({this.userAgent = 'GovSchemeDbBuilder'});

  /// Resolves the host's robots.txt rules and verifies if crawling the path is allowed.
  Future<bool> canCrawl(String url) async {
    try {
      final uri = Uri.parse(Normalizer.normalizeUrl(url));
      final rootUrl = '${uri.scheme}://${uri.host}';

      if (!_disallowedRulesCache.containsKey(rootUrl)) {
        await _fetchAndParseRobotsTxt(rootUrl);
      }

      final rules = _disallowedRulesCache[rootUrl] ?? [];
      final path = uri.path + (uri.hasQuery ? '?${uri.query}' : '');

      for (var rule in rules) {
        if (rule.hasMatch(path)) {
          return false; // Crawling this path is disallowed
        }
      }
      return true;
    } catch (_) {
      // Default to true (lenient) if URL parsing or fetch fails entirely
      return true;
    }
  }

  Future<void> _fetchAndParseRobotsTxt(String rootUrl) async {
    final rules = <RegExp>[];
    _disallowedRulesCache[rootUrl] = rules;

    try {
      final response = await http
          .get(Uri.parse('$rootUrl/robots.txt'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return;

      final lines = response.body.split('\n');
      bool appliesToUs = false;

      for (var line in lines) {
        final cleanLine = line.trim();
        if (cleanLine.isEmpty || cleanLine.startsWith('#')) continue;

        final parts = cleanLine.split(':');
        if (parts.length < 2) continue;

        final key = parts[0].trim().toLowerCase();
        final value = parts.sublist(1).join(':').trim();

        if (key == 'user-agent') {
          appliesToUs =
              (value == '*' || value.toLowerCase() == userAgent.toLowerCase());
        } else if (appliesToUs && key == 'disallow') {
          if (value.isEmpty) continue;
          // Convert glob pattern rules to Dart RegExp
          final escapedRule = RegExp.escape(
            value,
          ).replaceAll(r'\*', '.*').replaceAll(r'\?', '.?');
          rules.add(RegExp('^$escapedRule'));
        }
      }
    } catch (_) {
      // Suppress network errors during robots.txt retrieval
    }
  }
}
