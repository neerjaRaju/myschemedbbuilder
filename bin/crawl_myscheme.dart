import 'dart:io';
import '../lib/crawler/cache_manager.dart';
import '../lib/crawler/crawler.dart';
import '../lib/crawler/rate_limiter.dart';
import '../lib/extractor/scheme_extractor.dart';
import '../lib/models/scheme.dart';
import '../lib/parser/json_parser.dart';

void main() async {
  print('==================================================');
  print('Starting MyScheme Crawler');
  print('==================================================');

  final cache = CacheManager(path: 'data/cache/myscheme');
  final rateLimiter = RateLimiter(
    maxRequests: 5,
    interval: const Duration(seconds: 1),
  );
  final crawler = ProductionCrawler(cache: cache, rateLimiter: rateLimiter);

  // Define seed crawl URLs
  final seedUrls = [
    'https://www.myscheme.gov.in/schemes/pm-kisan',
    'https://www.myscheme.gov.in/schemes/pm-shram-yogi-maan-dhan',
    'https://www.myscheme.gov.in/schemes/ayushman-bharat-jan-arogyha-yojana',
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
          print('Successfully crawled & processing: ${result.url}');
          final scheme = SchemeExtractor.extract(
            html: result.content!,
            sourceUrl: result.url,
            defaultState: 'Central',
            defaultMinistry:
                'Ministry of Electronics and Information Technology',
          );
          extractedSchemes.add(scheme);
        }
      },
    );

    print('\nCrawled ${extractedSchemes.length} schemes from MyScheme.');

    // Save outputs
    final outputPath = 'data/generated/myscheme_schemes.json';
    JsonParser.writeToFile(outputPath, extractedSchemes);
    print('Results saved to $outputPath');
  } finally {
    rateLimiter.dispose();
  }
}
