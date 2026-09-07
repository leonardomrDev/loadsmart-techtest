# loadsmart-techtest

Analytics Engineer challenge: a dbt star schema over the loads dataset (DuckDB), plus a
text-to-SQL notebook that queries it with a local LLM.

## Project layout

- `loadsmart/` - the dbt project (staging + marts, tests, documentation).
- `text_to_sql.ipynb` - question, generated SQL by the model, answer. Also has the results table, the
  2 stakeholder questions, the question the model can't answer, and the iteration log.
- `csv_exporter/` - notebook that exports delivered loads for the last available month to CSV.
- `mcp_server/` - the same model exposed as MCP tools.
- `powerbi/` - the report, plus the script that exports the CSVs it reads.
- `data/` - the raw CSV dataset provided.

## How to reproduce

### 1. Install

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
```

This creates `dev.duckdb` and `target/manifest.json`. Everything else depends on this step.

dbt reads `~/.dbt/profiles.yml`. This project's profile:

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

Needs [Ollama](https://ollama.com) running locally:

```
ollama pull qwen2.5-coder:14b
```

It has to be 14b. On 7b the geography questions fail, since it writes `pickup_state` off the fact
table instead of joining with `dim_lanes`.

```
jupyter nbconvert --to notebook --execute --inplace text_to_sql.ipynb
```

Ollama is local and requires no auth, so there's no API key anywhere and nothing to put in an
env variable.

### 4. Run the CSV export notebook

```
cd csv_exporter
jupyter nbconvert --to notebook --execute --inplace csv_exporter.ipynb
```

Creates the file `delivered_loads_last_month.csv`. The script queries "last available month" against
the raw data (March 2025, which only has 1 row).

### 5. MCP server

`mcp_server/server.py` creates an MCP that enables an MCP client to query the server with two tools: `get_schema`, which
returns the dbt documentation built from `manifest.json`, and `run_sql`, which runs a DuckDB
query. Needs `pip install mcp`.

`.mcp.json` registers it:

```json
{
  "mcpServers": {
    "loadsmart": {
      "command": "venv\\Scripts\\python.exe",
      "args": ["mcp_server/server.py"]
    }
  }
}
```

That is the Windows path to the virtual environment `venv/bin/python`.

## Data quality notes

The main findings from the raw CSV. Full detail is in `models/staging/schema.yml` and
`models/marts/schema.yml`, since that is what the notebook actually reads:

- Raw datetime columns are text in `M/D/YYYY H:MM` format. A plain `TRY_CAST(... AS TIMESTAMP)`
  returns NULL for every row, so staging uses `TRY_STRPTIME(col, '%-m/%-d/%Y %-H:%M')` instead.
- A handful of `loadsmart_id`s appear twice as row duplicates. Staging keeps one row per id.
- `delivery_date` is filled in even for cancelled loads, so it can't be used to tell whether a
  load was actually delivered. That is what `load_was_cancelled` is for.
- Volume drops off after December 2024 (January is partial, February is empty, March has a single
  row), so "the last full month available in the data" is December 2024.
- The raw header has `has_mobile_app_tracking` twice. Checked every row - the two copies are
  identical (always FALSE), so staging keeps one and nothing is lost.

## dbt model

Star schema: `fact_loadsmart` joined to `dim_shippers`, `dim_carriers`, `dim_lanes`. The fact
carries keys and measures only. Names, cities and states live in the dimensions. Every column
is documented in `schema.yml`, because that documentation is used by the LLM.
