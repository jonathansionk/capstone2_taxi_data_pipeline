import requests
import os
import pandas as pd

# Membuat folder data/raw
os.makedirs('./data/raw',exist_ok=True)

# Link URL untuk mendownload data mentah
yellow_tripdata_url = "https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2026-01.parquet"
taxi_zone_url = "https://d37ci6vzurychx.cloudfront.net/misc/taxi_zone_lookup.csv"

# Path untuk menyimpan data mentah
yellow_tripdata_path = './data/raw/yellow_tripdata_2026-01_raw.parquet'
taxi_zone_path = './data/raw/taxi_zone_lookup_raw.csv'

# function untuk ekstrak data

def extract_file(url, save_path):

    with requests.get(url, stream=True) as r:
        r.raise_for_status()
        with open(save_path, 'wb') as f:
            for chunk in r.iter_content(chunk_size=8192):
                f.write(chunk)

        print(f'Download Succes, saved to : {save_path}')


# Membuat fungsi untuk run extract kedua file

def run_extract():
    extract_file(yellow_tripdata_url,yellow_tripdata_path)
    extract_file(taxi_zone_url,taxi_zone_path)

# melihat nama kolom data set

# taxi_trip_df = pd.read_parquet(yellow_tripdata_path)
# taxi_zone_df = pd.read_csv(taxi_zone_path)

# print(taxi_trip_df.columns)
# print(taxi_zone_df.columns)