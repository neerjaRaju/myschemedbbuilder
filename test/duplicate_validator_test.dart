import 'package:government_scheme_db_builder/validator/duplicate_validator.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  group('DuplicateValidator', () {
    test('drops exact URL duplicates', () {
      final log = <String>[];
      final result = DuplicateValidator.deduplicate(
        [
          makeScheme(id: 'a'),
          makeScheme(id: 'b'),
        ],
        log,
      );
      expect(result, hasLength(1));
      expect(log, hasLength(1));
    });

    test('drops near-identical titles within same state and ministry', () {
      final log = <String>[];
      final result = DuplicateValidator.deduplicate(
        [
          makeScheme(
            id: 'a',
            title: 'Pradhan Mantri Kisan Samman Nidhi Yojana',
            officialUrl: 'https://a.gov.in/scheme-1',
          ),
          makeScheme(
            id: 'b',
            title: 'Pradhan Mantri Kisan Samman Nidhi Yojana!',
            officialUrl: 'https://b.gov.in/scheme-2',
          ),
        ],
        log,
      );
      expect(result, hasLength(1));
    });

    test('keeps similar titles from different states', () {
      final log = <String>[];
      final result = DuplicateValidator.deduplicate(
        [
          makeScheme(
            id: 'a',
            title: 'Old Age Pension Scheme',
            state: 'Kerala',
            officialUrl: 'https://kerala.gov.in/oaps',
          ),
          makeScheme(
            id: 'b',
            title: 'Old Age Pension Scheme',
            state: 'Rajasthan',
            officialUrl: 'https://rajasthan.gov.in/oaps',
          ),
        ],
        log,
      );
      expect(result, hasLength(2));
    });

    test('keeps entirely distinct schemes', () {
      final log = <String>[];
      final result = DuplicateValidator.deduplicate(
        [
          makeScheme(
            id: 'a',
            title: 'PM Kisan',
            officialUrl: 'https://a.gov.in/1',
          ),
          makeScheme(
            id: 'b',
            title: 'Ayushman Bharat',
            description: 'Health insurance scheme.',
            officialUrl: 'https://b.gov.in/2',
          ),
        ],
        log,
      );
      expect(result, hasLength(2));
      expect(log, isEmpty);
    });
  });
}
