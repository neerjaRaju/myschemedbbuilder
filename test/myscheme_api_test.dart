import 'package:government_scheme_db_builder/crawler/myscheme_api.dart';
import 'package:test/test.dart';

void main() {
  group('MySchemeApiConfig', () {
    test('parses with defaults', () {
      final config = MySchemeApiConfig.fromJson({
        'base_url': 'https://api.myscheme.gov.in',
        'api_key': 'key',
      });
      expect(config.searchPath, '/search/v6/schemes');
      expect(config.detailPath, '/schemes/v5/public/schemes');
      expect(config.pageSize, 100);
      expect(config.requestsPerSecond, 4);
    });

    test('loads the bundled sources/myscheme.json', () {
      final config = MySchemeApiConfig.loadFromFile('sources/myscheme.json');
      expect(config.baseUrl, 'https://api.myscheme.gov.in');
      expect(config.apiKey, isNotEmpty);
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

    test('collectSlugs ignores payloads without slugs', () {
      expect(MySchemeApiClient.collectSlugs({'a': 1}), isEmpty);
      expect(MySchemeApiClient.collectSlugs(null), isEmpty);
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
  });
}
