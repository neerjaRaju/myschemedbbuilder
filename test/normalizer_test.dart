import 'package:government_scheme_db_builder/utils/normalizer.dart';
import 'package:test/test.dart';

void main() {
  group('sanitizeText', () {
    test('strips HTML tags and entities', () {
      expect(
        Normalizer.sanitizeText('<p>Hello&nbsp;<b>World</b></p>'),
        'Hello World',
      );
    });

    test('collapses whitespace and trims', () {
      expect(Normalizer.sanitizeText('  a \n\t b   c '), 'a b c');
    });

    test('removes bullet glyphs and invisible characters', () {
      expect(Normalizer.sanitizeText('• item​ one'), 'item one');
    });

    test('returns empty for empty input', () {
      expect(Normalizer.sanitizeText(''), '');
    });
  });

  group('normalizeList', () {
    test('produces markdown bullets and drops empty items', () {
      expect(
        Normalizer.normalizeList(['<b>A</b>', '', '  B  ']),
        '* A\n* B',
      );
    });
  });

  group('normalizeHelpline', () {
    test('formats 10-digit numbers', () {
      expect(Normalizer.normalizeHelpline('98765 43210'), '+91-9876543210');
    });

    test('formats 12-digit numbers with country code', () {
      expect(Normalizer.normalizeHelpline('919876543210'), '+91-9876543210');
    });

    test('passes through text and toll-free strings sanitized', () {
      expect(
        Normalizer.normalizeHelpline('Call  1800-11-0001 now'),
        'Call 1800-11-0001 now',
      );
      expect(Normalizer.normalizeHelpline('155261'), '155261');
    });
  });

  group('normalizeDate', () {
    test('parses ISO dates', () {
      expect(Normalizer.normalizeDate('2026-01-15'), '2026-01-15');
    });

    test('parses DD/MM/YYYY', () {
      expect(Normalizer.normalizeDate('15/01/2026'), '2026-01-15');
    });

    test('parses day month-name year', () {
      expect(Normalizer.normalizeDate('15 January 2026'), '2026-01-15');
      expect(Normalizer.normalizeDate('3rd Aug 2025'), '2025-08-03');
    });

    test('parses month-name day, year', () {
      expect(Normalizer.normalizeDate('January 15, 2026'), '2026-01-15');
    });

    test('returns empty for unparseable input (deterministic)', () {
      expect(Normalizer.normalizeDate('not a date'), '');
      expect(Normalizer.normalizeDate(''), '');
    });

    test('rejects impossible dates', () {
      expect(Normalizer.normalizeDate('45/45/2026'), '');
    });
  });

  group('normalizeUrl', () {
    test('lowercases scheme and host but preserves path case', () {
      expect(
        Normalizer.normalizeUrl('HTTPS://WWW.India.GOV.in/Schemes/ABC'),
        'https://www.india.gov.in/Schemes/ABC',
      );
    });

    test('adds https to schemeless URLs', () {
      expect(
        Normalizer.normalizeUrl('www.myscheme.gov.in/schemes/pm-kisan'),
        'https://www.myscheme.gov.in/schemes/pm-kisan',
      );
    });

    test('strips fragments, trailing slashes and tracking params', () {
      expect(
        Normalizer.normalizeUrl(
          'https://ballapps.gov.in/schemes/?utm_source=x&id=2#top',
        ),
        'https://ballapps.gov.in/schemes?id=2',
      );
    });

    test('returns empty for garbage', () {
      expect(Normalizer.normalizeUrl(''), '');
      expect(Normalizer.normalizeUrl('   '), '');
    });
  });
}
