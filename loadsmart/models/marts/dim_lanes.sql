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
    md5(l.lane) AS lane_key
    ,l.lane
    ,l.pickup_city
    ,l.pickup_state
    ,p.state_name AS pickup_state_name
    ,l.delivery_city
    ,l.delivery_state
    ,d.state_name AS delivery_state_name
FROM lanes l
LEFT JOIN {{ref('us_states')}} p ON l.pickup_state = p.state_code
LEFT JOIN {{ref('us_states')}} d ON l.delivery_state = d.state_code