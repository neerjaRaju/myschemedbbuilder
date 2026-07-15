import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

class Downloader {
  const Downloader();

  Future<File> download({
    required String url,
    required String fileName,
    String outputDir = 'data/raw',
  }) async {
    final uri = Uri.parse(url);

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception(
        'Download failed (${response.statusCode}) : $url',
      );
    }

    final directory = Directory(outputDir);

    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }

    final file = File(path.join(outputDir, fileName));

    await file.writeAsBytes(response.bodyBytes);

    return file;
  }

  Future<String> downloadAsString(String url) async {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode != 200) {
      throw Exception(
        'Download failed (${response.statusCode})',
      );
    }

    return response.body;
  }
}