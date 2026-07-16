import 'dart:io';

import 'package:government_scheme_db_builder/crawler/crawl_runner.dart';
import 'package:government_scheme_db_builder/crawler/source_config.dart';
import 'package:government_scheme_db_builder/utils/constants.dart';
import 'package:government_scheme_db_builder/utils/logger.dart';

/// Crawls official state government scheme portals and writes
/// `data/generated/state_schemes.json`.
Future<void> main() async {
  const logger = SimpleLogger(name: 'crawl-state');
  logger.info('Starting state portals crawler');

  try {
    final config =
        SourceConfig.loadFromFile('$kSourcesDir/state_portals.json');
    final schemes = await CrawlRunner(config).run();
    logger.info('State portals crawl finished with ${schemes.length} schemes.');
  } on Exception catch (e) {
    logger.error('State portals crawl failed: $e');
    exitCode = 1;
  }
}
