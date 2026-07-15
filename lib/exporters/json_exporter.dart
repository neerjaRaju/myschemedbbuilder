import 'dart:convert';
import 'dart:io';

import '../models/scheme.dart';

class JsonExporter {
  Future<void> export(
    List<Scheme> schemes,
    String path,
  ) async {
    final json = schemes
        .map((e) => e.toJson())
        .toList();

    await File(path).writeAsString(
      const JsonEncoder.withIndent('  ')
          .convert(json),
    );
  }
}