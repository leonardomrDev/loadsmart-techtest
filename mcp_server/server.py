import json
import os
import duckdb
from mcp.server import MCPServer

mcp = MCPServer("loadsmart")

# repo root, so the paths still work whatever folder the client starts the server from
root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
manifest = json.load(open(os.path.join(root, 'loadsmart/target/manifest.json'), encoding='utf-8'))

@mcp.tool()
def get_schema() -> str:
    "dbt documentation"
    models = [m for m in manifest['nodes'].values() if m['resource_type'] == 'model']

    return json.dumps({m['name']: m['columns'] for m in models}, indent=2)

@mcp.tool()
def run_sql(query: str) -> str:
    "runs a DuckDB SQL query on the dimensional model"
    return duckdb.connect(
        os.path.join(root, 'loadsmart/dev.duckdb'),
        read_only=True).execute(query).fetchdf().to_string()

mcp.run()