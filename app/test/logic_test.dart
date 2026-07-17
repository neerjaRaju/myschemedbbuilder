import 'package:flutter_test/flutter_test.dart';
import 'package:scheme_app/l10n/strings.dart';
import 'package:scheme_app/logic/eligibility.dart';
import 'package:scheme_app/logic/filters.dart';
import 'package:scheme_app/models/scheme.dart';

Scheme makeScheme({
  String id = 'a',
  String title = 'Test Scheme',
  String eligibility = '',
  String state = 'Central',
  String description = 'A scheme.',
  List<String> tags = const [],
}) {
  return Scheme(
    id: id,
    title: title,
    description: description,
    benefits: 'Benefit.',
    eligibility: eligibility,
    documents: const [],
    applicationProcess: '',
    ministry: '',
    department: '',
    category: '',
    tags: tags,
    state: state,
    officialUrl: 'https://www.myscheme.gov.in/schemes/$id',
    helpline: '',
    faq: const {},
    lastUpdated: '',
  );
}

void main() {
  group('AgeRule', () {
    test('parses between X and Y years', () {
      final rule = AgeRule.parse('Applicant must be between 18 and 40 years.');
      expect(rule.allows(25), isTrue);
      expect(rule.allows(17), isFalse);
      expect(rule.allows(41), isFalse);
    });

    test('parses above / below', () {
      expect(AgeRule.parse('above 60 years of age').allows(65), isTrue);
      expect(AgeRule.parse('above 60 years of age').allows(50), isFalse);
      expect(AgeRule.parse('below 35 years').allows(30), isTrue);
      expect(AgeRule.parse('below 35 years').allows(40), isFalse);
    });

    test('unconstrained when no age is mentioned', () {
      expect(AgeRule.parse('Open to all citizens.').allows(99), isTrue);
    });
  });

  group('IncomeRule', () {
    test('parses lakh caps', () {
      expect(
        IncomeRule.parseCap('Annual income should not exceed Rs. 2.5 lakh'),
        250000,
      );
    });

    test('parses plain rupee caps', () {
      expect(
        IncomeRule.parseCap('family income less than ₹100000 per annum'),
        100000,
      );
    });

    test('returns null when no cap is stated', () {
      expect(IncomeRule.parseCap('No income restrictions.'), isNull);
    });
  });

  group('SmartFilters', () {
    test('level filter separates central and state schemes', () {
      final central = makeScheme(id: 'c', state: 'Central');
      final rajasthan = makeScheme(id: 'r', state: 'Rajasthan');
      final filters = SmartFilters(level: SchemeLevel.central);
      expect(filters.matches(central), isTrue);
      expect(filters.matches(rajasthan), isFalse);
    });

    test('state filter keeps central plus matching state', () {
      final filters = SmartFilters(state: 'Kerala');
      expect(filters.matches(makeScheme(state: 'Kerala')), isTrue);
      expect(filters.matches(makeScheme(state: 'Central')), isTrue);
      expect(filters.matches(makeScheme(state: 'Rajasthan')), isFalse);
    });

    test('age filter excludes out-of-window schemes', () {
      final filters = SmartFilters(age: 70);
      final young = makeScheme(
        eligibility: 'Applicant must be between 18 and 40 years.',
      );
      expect(filters.matches(young), isFalse);
      expect(filters.matches(makeScheme(eligibility: 'Any age.')), isTrue);
    });

    test('income filter respects stated ceilings', () {
      final filters = SmartFilters(income: 900000);
      final capped = makeScheme(
        eligibility: 'Annual income should not exceed Rs. 2.5 lakh.',
      );
      expect(filters.matches(capped), isFalse);
      expect(filters.matches(makeScheme()), isTrue);
    });

    test('empty filters match everything', () {
      expect(SmartFilters().matches(makeScheme()), isTrue);
    });
  });

  group('EligibilityChecker', () {
    test('counts schemes the profile may qualify for', () {
      final schemes = [
        makeScheme(id: '1', eligibility: 'between 18 and 40 years'),
        makeScheme(id: '2', eligibility: 'above 60 years'),
        makeScheme(id: '3'),
      ];
      final result = EligibilityChecker.run(
        schemes,
        const EligibilityProfile(age: 30),
      );
      expect(result.count, 2);
      expect(result.eligible.map((s) => s.id), containsAll(['1', '3']));
    });
  });

  group('Localization', () {
    test('all languages define every key defined for English', () {
      const english = S('en');
      const probeKeys = [
        'appTitle',
        'featured',
        'categories',
        'eligibility',
        'compare',
        'notifications',
        'agriculture',
        'skillDevelopment',
        'eligibleCount',
      ];
      for (final (code, _) in kSupportedLanguages) {
        final s = S(code);
        for (final key in probeKeys) {
          expect(s.get(key), isNotEmpty, reason: '$code/$key');
          if (code != 'en') {
            expect(
              s.get(key) == english.get(key) && key != 'appTitle',
              isFalse,
              reason: '$code/$key should be translated',
            );
          }
        }
      }
    });
  });

  group('Scheme model', () {
    test('parses JSON-encoded tags and faq columns', () {
      final scheme = Scheme.fromRow({
        'id': 'x',
        'title': 'T',
        'description': 'D',
        'benefits': '',
        'eligibility': '',
        'documents': 'Aadhaar Card\nLand Records',
        'application_process': '',
        'ministry': '',
        'department': '',
        'category': '',
        'tags': '["farmer","income"]',
        'state': 'Central',
        'official_url': 'https://x',
        'helpline': '',
        'faq': '{"Q?":"A."}',
        'last_updated': '',
      });
      expect(scheme.tags, ['farmer', 'income']);
      expect(scheme.documents, ['Aadhaar Card', 'Land Records']);
      expect(scheme.faq, {'Q?': 'A.'});
      expect(scheme.isCentral, isTrue);
    });
  });
}
