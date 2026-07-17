/// Shared constants used across the crawling and build pipeline.
library;

/// User agent sent with every outbound HTTP request.
const String kUserAgent =
    'GovSchemeDbBuilder/2.0 (+https://github.com/neerjaRaju/myschemedbbuilder)';

/// Root data directory.
const String kDataDir = 'data';

/// Directory for the persistent API response cache.
const String kCacheDir = '$kDataDir/cache';

/// Directory where each crawler writes its generated JSON dataset.
const String kGeneratedDir = '$kDataDir/generated';

/// Directory for the merged, validated master dataset.
const String kProcessedDir = '$kDataDir/processed';

/// Directory for final build artifacts (SQLite database).
const String kOutputDir = '$kDataDir/output';

/// Path of the merged master dataset.
const String kMasterDatasetPath = '$kProcessedDir/schemes_master.json';

/// Path of the final SQLite database.
const String kDatabasePath = '$kOutputDir/schemes.db';

/// Directory containing per-source crawl configuration files.
const String kSourcesDir = 'sources';

/// Default HTTP request timeout. Some government portals are slow to
/// respond from data-center IPs, so this is deliberately generous.
const Duration kHttpTimeout = Duration(seconds: 45);

/// Default cache time-to-live. Pages younger than this are not re-fetched,
/// which is what makes repeated crawls incremental.
const Duration kCacheTtl = Duration(days: 7);

/// Number of rows inserted per multi-row SQL statement.
const int kInsertBatchSize = 250;

/// How often (in pages) crawl progress is reported.
const int kProgressInterval = 25;
