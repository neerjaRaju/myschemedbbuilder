import 'package:government_scheme_db_builder/crawler/robots_checker.dart';
import 'package:test/test.dart';

void main() {
  group('RobotsChecker.parseDisallowRules', () {
    const robots = '''
# Sample robots file
User-agent: *
Disallow: /admin
Disallow: /private/*

User-agent: SpecialBot
Disallow: /special
''';

    test('parses wildcard-agent disallow rules', () {
      final rules = RobotsChecker.parseDisallowRules(robots, 'MyCrawler/1.0');
      expect(rules, hasLength(2));
      expect(rules.any((r) => r.hasMatch('/admin')), isTrue);
      expect(rules.any((r) => r.hasMatch('/admin/settings')), isTrue);
      expect(rules.any((r) => r.hasMatch('/public')), isFalse);
    });

    test('glob patterns match path segments', () {
      final rules = RobotsChecker.parseDisallowRules(robots, 'MyCrawler/1.0');
      expect(rules.any((r) => r.hasMatch('/private/data')), isTrue);
    });

    test('agent-specific sections apply only to that agent', () {
      final generic = RobotsChecker.parseDisallowRules(robots, 'MyCrawler/1.0');
      expect(generic.any((r) => r.hasMatch('/special')), isFalse);

      final special = RobotsChecker.parseDisallowRules(robots, 'SpecialBot');
      expect(special.any((r) => r.hasMatch('/special')), isTrue);
    });

    test('empty and comment-only files allow everything', () {
      expect(RobotsChecker.parseDisallowRules('', 'A'), isEmpty);
      expect(RobotsChecker.parseDisallowRules('# nothing here', 'A'), isEmpty);
    });
  });
}
