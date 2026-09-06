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
- `mcp_server/` - bonus: exposes the same dbt documentation and the database as MCP tools.
- `data/` - the raw CSV as provided (also seeded into the dbt project from `loadsmart/seeds/`).

## How to reproduce

### Python environment

```
pip install dbt-core dbt-duckdb duckdb pandas requests jupyter nbconvert nbformat
```

### Build the dbt project

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

### Run the text-to-SQL notebook

Requires a local [Ollama](https://ollama.com) instance with the model pulled:

```
ollama pull qwen2.5-coder:7b
```

Then open `text_to_sql.ipynb` and run all cells, or execute it headlessly:

```
jupyter nbconvert --to notebook --execute --inplace text_to_sql.ipynb
```

The notebook builds its schema context programmatically from `loadsmart/target/manifest.json`
(dbt's documentation), so the dbt project has to be built before this runs.

Ollama runs unauthenticated on `localhost:11434` - there's no API key or credential involved,
so there's nothing to put in an environment variable and nothing sensitive committed to the repo.

### Run the CSV export notebook

Also needs the dbt project built, since it reads straight from `loadsmart/dev.duckdb`:

```
cd csv_exporter
jupyter nbconvert --to notebook --execute --inplace csv_exporter.ipynb
```

Writes `csv_exporter/delivered_loads_last_month.csv`. Note this notebook reads "last available
month" literally against the raw data (March 2025, which only has 1 row) - a different question
than "last full month" (December 2024), which is what the AI notebook's first question uses.

### MCP server (bonus)

`mcp_server/server.py` turns the model into an MCP server, so instead of going through the
notebook, an MCP client can query it directly. It exposes two tools:

- `get_schema` - hands back the dbt documentation, built from `manifest.json`. Same contract the
  notebook uses, just served a different way.
- `run_sql` - runs a DuckDB query against the dimensional model.

It needs the dbt project built first, since it reads `manifest.json` and `dev.duckdb`. Plus the
SDK:

```
pip install mcp
```

`.mcp.json` in the repo root is what registers the server:

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

I'm on Windows, so that's the path to the venv interpreter here. On macOS or Linux, swap it for
`venv/bin/python`. The double backslashes are just JSON escaping - the value that actually gets
used is `venv\Scripts\python.exe`. If the client still can't find the interpreter, put the full
absolute path in there.

#### Using a different MCP client

`.mcp.json` at the repo root is the Claude Code convention, but nothing about the server is tied
to it - it's a plain stdio MCP server, so any client that speaks the protocol works. The same
`mcpServers` block above goes wherever your client keeps its config (`claude_desktop_config.json`
for Claude Desktop, `.cursor/mcp.json` for Cursor, and so on - check your client's docs for the
path). VS Code is the one I'd watch out for, since it uses a `servers` key instead of
`mcpServers`.

`server.py` works out its own paths from its file location, so it doesn't matter which folder the
client launches it from. I tested it from the repo root, from inside subfolders, and from the
drive root, and it connects the same way each time.

#### Querying it

Once the config is in place, restart the MCP client and it picks the server up on startup. There's
nothing to run by hand. `server.py` is a stdio server, so if you do launch it yourself it just
sits there quietly waiting for a client to talk to it - that's it working, not hanging.

From there you just ask questions in plain English and the client calls the tools on its own:

- "Which carrier moved the most loads into Texas?"
- "What is the average book price by pickup state?"
- "Compare profit per load across equipment types"

It usually calls `get_schema` first to learn the tables, then writes its own SQL and sends it
through `run_sql`. I ran all 8 of the challenge questions this way and got the same answers as the
notebook, which is really the point - both of them are reading the same `schema.yml`.

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
