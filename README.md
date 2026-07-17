# Government Scheme Database Builder

Builds an offline SQLite database (`schemes.db`) of Indian government
schemes from [MyScheme](https://www.myscheme.gov.in), the Government of
India's official scheme portal, which covers both central and state
schemes.

The repository also contains a Flutter app (in [`app/`](app/)) that
downloads this database and provides offline browsing, search, smart
filters, an eligibility checker, bookmarks, comparison and 11 languages.
See [`app/README.md`](app/README.md).

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
dart run bin/build_master_dataset.dart  # data/processed/schemes_master.json
dart run bin/build_database.dart        # data/output/schemes.db
dart run bin/update_database.dart       # incremental sync of an existing db
```

## Data source

All data comes from the official MyScheme public JSON API
(`api.myscheme.gov.in`) — the same endpoints, headers and public API key
the myscheme.gov.in website itself uses. The crawler:

- enumerates every scheme slug through the paginated search endpoint
- fetches each scheme's full detail payload
- caches API responses on disk with a TTL (repeat runs are incremental)
- rate-limits requests and retries transient failures with exponential
  backoff and jitter
- reports progress as it goes

Endpoints, API key, page size and rate limit are configured in
`sources/myscheme.json`.

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
  dispatch) re-crawls MyScheme, rebuilds the master dataset and SQLite
  database, and commits the refreshed artifacts as `github-actions[bot]`
  (rebasing onto the latest `main` before pushing, since the crawl takes
  a while and `main` may move mid-run).

## Development

```bash
dart format .
dart analyze
dart test
```
