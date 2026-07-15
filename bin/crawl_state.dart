import 'dart:io';
import '../lib/crawler/cache_manager.dart';
import '../lib/crawler/crawler.dart';
import '../lib/crawler/rate_limiter.dart';
import '../lib/extractor/scheme_extractor.dart';
import '../lib/models/scheme.dart';
import '../lib/parser/json_parser.dart';

void main() async {
  print('==================================================');
  print('Starting Regional State Portals Crawler');
  print('==================================================');

  final cache = CacheManager(path: 'data/cache/state_portals');
  final rateLimiter = RateLimiter(
    maxRequests: 2,
    interval: const Duration(seconds: 1),
  );
  final crawler = ProductionCrawler(cache: cache, rateLimiter: rateLimiter);

  // Simulated state portal schema seeds
  final seedUrls = [
    'https://sanjeevani.rajasthan.gov.in/schemes/bhamashah',
    'https://mahadbt.maharashtra.gov.in/schemes/scholarship',
  ];

  for (var url in seedUrls) {
    crawler.queueUrl(url);
  }

  final List<Scheme> extractedSchemes = [];

  try {
    await crawler.start(
      onPageDownloaded: (result) {
        if (result.error != null) {
          stderr.writeln('Download Error [${result.url}]: ${result.error}');
          return;
        }

        if (result.content != null) {
          // Attempt to dynamically resolve state from domain structures
          final resolvedState = result.url.contains('rajasthan')
              ? 'Rajasthan'
              : 'Maharashtra';

          print('Extracting $resolvedState Scheme from: ${result.url}');
          final scheme = SchemeExtractor.extract(
            html: result.content!,
            sourceUrl: result.url,
            defaultState: resolvedState,
            defaultMinistry: 'Department of Social Justice',
          );
          extractedSchemes.add(scheme);
        }
      },
    );

    final outputPath = 'data/generated/state_schemes.json';
    JsonParser.writeToFile(outputPath, extractedSchemes);
    print('Successfully generated: $outputPath');
  } finally {
    rateLimiter.dispose();
  }
}
