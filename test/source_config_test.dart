import 'dart:io';

import 'package:government_scheme_db_builder/crawler/crawl_runner.dart';
import 'package:government_scheme_db_builder/crawler/myscheme_api.dart';
import 'package:government_scheme_db_builder/crawler/source_config.dart';
import 'package:test/test.dart';

void main() {
  group('SourceConfig', () {
    test('parses a full JSON config', () {
      final config = SourceConfig.fromJson({
        'name': 'test',
        'seed_urls': ['https://a.gov.in/schemes'],
        'sitemap_urls': ['https://a.gov.in/sitemap.xml'],
        'url_allow_pattern': r'^https://a\.gov\.in/',
        'detail_url_pattern': r'^https://a\.gov\.in/schemes/[a-z-]+$',
        'default_state': 'Kerala',
        'default_ministry': 'Ministry X',
        'requests_per_second': 5,
        'max_pages': 100,
        'state_by_domain': {'kerala.gov.in': 'Kerala'},
        'api': {'base_url': 'https://api.a.gov.in', 'api_key': 'k'},
      });

      expect(config.name, 'test');
      expect(config.allowRegExp.hasMatch('https://a.gov.in/schemes'), isTrue);
      expect(
        config.detailRegExp.hasMatch('https://a.gov.in/schemes/pm-kisan'),
        isTrue,
      );
      expect(
        config.detailRegExp.hasMatch('https://a.gov.in/schemes/'),
        isFalse,
      );
      expect(config.maxPages, 100);
      expect(config.api, isNotNull);
    });

    test('applies defaults for optional fields', () {
      final config = SourceConfig.fromJson({
        'name': 'minimal',
        'seed_urls': <String>[],
      });
      expect(config.sitemapUrls, isEmpty);
      expect(config.requestsPerSecond, 2);
      expect(config.maxPages, isNull);
      expect(config.api, isNull);
    });

    test('stateForUrl resolves by domain with fallback', () {
      final config = SourceConfig.fromJson({
        'name': 'states',
        'seed_urls': <String>[],
        'default_state': 'Central',
        'state_by_domain': {'kerala.gov.in': 'Kerala'},
      });
      expect(
        config.stateForUrl('https://schemes.kerala.gov.in/x'),
        'Kerala',
      );
      expect(config.stateForUrl('https://other.gov.in/x'), 'Central');
    });

    test('bundled source config files load and are well-formed', () {
      for (final file in Directory('sources').listSync().whereType<File>()) {
        final config = SourceConfig.loadFromFile(file.path);
        expect(config.name, isNotEmpty, reason: file.path);
        expect(
          config.seedUrls.every((u) => u.startsWith('https://')),
          isTrue,
          reason: file.path,
        );
      }
    });
  });

  group('CrawlRunner.parseSitemapLocs', () {
    test('extracts and normalizes loc entries', () {
      const xml = '''
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url><loc>https://www.myscheme.gov.in/schemes/pm-kisan</loc></url>
  <url><loc> https://www.myscheme.gov.in/schemes/pmjay/ </loc></url>
</urlset>
''';
      expect(CrawlRunner.parseSitemapLocs(xml), [
        'https://www.myscheme.gov.in/schemes/pm-kisan',
        'https://www.myscheme.gov.in/schemes/pmjay',
      ]);
    });

    test('returns empty for non-sitemap content', () {
      expect(CrawlRunner.parseSitemapLocs('<html></html>'), isEmpty);
    });
  });

  group('MySchemeApiClient helpers', () {
    test('collectSlugs finds slugs at any depth', () {
      final payload = {
        'data': {
          'hits': {
            'items': [
              {
                'fields': {'slug': 'pm-kisan'},
              },
              {
                'fields': {'slug': 'pmjay'},
              },
            ],
          },
        },
      };
      expect(
        MySchemeApiClient.collectSlugs(payload),
        ['pm-kisan', 'pmjay'],
      );
    });

    test('findTotal locates the reported total', () {
      final payload = {
        'data': {
          'summary': {'total': 3847},
        },
      };
      expect(MySchemeApiClient.findTotal(payload), 3847);
      expect(MySchemeApiClient.findTotal({'a': 1}), isNull);
    });

    test('MySchemeApiConfig parses with defaults', () {
      final config = MySchemeApiConfig.fromJson({
        'base_url': 'https://api.myscheme.gov.in',
        'api_key': 'key',
      });
      expect(config.searchPath, '/search/v6/schemes');
      expect(config.detailPath, '/schemes/v5/public/schemes');
      expect(config.pageSize, 100);
    });
  });
}
