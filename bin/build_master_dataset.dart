import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  const generatedDir = 'data/generated';
  const outputFile = 'data/processed/schemes_master.json';

  final inputDirectory = Directory(generatedDir);

  if (!inputDirectory.existsSync()) {
    print('❌ Directory not found: $generatedDir');
    exit(1);
  }

  final jsonFiles = inputDirectory
      .listSync()
      .whereType<File>()
      .where((file) => file.path.endsWith('.json'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  if (jsonFiles.isEmpty) {
    print('❌ No JSON files found in $generatedDir');
    exit(1);
  }

  print('======================================');
  print('Government Scheme Dataset Builder');
  print('======================================');
  print('');

  final Map<String, Map<String, dynamic>> schemes = {};

  int totalRecords = 0;

  for (final file in jsonFiles) {
    print('Reading ${file.path}');

    try {
      final content = await file.readAsString();

      final decoded = jsonDecode(content);

      if (decoded is! List) {
        print('Skipping ${file.path} (Not a JSON array)');
        continue;
      }

      print('  ${decoded.length} records');

      totalRecords += decoded.length;

      for (final item in decoded) {
        if (item is! Map<String, dynamic>) continue;

        final id = (item['id'] ?? '').toString().trim();

        if (id.isEmpty) continue;

        // Latest entry wins
        schemes[id] = item;
      }
    } catch (e) {
      print('Failed: ${file.path}');
      print(e);
    }

    print('');
  }

  final output = schemes.values.toList();

  output.sort(
    (a, b) => (a['title'] ?? '')
        .toString()
        .compareTo((b['title'] ?? '').toString()),
  );

  final out = File(outputFile);

  await out.parent.create(recursive: true);

  await out.writeAsString(
    const JsonEncoder.withIndent('  ').convert(output),
  );

  print('======================================');
  print('Build Complete');
  print('======================================');
  print('Files           : ${jsonFiles.length}');
  print('Input Records   : $totalRecords');
  print('Unique Schemes  : ${output.length}');
  print('Duplicates      : ${totalRecords - output.length}');
  print('Output          : $outputFile');
}