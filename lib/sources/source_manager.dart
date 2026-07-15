import '../models/scheme.dart';
import 'source.dart';

class SourceManager {
  final List<SchemeSource> sources;

  const SourceManager({
    required this.sources,
  });

  Future<List<Scheme>> loadAll() async {
    final List<Scheme> schemes = [];

    for (final source in sources) {
      print("Loading ${source.name}");

      final items = await source.fetchSchemes();

      schemes.addAll(items);
    }

    return schemes;
  }
}