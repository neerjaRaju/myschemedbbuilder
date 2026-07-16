import 'dart:convert';
import 'dart:io';

import '../models/scheme.dart';
import '../utils/logger.dart';

/// Reads generated crawler JSON files into typed [Scheme] lists.
///
/// Writing is handled by `JsonExporter` so serialization rules live in one
/// place.
class JsonParser {
  JsonParser._();

  static const SimpleLogger _logger = SimpleLogger(name: 'json-parser');

  /// Parses a crawler JSON file safely into a typed list of schemes.
  ///
  /// Malformed files or records are logged and skipped instead of aborting
  /// the whole pipeline.
  static List<Scheme> parseFile(String filePath) {
    final file = File(filePath);
    if (!file.existsSync()) return [];

    final rawContent = file.readAsStringSync();
    if (rawContent.trim().isEmpty) return [];

    Object? decoded;
    try {
      decoded = json.decode(rawContent);
    } on FormatException catch (e) {
      _logger.error('Invalid JSON in $filePath: $e');
      return [];
    }
    if (decoded is! List) {
      _logger.error('Expected a JSON array in $filePath.');
      return [];
    }

    final schemes = <Scheme>[];
    for (final item in decoded) {
      try {
        schemes.add(Scheme.fromJson(Map<String, dynamic>.from(item as Map)));
      } catch (e) {
        _logger.warn('Skipping malformed record in $filePath: $e');
      }
    }
    return schemes;
  }
}
