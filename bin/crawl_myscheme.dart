import 'dart:io';

import 'package:government_scheme_db_builder/crawler/myscheme_api.dart';
import 'package:government_scheme_db_builder/utils/constants.dart';
import 'package:government_scheme_db_builder/utils/logger.dart';

/// Fetches every scheme from the official MyScheme public API and writes
/// `data/generated/myscheme_schemes.json`.
Future<void> main() async {
  const logger = SimpleLogger(name: 'crawl-myscheme');
  logger.info('Starting MyScheme API crawler');

  try {
    final config = MySchemeApiConfig.loadFromFile('$kSourcesDir/myscheme.json');
    final schemes = await MySchemeApiRunner(config).run();
    logger.info('MyScheme API crawl finished with ${schemes.length} schemes.');
  } on Exception catch (e) {
    logger.error('MyScheme API crawl failed: $e');
    exitCode = 1;
  }
}
