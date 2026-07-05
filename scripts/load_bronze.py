import csv
from io import StringIO

import pandas as pd
from sqlalchemy import create_engine, text


# Membuat koneksi database
engine = create_engine(
    "postgresql+psycopg2://"
    "taxi_user:taxi_pass@postgres:5432/taxi_db"
)


INTEGER_COLUMNS = {
    "vendor_id",
    "passenger_count",
    "ratecode_id",
    "pickup_location_id",
    "dropoff_location_id",
    "payment_type",
    "location_id"
}


# Function load menggunakan PostgreSQL COPY
def copy_to_postgres(table, conn, keys, data_iter):

    dbapi_connection = conn.connection

    with dbapi_connection.cursor() as cursor:

        csv_buffer = StringIO()

        csv_writer = csv.writer(
            csv_buffer,
            lineterminator="\n"
        )

        # Memeriksa setiap baris sebelum dikirim ke PostgreSQL
        for row in data_iter:

            cleaned_row = []

            for column, value in zip(keys, row):

                # Mengubah nilai kosong menjadi NULL PostgreSQL
                if pd.isna(value):
                    cleaned_row.append(r"\N")

                # Mengubah nilai seperti 1.0 menjadi 1
                elif column in INTEGER_COLUMNS:
                    cleaned_row.append(int(value))

                else:
                    cleaned_row.append(value)

            csv_writer.writerow(cleaned_row)

        csv_buffer.seek(0)

        column_names = ", ".join(
            f'"{column}"' for column in keys
        )

        table_name = (
            f'"{table.schema}"."{table.name}"'
        )

        copy_query = f"""
            COPY {table_name} ({column_names})
            FROM STDIN
            WITH (
                FORMAT CSV,
                NULL '\\N'
            )
        """

        cursor.copy_expert(
            copy_query,
            csv_buffer
        )


# Path File
TAXI_TRIP_FILE = './data/raw/yellow_tripdata_2026-01_raw.parquet'
TAXI_ZONE_FILE = './data/raw/taxi_zone_lookup_raw.csv'


# Membuat Truncate Function agar tidak duplikat
# saat dijalankan lebih dari sekali
def truncate_table():

    with engine.begin() as conn:
        conn.execute(
            text(
                """
                TRUNCATE TABLE
                    bronze.raw_taxi_trips,
                    bronze.raw_taxi_zones
                RESTART IDENTITY;
                """
            )
        )

    print('Tables Truncated, Clean Start')


# Untuk load TAXI_TRIP_FILE
def load_taxi_trips():

    taxi_trip_df = pd.read_parquet(TAXI_TRIP_FILE)

    taxi_trip_df = taxi_trip_df.rename(columns={
        "VendorID": "vendor_id",
        "tpep_pickup_datetime": "pickup_datetime",
        "tpep_dropoff_datetime": "dropoff_datetime",
        "passenger_count": "passenger_count",
        "trip_distance": "trip_distance",
        "RatecodeID": "ratecode_id",
        "store_and_fwd_flag": "store_and_fwd_flag",
        "PULocationID": "pickup_location_id",
        "DOLocationID": "dropoff_location_id",
        "payment_type": "payment_type",
        "fare_amount": "fare_amount",
        "extra": "extra",
        "mta_tax": "mta_tax",
        "tip_amount": "tip_amount",
        "tolls_amount": "tolls_amount",
        "improvement_surcharge": "improvement_surcharge",
        "total_amount": "total_amount",
        "congestion_surcharge": "congestion_surcharge",
        "Airport_fee": "airport_fee",
        "cbd_congestion_fee": "cbd_congestion_fee"
    })

    print("TAXI_TRIP_FILE Starting load to PostgreSQL...")

    taxi_trip_df.to_sql(
        "raw_taxi_trips",
        engine,
        schema="bronze",
        if_exists="append",
        index=False,
        method=copy_to_postgres,
        chunksize=100_000
    )

    print(
        f'Taxi Trips File Loaded: '
        f'{len(taxi_trip_df)} rows'
    )


# Untuk load TAXI_ZONE_FILE
def load_taxi_zone():

    taxi_zone_df = pd.read_csv(TAXI_ZONE_FILE)

    taxi_zone_df = taxi_zone_df.rename(columns={
        "LocationID": "location_id",
        "Borough": "borough",
        "Zone": "zone",
        "service_zone": "service_zone"
    })

    print("TAXI_ZONE_FILE Starting load to PostgreSQL...")

    taxi_zone_df.to_sql(
        "raw_taxi_zones",
        engine,
        schema="bronze",
        if_exists="append",
        index=False,
        method=copy_to_postgres,
        chunksize=100_000
    )

    print(
        f'Taxi Zones File Loaded: '
        f'{len(taxi_zone_df)} rows'
    )


# Membuat Audit log
def audit_log(step, status):

    with engine.begin() as conn:
        conn.execute(
            text(
                """
                INSERT INTO audit.pipeline_run(
                    step_name,
                    status,
                    run_time
                )
                VALUES (
                    :step,
                    :status,
                    NOW()
                )
                """
            ),
            {
                "step": step,
                "status": status
            }
        )


# Membuat fungsi untuk run Pipeline Bronze
def run_bronze_pipeline():

    try:
        truncate_table()
        load_taxi_trips()
        load_taxi_zone()

        audit_log(
            "bronze_load",
            "success"
        )

        print("Bronze Pipeline Success")

    except Exception as e:

        print(
            "Bronze Pipeline Error:",
            e
        )

        try:
            audit_log(
                "bronze_load",
                "failed"
            )

        except Exception as audit_error:
            print(
                "Audit log gagal disimpan:",
                audit_error
            )

        raise


if __name__ == "__main__":
    run_bronze_pipeline()