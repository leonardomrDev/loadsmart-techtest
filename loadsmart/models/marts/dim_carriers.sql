WITH carriers AS (
    SELECT DISTINCT
        COALESCE(carrier_name, 'UNKNOWN') as carrier_name
        ,vip_carrier
    FROM {{ref('stg_loadsmart')}}
    --WHERE carrier_name IS NOT NULL
)

SELECT
    md5(carrier_name) AS carrier_key
    ,carrier_name
    ,vip_carrier
FROM carriers