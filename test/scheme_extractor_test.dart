import 'package:government_scheme_db_builder/extractor/scheme_extractor.dart';
import 'package:test/test.dart';

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
  group('SchemeExtractor.fromApiJson', () {
    final scheme = SchemeExtractor.fromApiJson(
      {'data': _schemeData()},
      slug: 'pm-kisan',
      defaultState: 'Central',
      defaultMinistry: '',
    );

    test('extracts all core fields from an API detail payload', () {
      expect(scheme, isNotNull);
      expect(scheme!.title, 'PM Kisan Samman Nidhi');
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
      expect(
        scheme.officialUrl,
        'https://www.myscheme.gov.in/schemes/pm-kisan',
      );
    });

    test('preserves document list boundaries', () {
      expect(scheme!.requiredDocuments, ['Aadhaar Card', 'Land Records']);
    });

    test('flattens rich-text application process', () {
      expect(scheme!.applicationProcess, 'Register on the PM Kisan portal.');
    });

    test('extracts FAQ pairs', () {
      expect(scheme!.faq, {'Who is eligible?': 'Farmer families.'});
    });

    test('produces a deterministic 16-character id', () {
      final again = SchemeExtractor.fromApiJson(
        {'data': _schemeData()},
        slug: 'pm-kisan',
        defaultState: 'Central',
        defaultMinistry: '',
      );
      expect(again!.id, scheme!.id);
      expect(scheme.id, hasLength(16));
    });

    test('applies defaults when state and ministry are missing', () {
      final data = _schemeData();
      final en = data['en'] as Map<String, dynamic>;
      final basic = en['basicDetails'] as Map<String, dynamic>;
      basic.remove('state');
      basic.remove('nodalMinistryName');

      final result = SchemeExtractor.fromApiJson(
        {'data': data},
        slug: 'x',
        defaultState: 'Central',
        defaultMinistry: 'Default Ministry',
      );
      expect(result!.state, 'Central');
      expect(result.ministry, 'Default Ministry');
    });

    test('returns null for payloads without a scheme (no fake data)', () {
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
      expect(
        SchemeExtractor.fromApiJson(
          {
            'data': {
              'en': {'basicDetails': <String, dynamic>{}},
            },
          },
          slug: 'x',
          defaultState: '',
          defaultMinistry: '',
        ),
        isNull,
      );
    });
  });
}
