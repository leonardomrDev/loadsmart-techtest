SELECT
    loadsmart_id
    ,md5(COALESCE(shipper_name, 'UNKNOWN')) AS shipper_key
    ,md5(COALESCE(carrier_name, 'UNKNOWN')) as carrier_key
    ,md5(COALESCE(lane, 'UNKNOWN')) AS lane_key
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
     