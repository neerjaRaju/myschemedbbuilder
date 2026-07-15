import 'dart:io';
import '../lib/models/scheme.dart';
import '../lib/parser/json_parser.dart';
import '../lib/validator/scheme_validator.dart';
import '../lib/validator/duplicate_validator.dart';

void main() {
  final Directory generatedDir = Directory('data/generated');
  final String masterOutputPath = 'data/processed/schemes_master.json';

  if (!generatedDir.existsSync()) {
    print('Error: Generated data directory "data/generated" does not exist.');
    exit(1);
  }

  print('==================================================');
  print('Starting Master Dataset Compiler');
  print('==================================================');

  final List<Scheme> allSchemes = [];
  final List<String> errorLog = [];
  final List<String> deduplicationLog = [];

  // 1. Scan and parse all crawler outputs
  final List<FileSystemEntity> files = generatedDir.listSync();
  for (var file in files) {
    if (file is File && file.path.endsWith('.json')) {
      print('Reading generated file: ${file.path}');
      final schemes = JsonParser.parseFile(file.path);
      allSchemes.addAll(schemes);
    }
  }

  print('\nTotal raw records loaded: ${allSchemes.length}');

  // 2. Schema validation
  print('Validating records...');
  final List<Scheme> validatedSchemes = [];
  for (var scheme in allSchemes) {
    if (SchemeValidator.isValid(scheme, errorLog)) {
      validatedSchemes.add(scheme);
    }
  }

  if (errorLog.isNotEmpty) {
    print('Validation report (${errorLog.length} warnings/errors detected):');
    errorLog.take(15).forEach((err) => print('  - $err'));
    if (errorLog.length > 15)
      print('  - ... and ${errorLog.length - 15} more.');
  }

  // 3. De-duplicate across different sources using our multi-criteria validator
  print('\nDeduplicating and resolving similarities...');
  final List<Scheme> uniqueSchemes = DuplicateValidator.deduplicate(
    validatedSchemes,
    deduplicationLog,
  );

  if (deduplicationLog.isNotEmpty) {
    print(
      'Deduplication actions log (${deduplicationLog.length} resolved collisions):',
    );
    deduplicationLog.take(10).forEach((log) => print('  - $log'));
    if (deduplicationLog.length > 10)
      print('  - ... and ${deduplicationLog.length - 10} more.');
  }

  // 4. Sort deterministically by ID
  uniqueSchemes.sort((a, b) => a.id.compareTo(b.id));

  // 5. Write to master output path
  print(
    '\nWriting master dataset containing ${uniqueSchemes.length} clean records...',
  );
  JsonParser.writeToFile(masterOutputPath, uniqueSchemes);

  print('Master compilation complete. File saved to: $masterOutputPath');
}
