import 'dart:convert';
import 'dart:io';

import '../models/scheme.dart';

class JsonParser {
  const JsonParser();

  Future<List<Scheme>> parseFile(String path) async {
    final file = File(path);

    if (!file.existsSync()) {
      throw Exception('File not found: $path');
    }

    final jsonString = await file.readAsString();

    return parseString(jsonString);
  }

  List<Scheme> parseString(String jsonString) {
    final decoded = jsonDecode(jsonString);

    if (decoded is! List) {
      throw Exception('JSON root must be an array.');
    }

    return decoded
        .map((e) => Scheme.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}