WITH carriers AS (
    SELECT DISTINCT
        carrier_name
    FROM {{ref('stg_loadsmart')}}
    WHERE carrier_name IS NOT NULL
)

SELECT
    md5(carrier_name) AS carrier_key
    ,carrier_name
FROM carriers