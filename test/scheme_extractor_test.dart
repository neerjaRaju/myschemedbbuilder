import 'dart:convert';

import 'package:government_scheme_db_builder/extractor/scheme_extractor.dart';
import 'package:test/test.dart';

const _htmlPage = '''
<html>
<head><meta name="description" content="Meta fallback description."></head>
<body>
  <h1>Old Age Pension Scheme</h1>
  <div class="description">Monthly pension for senior citizens.</div>
  <div class="benefits">Rs 1500 per month.</div>
  <div class="eligibility">Age 60 or above.</div>
  <div class="documents"><ul><li>Aadhaar Card</li><li>Age Proof</li></ul></div>
  <div class="application-process">Apply at the nearest office.</div>
  <span class="ministry">Department of Social Justice</span>
  <a class="category">Pension</a>
  <span class="state">Kerala</span>
  <div class="faq-question">Who can apply?</div>
  <div class="faq-answer">Residents aged 60+.</div>
  <span class="last-updated">15/01/2026</span>
</body>
</html>
''';

Map<String, dynamic> _schemeData() => {
      'en': {
        'basicDetails': {
          'schemeName': 'PM Kisan Samman Nidhi',
          'briefDescription': 'Income support for farmers.',
          'nodalMinistryName': {
            'label': 'Ministry of Agriculture and Farmers Welfare',
          },
          'schemeCategory': ['Agriculture'],
          'state': {'label': 'Central'},
          'tags': ['farmer', 'income'],
        },
        'schemeContent': {
          'detailedDescription_md':
              'Provides Rs 6000 per year to farmer families.',
          'benefits_md': 'Rs 2000 every four months.',
        },
        'eligibilityCriteria': {
          'eligibilityDescription_md': 'All landholding farmer families.',
        },
        'applicationProcess': [
          {
            'mode': 'Online',
            'process': [
              {
                'children': [
                  {'text': 'Register on the PM Kisan portal.'},
                ],
              },
            ],
            'requiredDocuments': 'Aadhaar Card\nLand Records',
          },
        ],
        'faqs': [
          {'question': 'Who is eligible?', 'answer': 'Farmer families.'},
        ],
      },
    };

void main() {
  group('SchemeExtractor.extract (CSS selectors)', () {
    final scheme = SchemeExtractor.extract(
      html: _htmlPage,
      sourceUrl: 'https://kerala.gov.in/schemes/old-age-pension/',
      defaultState: 'Kerala',
      defaultMinistry: 'Default Ministry',
    );

    test('extracts all core fields', () {
      expect(scheme.title, 'Old Age Pension Scheme');
      expect(scheme.description, 'Monthly pension for senior citizens.');
      expect(scheme.benefits, 'Rs 1500 per month.');
      expect(scheme.eligibility, 'Age 60 or above.');
      expect(scheme.requiredDocuments, ['Aadhaar Card', 'Age Proof']);
      expect(scheme.applicationProcess, 'Apply at the nearest office.');
      expect(scheme.ministry, 'Department of Social Justice');
      expect(scheme.category, 'Pension');
      expect(scheme.state, 'Kerala');
    });

    test('extracts FAQ pairs', () {
      expect(scheme.faq, {'Who can apply?': 'Residents aged 60+.'});
    });

    test('normalizes dates and URLs', () {
      expect(scheme.lastUpdated, '2026-01-15');
      expect(
        scheme.officialUrl,
        'https://kerala.gov.in/schemes/old-age-pension',
      );
    });

    test('produces a deterministic id', () {
      final again = SchemeExtractor.extract(
        html: _htmlPage,
        sourceUrl: 'https://kerala.gov.in/schemes/old-age-pension/',
        defaultState: 'Kerala',
        defaultMinistry: 'Default Ministry',
      );
      expect(again.id, scheme.id);
      expect(scheme.id, hasLength(16));
    });
  });

  group('SchemeExtractor.extract (__NEXT_DATA__)', () {
    final nextData = json.encode({
      'props': {
        'pageProps': {'schemeData': _schemeData()},
      },
    });
    final html = '<html><body>'
        '<script id="__NEXT_DATA__" type="application/json">$nextData'
        '</script></body></html>';

    final scheme = SchemeExtractor.extract(
      html: html,
      sourceUrl: 'https://www.myscheme.gov.in/schemes/pm-kisan',
      defaultState: 'Central',
      defaultMinistry: '',
    );

    test('prefers embedded JSON over selectors', () {
      expect(scheme.title, 'PM Kisan Samman Nidhi');
      expect(
        scheme.description,
        'Provides Rs 6000 per year to farmer families.',
      );
      expect(scheme.benefits, 'Rs 2000 every four months.');
      expect(scheme.eligibility, 'All landholding farmer families.');
      expect(scheme.ministry, 'Ministry of Agriculture and Farmers Welfare');
      expect(scheme.category, 'Agriculture');
      expect(scheme.state, 'Central');
      expect(scheme.tags, ['farmer', 'income']);
    });

    test('flattens rich-text application process', () {
      expect(scheme.applicationProcess, 'Register on the PM Kisan portal.');
    });

    test('extracts FAQs from JSON', () {
      expect(scheme.faq, {'Who is eligible?': 'Farmer families.'});
    });

    test('empty shell pages yield empty titles (no fake data)', () {
      final shell = '<html><body>'
          '<script id="__NEXT_DATA__" type="application/json">'
          '{"props":{"pageProps":{}}}</script></body></html>';
      final empty = SchemeExtractor.extract(
        html: shell,
        sourceUrl: 'https://www.myscheme.gov.in/schemes/unknown',
        defaultState: 'Central',
        defaultMinistry: '',
      );
      expect(empty.title, isEmpty);
    });
  });

  group('SchemeExtractor.fromApiJson', () {
    test('builds a scheme from an API detail payload', () {
      final scheme = SchemeExtractor.fromApiJson(
        {'data': _schemeData()},
        slug: 'pm-kisan',
        defaultState: 'Central',
        defaultMinistry: '',
      );

      expect(scheme, isNotNull);
      expect(scheme!.title, 'PM Kisan Samman Nidhi');
      expect(
        scheme.officialUrl,
        'https://www.myscheme.gov.in/schemes/pm-kisan',
      );
      expect(scheme.requiredDocuments, ['Aadhaar Card', 'Land Records']);
      expect(scheme.faq, {'Who is eligible?': 'Farmer families.'});
    });

    test('returns null for payloads without a scheme', () {
      expect(
        SchemeExtractor.fromApiJson(
          {'data': null},
          slug: 'x',
          defaultState: '',
          defaultMinistry: '',
        ),
        isNull,
      );
      expect(
        SchemeExtractor.fromApiJson(
          {'status': 'error'},
          slug: 'x',
          defaultState: '',
          defaultMinistry: '',
        ),
        isNull,
      );
    });
  });
}
