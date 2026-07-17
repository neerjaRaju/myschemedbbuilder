import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

/// Downloads, stores and opens the offline `schemes.db` published weekly by
/// the GitHub Actions pipeline.
class DatabaseService {
  /// Raw GitHub URL of the weekly database artifact.
  static const String databaseUrl =
      'https://raw.githubusercontent.com/neerjaRaju/myschemedbbuilder/main/'
      'data/output/schemes.db';

  Database? _db;

  Database get db {
    final database = _db;
    if (database == null) {
      throw StateError('Database not opened. Call ensureReady() first.');
    }
    return database;
  }

  bool get isReady => _db != null;

  Future<String> _localPath() async {
    final dir = await getApplicationSupportDirectory();
    return p.join(dir.path, 'schemes.db');
  }

  Future<String> _etagPath() async {
    final dir = await getApplicationSupportDirectory();
    return p.join(dir.path, 'schemes.db.etag');
  }

  /// Opens the local database, downloading it first if it does not exist.
  ///
  /// [onProgress] receives values in `0.0..1.0` while downloading.
  Future<void> ensureReady({void Function(double progress)? onProgress}) async {
    if (_db != null) return;
    final path = await _localPath();
    if (!File(path).existsSync()) {
      await _download(path, onProgress: onProgress);
    }
    _open(path);
  }

  /// Re-downloads the database when GitHub has a newer version.
  ///
  /// Returns `true` when a new database was installed. Uses the HTTP ETag so
  /// an unchanged database costs a single conditional request.
  Future<bool> refresh({void Function(double progress)? onProgress}) async {
    final path = await _localPath();
    final etagFile = File(await _etagPath());
    final oldEtag = etagFile.existsSync() ? etagFile.readAsStringSync() : '';

    final head = await http.head(Uri.parse(databaseUrl));
    final remoteEtag = head.headers['etag'] ?? '';
    if (remoteEtag.isNotEmpty && remoteEtag == oldEtag) return false;

    _db?.dispose();
    _db = null;
    await _download(path, onProgress: onProgress);
    _open(path);
    return true;
  }

  Future<void> _download(
    String path, {
    void Function(double progress)? onProgress,
  }) async {
    final request = http.Request('GET', Uri.parse(databaseUrl));
    final response = await http.Client().send(request);
    if (response.statusCode != 200) {
      throw HttpException(
        'Database download failed: HTTP ${response.statusCode}',
        uri: Uri.parse(databaseUrl),
      );
    }

    final total = response.contentLength ?? 0;
    var received = 0;
    final tempFile = File('$path.download');
    final sink = tempFile.openWrite();
    try {
      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0 && onProgress != null) {
          onProgress(received / total);
        }
      }
    } finally {
      await sink.close();
    }
    // Atomic install: only replace the live db once fully downloaded.
    tempFile.renameSync(path);

    final etag = response.headers['etag'];
    if (etag != null) {
      File(await _etagPath()).writeAsStringSync(etag);
    }
  }

  void _open(String path) {
    final database = sqlite3.open(path, mode: OpenMode.readOnly);
    _db = database;
  }

  /// Value from the builder's `meta` table (e.g. `record_count`).
  String? meta(String key) {
    final rows = db.select('SELECT value FROM meta WHERE key = ?', [key]);
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  void dispose() {
    _db?.dispose();
    _db = null;
  }
}
