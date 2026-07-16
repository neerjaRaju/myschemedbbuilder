import 'dart:convert';
import 'dart:io';

import '../models/scheme.dart';

/// Writes scheme datasets as deterministic, pretty-printed JSON.
///
/// Records are sorted by id and serialized with a fixed key order (see
/// [Scheme.toJson]), so re-exporting identical data produces byte-identical
/// files — which keeps automated weekly commits free of noise.
class JsonExporter {
  JsonExporter._();

  static const JsonEncoder _encoder = JsonEncoder.withIndent('  ');

  /// Serializes [schemes] to [filePath], creating parent directories.
  static void export(String filePath, List<Scheme> schemes) {
    final sorted = List<Scheme>.of(schemes)
      ..sort((a, b) => a.id.compareTo(b.id));

    final file = File(filePath);
    if (!file.parent.existsSync()) {
      file.parent.createSync(recursive: true);
    }
    final jsonString = _encoder.convert(sorted.map((s) => s.toJson()).toList());
    file.writeAsStringSync('$jsonString\n', flush: true);
  }
}
