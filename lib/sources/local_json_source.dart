import '../models/scheme.dart';
import '../parsers/json_parser.dart';
import 'source.dart';

class LocalJsonSource implements SchemeSource {
  final String filePath;

  const LocalJsonSource(this.filePath);

  @override
  String get name => "Local JSON";

  @override
  Future<List<Scheme>> fetchSchemes() async {
    final parser = JsonParser();
    return parser.parseFile(filePath);
  }
}