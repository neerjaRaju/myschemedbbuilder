import '../models/scheme.dart';

class DuplicateValidator {
  const DuplicateValidator();

  List<Scheme> removeDuplicates(List<Scheme> schemes) {
    final map = <String, Scheme>{};

    for (final scheme in schemes) {
      map[scheme.id] = scheme;
    }

    return map.values.toList();
  }
}