# Changelog

## 2.0.0

- Production rewrite of the whole pipeline.
- MyScheme is now crawled through its official public JSON API with an HTML
  fallback; india.gov.in and state portals are crawled with link discovery.
- Crawler gained a persistent resumable queue, on-disk caching with TTL,
  robots.txt compliance, token-bucket rate limiting, retry with exponential
  backoff, concurrent workers and progress reporting.
- Source portals are configured declaratively in `sources/*.json`.
- SQLite output uses WAL, FTS5 full-text search, batched multi-row inserts,
  normalized tag table with foreign keys, indexes, `VACUUM` and `ANALYZE`.
- Incremental `update_database` sync (hash-based upserts and deletions).
- Deterministic JSON and SQLite exports.
- Full unit-test suite and CI (format, analyze, test) plus a weekly GitHub
  Actions workflow that rebuilds and commits the database.

## 1.0.0

- Initial version.
