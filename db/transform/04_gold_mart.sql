-- 1. Membuat View Trip Enhanced 

CREATE OR REPLACE VIEW gold.vw_trip_enriched AS
SELECT
    trip.trip_id,
    trip.vendor_id,
    trip.pickup_datetime,
    trip.dropoff_datetime,
    trip.pickup_date,
    trip.pickup_hour,
    trip.pickup_day_name,
    trip.is_weekend,
    trip.time_period,
    trip.trip_duration_minutes,
    trip.passenger_count,
    trip.trip_distance,
    trip.ratecode_id,
    trip.store_and_fwd_flag,
    trip.store_and_fwd_label,

    trip.pickup_location_id,
    pickup_zone.borough AS pickup_borough,
    pickup_zone.zone AS pickup_zone,
    pickup_zone.service_zone AS pickup_service_zone,

    trip.dropoff_location_id,
    dropoff_zone.borough AS dropoff_borough,
    dropoff_zone.zone AS dropoff_zone,
    dropoff_zone.service_zone AS dropoff_service_zone,

    trip.payment_type_id,
    trip.payment_type_label,
    trip.fare_amount,
    trip.extra,
    trip.mta_tax,
    trip.tip_amount,
    trip.tolls_amount,
    trip.improvement_surcharge,
    trip.total_amount,
    trip.congestion_surcharge,
    trip.airport_fee,
    trip.cbd_congestion_fee

FROM silver.taxi_trips_cleaned AS trip

LEFT JOIN silver.taxi_zones AS pickup_zone
    ON pickup_zone.location_id = trip.pickup_location_id

LEFT JOIN silver.taxi_zones AS dropoff_zone
    ON dropoff_zone.location_id = trip.dropoff_location_id;


-- 2. Membuat View Daily Trip Summary 

CREATE OR REPLACE VIEW gold.vw_daily_trip_summary AS
SELECT
    pickup_date,
    COUNT(pickup_date) AS total_trips,
    SUM(total_amount) AS total_revenue,
    AVG(fare_amount) AS average_fare,
    AVG(trip_distance) AS average_distance,
    AVG(trip_duration_minutes) AS average_duration,
    AVG(passenger_count) AS average_passenger

FROM silver.taxi_trips_cleaned
GROUP BY pickup_date;


-- 3. Membuat view Zone Performance
CREATE OR REPLACE VIEW gold.vw_zone_performance AS

WITH pickup_data AS (
    SELECT
        pickup_location_id AS location_id,
        pickup_borough AS borough,
        pickup_zone AS zone,
        pickup_service_zone AS service_zone,
        COUNT(pickup_datetime) AS total_pickup_trips,
        SUM(total_amount) AS total_revenue,
        AVG(fare_amount) AS average_fare,
        AVG(tip_amount) AS average_tip
    FROM silver.taxi_trips_cleaned
    GROUP BY 
        pickup_location_id,
        pickup_borough,
        pickup_zone,
        pickup_service_zone
),

dropoff_data AS(
    SELECT
        dropoff_location_id AS location_id,
        COUNT(dropoff_datetime) AS total_dropoff_trips
    FROM silver.taxi_trips_cleaned
    GROUP BY dropoff_location_id
)

SELECT
    pickup_data.location_id,
    pickup_data.borough,
    pickup_data.zone,
    pickup_data.service_zone,
    pickup_data.total_pickup_trips,
    dropoff_data.total_dropoff_trips,
    pickup_data.total_revenue,
    pickup_data.average_fare,
    pickup_data.average_tip

FROM pickup_data
LEFT JOIN dropoff_data
    ON pickup_data.location_id = dropoff_data.location_id










    
    

