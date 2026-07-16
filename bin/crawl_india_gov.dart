import 'dart:io';

import 'package:government_scheme_db_builder/crawler/crawl_runner.dart';
import 'package:government_scheme_db_builder/crawler/source_config.dart';
import 'package:government_scheme_db_builder/utils/constants.dart';
import 'package:government_scheme_db_builder/utils/logger.dart';

/// Crawls the national portal (india.gov.in) scheme pages and writes
/// `data/generated/india_gov_schemes.json`.
Future<void> main() async {
  const logger = SimpleLogger(name: 'crawl-india-gov');
  logger.info('Starting india.gov.in crawler');

  try {
    final config = SourceConfig.loadFromFile('$kSourcesDir/india_gov.json');
    final schemes = await CrawlRunner(config).run();
    logger.info('india.gov.in crawl finished with ${schemes.length} schemes.');
  } on Exception catch (e) {
    logger.error('india.gov.in crawl failed: $e');
    exitCode = 1;
  }
}
