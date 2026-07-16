import 'package:http/http.dart' as http;

import '../utils/constants.dart';
import '../utils/normalizer.dart';

/// Fetches and evaluates `robots.txt` rules per host.
///
/// Rules are cached per host for the lifetime of the checker, so each host's
/// `robots.txt` is fetched at most once per crawl.
class RobotsChecker {
  final Map<String, List<RegExp>> _disallowedRulesCache = {};
  final String userAgent;
  final http.Client _client;

  RobotsChecker({this.userAgent = kUserAgent, http.Client? client})
      : _client = client ?? http.Client();

  /// Returns `true` when crawling [url] is permitted by the host's
  /// `robots.txt`. Missing or unreachable robots files are treated leniently.
  Future<bool> canCrawl(String url) async {
    try {
      final uri = Uri.parse(Normalizer.normalizeUrl(url));
      final rootUrl = '${uri.scheme}://${uri.host}';

      final rules = _disallowedRulesCache[rootUrl] ??
          await _fetchAndParseRobotsTxt(rootUrl);
      final path = uri.path + (uri.hasQuery ? '?${uri.query}' : '');

      return !rules.any((rule) => rule.hasMatch(path));
    } catch (_) {
      // Default to lenient when URL parsing or the fetch fails entirely.
      return true;
    }
  }

  Future<List<RegExp>> _fetchAndParseRobotsTxt(String rootUrl) async {
    var rules = <RegExp>[];
    try {
      final response = await _client
          .get(Uri.parse('$rootUrl/robots.txt'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        rules = parseDisallowRules(response.body, userAgent);
      }
    } catch (_) {
      // Unreachable robots.txt: treat as allow-all.
    }
    _disallowedRulesCache[rootUrl] = rules;
    return rules;
  }

  /// Parses `Disallow` rules that apply to [userAgent] from a raw
  /// `robots.txt` [content] string. Exposed for unit testing.
  static List<RegExp> parseDisallowRules(String content, String userAgent) {
    final rules = <RegExp>[];
    final agentToken = userAgent.split('/').first.toLowerCase();
    var appliesToUs = false;

    for (final line in content.split('\n')) {
      final cleanLine = line.trim();
      if (cleanLine.isEmpty || cleanLine.startsWith('#')) continue;

      final separator = cleanLine.indexOf(':');
      if (separator < 0) continue;

      final key = cleanLine.substring(0, separator).trim().toLowerCase();
      final value = cleanLine.substring(separator + 1).trim();

      if (key == 'user-agent') {
        final agent = value.toLowerCase();
        appliesToUs = agent == '*' ||
            agent == agentToken ||
            agent == userAgent.toLowerCase();
      } else if (appliesToUs && key == 'disallow' && value.isNotEmpty) {
        // Convert glob pattern rules to RegExp.
        final escapedRule =
            RegExp.escape(value).replaceAll(r'\*', '.*').replaceAll(r'\$', r'$');
        rules.add(RegExp('^$escapedRule'));
      }
    }
    return rules;
  }

  /// Releases the underlying HTTP client.
  void close() => _client.close();
}
