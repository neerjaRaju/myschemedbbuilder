import 'package:government_scheme_db_builder/models/scheme.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  group('Scheme', () {
    test('JSON round trip preserves every field', () {
      final original = makeScheme();
      final restored = Scheme.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.description, original.description);
      expect(restored.benefits, original.benefits);
      expect(restored.eligibility, original.eligibility);
      expect(restored.requiredDocuments, original.requiredDocuments);
      expect(restored.applicationProcess, original.applicationProcess);
      expect(restored.ministry, original.ministry);
      expect(restored.department, original.department);
      expect(restored.category, original.category);
      expect(restored.tags, original.tags);
      expect(restored.state, original.state);
      expect(restored.officialUrl, original.officialUrl);
      expect(restored.helpline, original.helpline);
      expect(restored.faq, original.faq);
      expect(restored.lastUpdated, original.lastUpdated);
      expect(restored.hash, original.hash);
    });

    test('hash is deterministic for identical content', () {
      expect(makeScheme(id: 'a').hash, makeScheme(id: 'b').hash);
    });

    test('hash changes when content changes', () {
      expect(
        makeScheme().hash,
        isNot(makeScheme(title: 'Different Title').hash),
      );
    });
  });
}
