WITH shippers AS (
    SELECT DISTINCT
        shipper_name
    FROM {{ref ('stg_loadsmart')}}
    WHERE shipper_name IS NOT NULL
)

SELECT 
    md5(shipper_name) AS shipper_key
    ,shipper_name

FROM shippers