import '../models/scheme.dart';

abstract class SchemeSource {
  /// Name of the source
  String get name;

  /// Download and return all schemes from this source
  Future<List<Scheme>> fetchSchemes();
}