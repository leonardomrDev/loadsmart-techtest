WITH lanes AS (
    SELECT DISTINCT
        lane
        ,pickup_city
        ,pickup_state
        ,delivery_city
        ,delivery_state
    FROM {{ref('stg_loadsmart')}}
    WHERE lane IS NOT NULL
)

SELECT
    md5(lane) AS lane_key
    ,lane
    ,pickup_city
    ,pickup_state
    ,delivery_city
    ,delivery_state
FROM lanes