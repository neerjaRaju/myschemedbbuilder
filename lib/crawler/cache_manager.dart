import 'dart:io';

import '../utils/crypto_utils.dart';

class CacheManager {
  final Directory cacheDir;
  final Duration cacheDuration;

  CacheManager({
    required String path,
    this.cacheDuration = const Duration(days: 7),
  }) : cacheDir = Directory(path) {
    if (!cacheDir.existsSync()) {
      cacheDir.createSync(recursive: true);
    }
  }

  File _getCacheFile(String url) {
    final key = sha256Hash(url);
    return File('${cacheDir.path}/$key.html');
  }

  bool has(String url) {
    final file = _getCacheFile(url);
    if (!file.existsSync()) return false;

    final lastModified = file.lastModifiedSync();
    if (DateTime.now().difference(lastModified) > cacheDuration) {
      file.deleteSync();
      return false;
    }
    return true;
  }

  String? get(String url) {
    if (!has(url)) return null;
    return _getCacheFile(url).readAsStringSync();
  }

  void put(String url, String content) {
    final file = _getCacheFile(url);
    file.writeAsStringSync(content, flush: true);
  }

  void clear() {
    if (cacheDir.existsSync()) {
      cacheDir.deleteSync(recursive: true);
      cacheDir.createSync(recursive: true);
    }
  }
}
