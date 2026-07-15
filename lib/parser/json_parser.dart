import 'dart:convert';
import 'dart:io';
import '../models/scheme.dart';

class JsonParser {
  /// Parses a generated crawler JSON file safely into a typed List of Schemes.
  static List<Scheme> parseFile(String filePath) {
    final file = File(filePath);
    if (!file.existsSync()) return [];

    try {
      final rawContent = file.readAsStringSync();
      if (rawContent.trim().isEmpty) return [];

      final decoded = json.decode(rawContent);
      if (decoded is List) {
        return decoded
            .map(
              (item) => Scheme.fromJson(Map<String, dynamic>.from(item as Map)),
            )
            .toList();
      }
    } catch (e) {
      stderr.writeln('Failed to parse scheme JSON file: $filePath. Error: $e');
    }
    return [];
  }

  /// Writes a verified list of Schemes into standard indented JSON.
  static void writeToFile(String filePath, List<Scheme> schemes) {
    final file = File(filePath);
    if (!file.parent.existsSync()) {
      file.parent.createSync(recursive: true);
    }

    final jsonString = const JsonEncoder.withIndent(
      '  ',
    ).convert(schemes.map((s) => s.toJson()).toList());
    file.writeAsStringSync(jsonString, flush: true);
  }
}
