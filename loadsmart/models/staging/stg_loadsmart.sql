WITH source AS (
    SELECT * FROM {{ ref('2026_data_challenge_ae_data') }}
),

source_cleaned AS (
    SELECT
        loadsmart_id
        ,lane
        ,TRIM(SPLIT_PART(SPLIT_PART(lane, ' -> ', 1), ',', 1)) AS pickup_city
        ,UPPER(TRIM(SPLIT_PART(SPLIT_PART(lane, ' -> ', 1), ',', 2))) AS pickup_state
        ,TRIM(SPLIT_PART(SPLIT_PART(lane, ' -> ', 2), ',', 1)) AS delivery_city
        ,UPPER(TRIM(SPLIT_PART(SPLIT_PART(lane, ' -> ', 2), ',', 2))) AS delivery_state
        ,TRY_STRPTIME(quote_date, '%-m/%-d/%Y %-H:%M') AS quote_date
        ,TRY_STRPTIME(book_date, '%-m/%-d/%Y %-H:%M') AS book_date
        ,TRY_STRPTIME(source_date, '%-m/%-d/%Y %-H:%M') AS source_date
        ,TRY_STRPTIME(pickup_date, '%-m/%-d/%Y %-H:%M') AS pickup_date
        ,TRY_STRPTIME(delivery_date, '%-m/%-d/%Y %-H:%M') AS delivery_date
        ,CAST(book_price AS double) AS book_price
        ,CAST(source_price AS double) AS source_price
        ,CAST(pnl AS double) AS pnl
        ,CAST(mileage AS double) AS mileage
        ,equipment_type
        ,carrier_rating
        ,sourcing_channel
        ,vip_carrier
        ,CAST(carrier_dropped_us_count AS INTEGER) AS carrier_dropped_us_count
        ,carrier_name
        ,shipper_name
        ,carrier_on_time_to_pickup
        ,carrier_on_time_to_delivery
        ,carrier_on_time_overall
        ,TRY_STRPTIME(pickup_appointment_time, '%-m/%-d/%Y %-H:%M') AS pickup_appointment_time
        ,TRY_STRPTIME(delivery_appointment_time, '%-m/%-d/%Y %-H:%M') AS delivery_appointment_time
        ,has_mobile_app_tracking
        ,has_macropoint_tracking
        ,has_edi_tracking
        ,contracted_load
        ,load_booked_autonomously
        ,load_sourced_autonomously
        ,load_was_cancelled
        ,ROW_NUMBER() OVER(PARTITION BY loadsmart_id ORDER BY book_date DESC) AS rn
    FROM source
)

SELECT * exclude(rn) FROM source_cleaned WHERE rn = 1