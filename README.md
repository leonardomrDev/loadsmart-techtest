# loadsmart-techtest

Analytics Engineer challenge: a dbt star schema over the provided loads dataset (DuckDB), plus a
text-to-SQL notebook that queries that model using a local LLM.

## Project layout

- `loadsmart/` - the dbt project (staging + marts models, tests, documentation).
- `text_to_sql.ipynb` - natural-language question -> generated SQL -> answer, run against the
  dbt model. Also has the results table, the 2 stakeholder questions, the question the model
  can't answer, and the iteration log.
- `csv_exporter/` - Python skills deliverable: a notebook that reads the dbt model and exports
  delivered loads for the last available month to CSV.
- `data/` - the raw CSV as provided (also seeded into the dbt project from `loadsmart/seeds/`).

## How to reproduce

### 1. Python environment

```
pip install dbt-core dbt-duckdb duckdb pandas requests jupyter nbconvert nbformat
```

### 2. Build the dbt project

```
cd loadsmart
dbt seed
dbt run
dbt test
dbt docs generate
cd ..
```

This creates `loadsmart/dev.duckdb` and `loadsmart/target/manifest.json`, which the notebook
reads. `dbt seed` is required first - without it there's no data loaded yet.

dbt looks for `profiles.yml` at `~/.dbt/profiles.yml` by default. This project's profile:

```yaml
loadsmart:
  outputs:
    dev:
      type: duckdb
      path: dev.duckdb
      threads: 1
  target: dev
```

### 3. Run the text-to-SQL notebook

Requires a local [Ollama](https://ollama.com) instance with the model pulled:

```
ollama pull qwen2.5-coder:7b
```

Then open `text_to_sql.ipynb` and run all cells, or execute it headlessly:

```
jupyter nbconvert --to notebook --execute --inplace text_to_sql.ipynb
```

The notebook builds its schema context programmatically from `loadsmart/target/manifest.json`
(dbt's documentation), so it must be run after step 2.

Ollama runs unauthenticated on `localhost:11434` - there's no API key or credential involved,
so there's nothing to put in an environment variable and nothing sensitive committed to the repo.

### 4. Run the CSV export notebook

Also requires step 2 (reads directly from `loadsmart/dev.duckdb`):

```
cd csv_exporter
jupyter nbconvert --to notebook --execute --inplace csv_exporter.ipynb
```

Writes `csv_exporter/delivered_loads_last_month.csv`. Note this notebook reads "last available
month" literally against the raw data (March 2025, which only has 1 row) - a different question
than "last full month" (December 2024), which is what the AI notebook's first question uses.

## Data quality notes

The most important findings from the raw CSV (full detail in `models/staging/schema.yml` and
`models/marts/schema.yml`, since that's what the AI notebook actually reads):

- Raw datetime columns are text in `M/D/YYYY H:MM` format. A plain
  `TRY_CAST(... AS TIMESTAMP)` returns NULL for every row, for that reason, staging uses
  `TRY_STRPTIME(col, '%-m/%-d/%Y %-H:%M')` instead.
- A handful of `loadsmart_id`s appear twice in the bronze layer as row duplicates. Staging keeps one row per id.
- `delivery_date` exists even for cancelled loads, so it cant be used to detect whether a
  load was actually delivered. Created `load_was_cancelled` for that reason.
- Data volume drops off after December 2024 (January 2025 has partial data, February 2025 comes empty,
  a single stray row in March 2025), so "the last full month available in the data" is December
  2024.
- The raw header has `has_mobile_app_tracking` twice (DuckDB loads the second copy as
  `has_mobile_app_tracking_2`). Checked all rows - the two columns are identical everywhere
  (always FALSE), so staging only keeps one; no data is lost.

## dbt model

Star schema: `fact_loadsmart` joined to `dim_shippers`, `dim_carriers`, `dim_lanes`. 
Every column in every model (staging and marts) is documented in `schema.yml`, since
that documentation is what the text-to-SQL notebook reads to build its schema context.
