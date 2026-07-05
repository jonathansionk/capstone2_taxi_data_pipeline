-- Membuat raw tables

CREATE TABLE IF NOT EXISTS bronze.raw_taxi_trips(
    trip_id SERIAL PRIMARY KEY,

    vendor_id INT,
    pickup_datetime TIMESTAMP,
    dropoff_datetime TIMESTAMP,
    passenger_count INT,
    trip_distance FLOAT,
    ratecode_id INT,
    store_and_fwd_flag TEXT,
    pickup_location_id INT,
    dropoff_location_id INT,
    payment_type INT,
    fare_amount FLOAT,
    extra FLOAT,
    mta_tax FLOAT,
    tip_amount FLOAT,
    tolls_amount FLOAT,
    improvement_surcharge FLOAT,
    total_amount FLOAT,
    congestion_surcharge FLOAT,
    airport_fee FLOAT,
    cbd_congestion_fee FLOAT
);


CREATE TABLE IF NOT EXISTS bronze.raw_taxi_zones (
    location_id INT PRIMARY KEY,
    borough TEXT,
    zone TEXT,
    service_zone TEXT
);