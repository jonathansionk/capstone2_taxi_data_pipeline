-- Membuat Tabel Silver Taxi Trip
CREATE TABLE IF NOT EXISTS silver.taxi_trips_cleaned (
    trip_id INT PRIMARY KEY,

    vendor_id INTEGER,
    pickup_datetime TIMESTAMP,
    dropoff_datetime TIMESTAMP,

    -- Kolom turunan
    pickup_date DATE,
    pickup_hour SMALLINT,
    pickup_day_name TEXT,
    is_weekend BOOLEAN,
    time_period VARCHAR(30),
    trip_duration_minutes NUMERIC(12, 2),

    passenger_count INTEGER,
    trip_distance NUMERIC(12, 3),
    ratecode_id INTEGER,

    -- Store and forward
    store_and_fwd_flag TEXT,
    store_and_fwd_label VARCHAR(50),

    -- Mapping pickup
    pickup_location_id INTEGER,
    pickup_borough TEXT,
    pickup_zone TEXT,
    pickup_service_zone TEXT,

    -- Mapping dropoff
    dropoff_location_id INTEGER,
    dropoff_borough TEXT,
    dropoff_zone TEXT,
    dropoff_service_zone TEXT,

    -- Mapping payment
    payment_type_id SMALLINT,
    payment_type_label VARCHAR(50),

    -- Nilai pembayaran
    fare_amount NUMERIC(14, 2),
    extra NUMERIC(14, 2),
    mta_tax NUMERIC(14, 2),
    tip_amount NUMERIC(14, 2),
    tolls_amount NUMERIC(14, 2),
    improvement_surcharge NUMERIC(14, 2),
    total_amount NUMERIC(14, 2),
    congestion_surcharge NUMERIC(14, 2),
    airport_fee NUMERIC(14, 2),
    cbd_congestion_fee NUMERIC(14, 2)
);

-- Membuat Truncate table agar tidak duplikat saat dijalankan berulang

TRUNCATE TABLE silver.taxi_trips_cleaned;



-- Membuat Tabel Silver Taxi Zone
CREATE TABLE IF NOT EXISTS silver.taxi_zones(
    location_id INT PRIMARY KEY,
    borough TEXT,
    zone TEXT,
    service_zone TEXT
);

-- Membuat Truncate table agar tidak duplikat saat dijalankan berulang

TRUNCATE TABLE silver.taxi_zones;





-- Load Taxi Zone dari Bronze Ke Silver

INSERT INTO silver.taxi_zones(
    location_id,
    borough,
    zone,
    service_zone
)
SELECT 
    location_id,
    borough,
    zone,
    service_zone
FROM bronze.raw_taxi_zones
WHERE location_id IS NOT NULL;

-- Transformasi Bronze ke 

INSERT INTO silver.taxi_trips_cleaned (
    trip_id,
    vendor_id,

    pickup_datetime,
    dropoff_datetime,

    pickup_date,
    pickup_hour,
    pickup_day_name,
    is_weekend,
    time_period,
    trip_duration_minutes,

    passenger_count,
    trip_distance,
    ratecode_id,

    store_and_fwd_flag,
    store_and_fwd_label,

    pickup_location_id,
    pickup_borough,
    pickup_zone,
    pickup_service_zone,

    dropoff_location_id,
    dropoff_borough,
    dropoff_zone,
    dropoff_service_zone,

    payment_type_id,
    payment_type_label,

    fare_amount,
    extra,
    mta_tax,
    tip_amount,
    tolls_amount,
    improvement_surcharge,
    total_amount,
    congestion_surcharge,
    airport_fee,
    cbd_congestion_fee
)

SELECT
    trip.trip_id,
    trip.vendor_id,

    trip.pickup_datetime,
    trip.dropoff_datetime,

    -- 1. Mengambil tanggal pickup
    trip.pickup_datetime::DATE AS pickup_date,

    -- 2. Mengambil jam pickup
    EXTRACT(
        HOUR FROM trip.pickup_datetime
    )::SMALLINT AS pickup_hour,

    -- 3. Mengambil nama hari
    TO_CHAR(
        trip.pickup_datetime,
        'FMDay'
    ) AS pickup_day_name,

    -- 4. Menentukan weekday atau weekend
    CASE
        WHEN EXTRACT(ISODOW FROM trip.pickup_datetime) IN (6, 7) THEN TRUE
        ELSE FALSE
    END AS is_weekend,

    -- 5. Membuat kelompok waktu
    CASE
        WHEN EXTRACT(HOUR FROM trip.pickup_datetime)
            BETWEEN 0 AND 5
            THEN 'Late Night'

        WHEN EXTRACT(HOUR FROM trip.pickup_datetime)
            BETWEEN 7 AND 9
            THEN 'Morning Rush'

        WHEN EXTRACT(HOUR FROM trip.pickup_datetime)
            BETWEEN 6 AND 10
            THEN 'Morning'

        WHEN EXTRACT(HOUR FROM trip.pickup_datetime)
            BETWEEN 11 AND 15
            THEN 'Afternoon'

        WHEN EXTRACT(HOUR FROM trip.pickup_datetime)
            BETWEEN 16 AND 19
            THEN 'Evening Rush'

        ELSE 'Night'
    END AS time_period,

    -- 6. Menghitung durasi perjalanan dalam menit
    ROUND(
        (
            EXTRACT(
                EPOCH FROM (
                    trip.dropoff_datetime
                    - trip.pickup_datetime
                )
            ) / 60
        )::NUMERIC,
        2
    ) AS trip_duration_minutes,

    trip.passenger_count,

    ROUND(
        trip.trip_distance::NUMERIC,
        3
    ) AS trip_distance,

    trip.ratecode_id,

    trip.store_and_fwd_flag,

    -- 7. Mapping store and forward flag
    CASE TRIM(trip.store_and_fwd_flag)
        WHEN 'Y' THEN 'Store and Forward'
        WHEN 'N' THEN 'Normal'
        ELSE 'Unknown'
    END AS store_and_fwd_label,

    -- 8. Mapping lokasi pickup
    trip.pickup_location_id,
    pickup_lookup.borough AS pickup_borough,
    pickup_lookup.zone AS pickup_zone,
    pickup_lookup.service_zone AS pickup_service_zone,

    -- 9. Mapping lokasi dropoff
    trip.dropoff_location_id,
    dropoff_lookup.borough AS dropoff_borough,
    dropoff_lookup.zone AS dropoff_zone,
    dropoff_lookup.service_zone AS dropoff_service_zone,

    trip.payment_type AS payment_type_id,

    -- 10. Mapping payment type
    CASE trip.payment_type
        WHEN 1 THEN 'Credit Card'
        WHEN 2 THEN 'Cash'
        WHEN 3 THEN 'No Charge'
        WHEN 4 THEN 'Dispute'
        WHEN 0 THEN 'Unknown'
        ELSE 'Unknown / Not Recorded'
    END AS payment_type_label,

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
    

FROM bronze.raw_taxi_trips AS trip

-- Join pertama untuk mapping pickup location
INNER JOIN silver.taxi_zones AS pickup_lookup
    ON pickup_lookup.location_id
       = trip.pickup_location_id

-- Join kedua untuk mapping dropoff location
INNER JOIN silver.taxi_zones AS dropoff_lookup
    ON dropoff_lookup.location_id
       = trip.dropoff_location_id

WHERE 
       -- Validasi Quality Data 

    -- Dropoff harus lebih besar dari pada pickup
    trip.dropoff_datetime > trip.pickup_datetime

    -- Jarak trip_distance lebih besar dari 0
    AND trip.trip_distance > 0;


-- Membuat Tabel Data Quality Issues

CREATE TABLE IF NOT EXISTS silver.data_quality_issues(
    issue_id SERIAL PRIMARY KEY,
    trip_id INT NOT NULL,
    error_type VARCHAR(50) NOT NULL
);

-- Mengosongkan tabel agar tidak duplikat saat di jalankan ulang
TRUNCATE TABLE silver.data_quality_issues
RESTART IDENTITY;


-- Data Durasi Invalid

INSERT INTO silver.data_quality_issues(
    trip_id,
    error_type
)
SELECT
    trip_id,
    'duration invalid'
FROM bronze.raw_taxi_trips
WHERE pickup_datetime >= dropoff_datetime;

-- Data Jarak Invalid

INSERT INTO silver.data_quality_issues(
    trip_id,
    error_type
)
SELECT
    trip_id,
    'distance invalid'
FROM bronze.raw_taxi_trips
WHERE trip_distance <= 0;