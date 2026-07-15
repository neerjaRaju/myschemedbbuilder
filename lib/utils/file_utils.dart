import 'dart:io';

class FileUtils {
  static void ensureDirectory(String path) {
    final dir = Directory(path);

    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
  }

  static bool exists(String path) {
    return File(path).existsSync();
  }

  static Future<String> read(String path) async {
    return File(path).readAsString();
  }

  static Future<void> write(
    String path,
    String data,
  ) async {
    await File(path).writeAsString(data);
  }
}