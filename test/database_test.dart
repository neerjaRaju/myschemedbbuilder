import 'package:government_scheme_db_builder/database/database.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  group('SchemeDatabase', () {
    late SchemeDatabase db;

    setUp(() => db = SchemeDatabase.inMemory());
    tearDown(() => db.close());

    test('batch-inserts and counts schemes', () {
      final schemes = [
        for (var i = 0; i < 600; i++)
          makeScheme(
            id: 'scheme-$i',
            title: 'Scheme $i',
            officialUrl: 'https://example.gov.in/schemes/$i',
          ),
      ];
      db.insertSchemes(schemes, batchSize: 250);
      expect(db.count(), 600);
    });

    test('upserts replace rows with the same id', () {
      db.insertSchemes([makeScheme(id: 'a')]);
      db.insertSchemes([makeScheme(id: 'a', title: 'Renamed Scheme')]);
      expect(db.count(), 1);
      expect(db.search('Renamed'), hasLength(1));
    });

    test('FTS search finds schemes by content', () {
      db.insertSchemes([
        makeScheme(
          id: 'a',
          title: 'PM Kisan',
          description: 'Income support for farmer families.',
          officialUrl: 'https://a.gov.in/1',
        ),
        makeScheme(
          id: 'b',
          title: 'Ayushman Bharat',
          description: 'Cashless health insurance coverage.',
          benefits: 'Hospitalization cover of Rs 5 lakh.',
          eligibility: 'Economically weaker households.',
          officialUrl: 'https://b.gov.in/2',
          tags: const ['health'],
        ),
      ]);

      final farmers = db.search('farmer');
      expect(farmers, hasLength(1));
      expect(farmers.first['title'], 'PM Kisan');

      final health = db.search('health');
      expect(health, hasLength(1));
      expect(health.first['title'], 'Ayushman Bharat');
    });

    test('FTS index follows deletions', () {
      db.insertSchemes([makeScheme(id: 'a')]);
      expect(db.search('Kisan'), hasLength(1));
      db.deleteSchemes(['a']);
      expect(db.count(), 0);
      expect(db.search('Kisan'), isEmpty);
    });

    test('existingHashes maps ids to content hashes', () {
      final scheme = makeScheme(id: 'a');
      db.insertSchemes([scheme]);
      expect(db.existingHashes(), {'a': scheme.hash});
    });

    test('meta table stores schema version', () {
      db.setMeta('record_count', '1');
      // Re-setting must not throw and count() still works.
      db.setMeta('record_count', '2');
      expect(db.count(), 0);
    });
  });
}
