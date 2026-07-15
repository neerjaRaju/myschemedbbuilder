import 'dart:io';
import '../lib/crawler/cache_manager.dart';
import '../lib/crawler/crawler.dart';
import '../lib/crawler/rate_limiter.dart';
import '../lib/extractor/scheme_extractor.dart';
import '../lib/models/scheme.dart';
import '../lib/parser/json_parser.dart';

void main() async {
  print('==================================================');
  print('Starting India Gov Portal Crawler');
  print('==================================================');

  final cache = CacheManager(path: 'data/cache/india_gov');
  final rateLimiter = RateLimiter(
    maxRequests: 3,
    interval: const Duration(seconds: 1),
  );
  final crawler = ProductionCrawler(cache: cache, rateLimiter: rateLimiter);

  final seedUrls = [
    'https://www.india.gov.in/schemes/national-social-assistance-programme',
    'https://www.india.gov.in/schemes/pradhan-mantri-awas-yojana-gramin',
  ];

  for (var url in seedUrls) {
    crawler.queueUrl(url);
  }

  final List<Scheme> extractedSchemes = [];

  try {
    await crawler.start(
      onPageDownloaded: (result) {
        if (result.error != null) {
          stderr.writeln('Failed to download [${result.url}]: ${result.error}');
          return;
        }

        if (result.content != null) {
          print('Processing parsed model: ${result.url}');
          final scheme = SchemeExtractor.extract(
            html: result.content!,
            sourceUrl: result.url,
            defaultState: 'Central',
            defaultMinistry: 'Ministry of Rural Development',
          );
          extractedSchemes.add(scheme);
        }
      },
    );

    final outputPath = 'data/generated/india_gov_schemes.json';
    JsonParser.writeToFile(outputPath, extractedSchemes);
    print('Successfully generated: $outputPath');
  } finally {
    rateLimiter.dispose();
  }
}
