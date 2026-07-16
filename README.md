# Government Scheme Database Builder

Builds an offline SQLite database (`schemes.db`) of Indian government
schemes from official sources: [MyScheme](https://www.myscheme.gov.in),
[india.gov.in](https://www.india.gov.in) and official state government
scheme portals.

## Pipeline

```
Official Sources → Crawler → Cache → Extractor → Normalizer → Validator
→ Duplicate Removal → Generated JSON → Master Dataset → SQLite Builder
→ schemes.db
```

Each stage is a standalone Dart entrypoint:

```bash
dart pub get

dart run bin/crawl_myscheme.dart        # data/generated/myscheme_schemes.json
dart run bin/crawl_india_gov.dart       # data/generated/india_gov_schemes.json
dart run bin/crawl_state.dart           # data/generated/state_schemes.json

dart run bin/build_master_dataset.dart  # data/processed/schemes_master.json
dart run bin/build_database.dart        # data/output/schemes.db
dart run bin/update_database.dart       # incremental sync of an existing db
```

## Crawling

Crawl behavior is configured per source in `sources/*.json` (seed URLs,
sitemaps, URL allow/detail patterns, rate limits, page caps, state-by-domain
mapping). The crawler provides:

- persistent resumable URL queue (interrupted crawls continue where they stopped)
- on-disk page cache with TTL (repeat runs are incremental)
- robots.txt compliance and per-source rate limiting
- retry with exponential backoff and jitter
- concurrent download workers with progress reporting
- duplicate URL elimination via URL normalization

MyScheme is client-rendered, so its crawler uses the portal's official
public JSON API (the same endpoints and public API key the website itself
uses), with HTML crawling as a fallback.

## Data quality

Every record is normalized (whitespace, HTML, unicode, bullet lists, dates,
URLs, phone numbers), validated (required fields, URL format, dates, empty
content) and de-duplicated (exact URL, content hash, and >90% title
similarity within the same state and ministry). Exports are deterministic:
identical inputs produce byte-identical JSON and SQLite outputs.

## Database

`data/output/schemes.db` is built with WAL mode, foreign keys, batched
multi-row inserts via prepared statements, indexes on searchable columns, a
normalized `scheme_tags` table, an FTS5 full-text index (`schemes_fts`)
kept in sync by triggers, and a final `ANALYZE` + `VACUUM`.

Full-text search example:

```sql
SELECT s.title, s.state
FROM schemes s JOIN schemes_fts f ON f.id = s.id
WHERE schemes_fts MATCH 'farmer income support'
ORDER BY rank LIMIT 10;
```

## Automation

- `.github/workflows/test.yml` — format check, static analysis and tests on
  every push and pull request.
- `.github/workflows/build_database.yml` — every Sunday (and on manual
  dispatch) re-crawls all sources, rebuilds the master dataset and SQLite
  database, and commits the refreshed artifacts as `github-actions[bot]`.

## Development

```bash
dart format .
dart analyze
dart test
```
