import 'package:government_scheme_db_builder/validator/scheme_validator.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  group('SchemeValidator', () {
    test('accepts a fully populated scheme', () {
      final errors = <String>[];
      expect(SchemeValidator.isValid(makeScheme(), errors), isTrue);
      expect(errors, isEmpty);
    });

    test('rejects empty title', () {
      final errors = <String>[];
      expect(
        SchemeValidator.isValid(makeScheme(title: '  '), errors),
        isFalse,
      );
      expect(errors, hasLength(1));
    });

    test('rejects invalid URL', () {
      final errors = <String>[];
      expect(
        SchemeValidator.isValid(
          makeScheme(officialUrl: 'not-a-url'),
          errors,
        ),
        isFalse,
      );
    });

    test('rejects non-http scheme URLs', () {
      final errors = <String>[];
      expect(
        SchemeValidator.isValid(
          makeScheme(officialUrl: 'ftp://example.gov.in/x'),
          errors,
        ),
        isFalse,
      );
    });

    test('rejects records with no descriptive content', () {
      final errors = <String>[];
      expect(
        SchemeValidator.isValid(
          makeScheme(description: '', benefits: '', eligibility: ''),
          errors,
        ),
        isFalse,
      );
    });

    test('accepts records with only benefits as content', () {
      final errors = <String>[];
      expect(
        SchemeValidator.isValid(
          makeScheme(description: '', eligibility: ''),
          errors,
        ),
        isTrue,
      );
    });

    test('rejects malformed last-updated dates', () {
      final errors = <String>[];
      expect(
        SchemeValidator.isValid(
          makeScheme(lastUpdated: '15/01/2026'),
          errors,
        ),
        isFalse,
      );
    });

    test('accepts empty last-updated', () {
      final errors = <String>[];
      expect(
        SchemeValidator.isValid(makeScheme(lastUpdated: ''), errors),
        isTrue,
      );
    });
  });
}
