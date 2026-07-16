import 'dart:io';

import 'package:government_scheme_db_builder/crawler/crawl_runner.dart';
import 'package:government_scheme_db_builder/crawler/myscheme_api.dart';
import 'package:government_scheme_db_builder/crawler/source_config.dart';
import 'package:government_scheme_db_builder/utils/constants.dart';
import 'package:government_scheme_db_builder/utils/logger.dart';

/// Crawls the national MyScheme portal and writes
/// `data/generated/myscheme_schemes.json`.
///
/// MyScheme is a client-rendered application, so the primary strategy is
/// its official public JSON API (the same one the website calls). If the
/// API becomes unavailable, the entrypoint falls back to HTML crawling.
Future<void> main() async {
  const logger = SimpleLogger(name: 'crawl-myscheme');
  logger.info('Starting MyScheme crawler');

  final config = SourceConfig.loadFromFile('$kSourcesDir/myscheme.json');

  final apiBlock = config.api;
  if (apiBlock != null) {
    try {
      final apiConfig = MySchemeApiConfig.fromJson(apiBlock);
      final schemes = await MySchemeApiRunner(apiConfig).run();
      logger.info(
        'MyScheme API crawl finished with ${schemes.length} schemes.',
      );
      return;
    } on Exception catch (e) {
      logger.error('MyScheme API crawl failed: $e');
      logger.warn('Falling back to HTML crawl.');
    }
  }

  try {
    final schemes = await CrawlRunner(config).run();
    logger.info('MyScheme HTML crawl finished with ${schemes.length} schemes.');
  } on Exception catch (e) {
    logger.error('MyScheme crawl failed: $e');
    exitCode = 1;
  }
}
