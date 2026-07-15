import 'dart:io';

class FileUtils {
  /// Ensures that all required directory trees exist for crawler output.
  static void ensureDirectoriesExist() {
    final directories = [
      'data/raw',
      'data/cache',
      'data/generated',
      'data/processed',
      'data/output',
    ];

    for (var dirPath in directories) {
      final dir = Directory(dirPath);
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
    }
  }

  /// Cleans out old cached data recursively.
  static void clearDirectoryContents(String path) {
    final dir = Directory(path);
    if (dir.existsSync()) {
      dir.listSync().forEach((entity) {
        if (entity is File) {
          entity.deleteSync();
        } else if (entity is Directory) {
          entity.deleteSync(recursive: true);
        }
      });
    }
  }

  /// Safe write-string execution with directory-building fallback.
  static void writeSafeString(String path, String content) {
    final file = File(path);
    if (!file.parent.existsSync()) {
      file.parent.createSync(recursive: true);
    }
    file.writeAsStringSync(content, flush: true);
  }
}
