SELECT
    loadsmart_id
    ,md5(shipper_name) AS shipper_key
    ,md5(carrier_key) AS carrier_key
    ,md5(lane) AS lane_key
    ,pickup_city
    ,pickup_state
    ,delivery_city
    ,delivery_state
    ,quote_date
    ,book_date
    ,source_date
    ,pickup_date
    ,delivery_date
    ,book_price
    ,source_price
    ,pnl
    ,mileage
    ,equipment_type
    ,carrier_rating
    ,sourcing_channel
    ,vip_carrier
    ,carrier_dropped_us_count
    ,carrier_on_time_to_pickup
    ,carrier_on_time_to_delivery
    ,carrier_on_time_overall
    ,pickup_appointment_time
    ,delivery_appointment_time
    ,has_mobile_app_tracking
    ,has_macropoint_tracking
    ,has_edi_tracking
    ,contracted_load
    ,load_booked_autonomously
    ,load_sourced_autonomously
    ,load_was_cancelled
FROM {{ref('stg_loadsmart')}}
     