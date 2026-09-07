import duckdb

con = duckdb.connect('../loadsmart/dev.duckdb', read_only=True)

for table in ['fact_loadsmart', 'dim_shippers', 'dim_carriers', 'dim_lanes']:
    con.execute(f"COPY {table} TO '{table}.csv' (HEADER, DELIMITER ',')")
    print(table, 'exported')
