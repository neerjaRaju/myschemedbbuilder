import 'dart:io';

import 'constants.dart';

/// Filesystem helpers shared by the pipeline entrypoints.
class FileUtils {
  FileUtils._();

  /// Ensures that every data directory used by the pipeline exists.
  static void ensureDirectoriesExist() {
    const directories = [
      kCacheDir,
      kGeneratedDir,
      kProcessedDir,
      kOutputDir,
    ];

    for (final dirPath in directories) {
      final dir = Directory(dirPath);
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
    }
  }

  /// Removes every entry inside [path] without deleting the directory.
  static void clearDirectoryContents(String path) {
    final dir = Directory(path);
    if (!dir.existsSync()) return;
    for (final entity in dir.listSync()) {
      entity.deleteSync(recursive: true);
    }
  }

  /// Writes [content] to [path], creating parent directories as needed.
  static void writeSafeString(String path, String content) {
    final file = File(path);
    if (!file.parent.existsSync()) {
      file.parent.createSync(recursive: true);
    }
    file.writeAsStringSync(content, flush: true);
  }
}
