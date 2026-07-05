from datetime import datetime

from scripts.load_bronze import run_bronze_pipeline
from scripts.extract import run_extract
from scripts.transform_silver import run_silver_pipeline
from scripts.mart_gold import run_gold_pipeline
from scripts.init_database import run_database_init


# Menampilkan pesan beserta timestamp
def log(message: str) -> None:
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    print(f"{timestamp} - {message}", flush=True)


def main():

    print("======================================", flush=True)
    log("START DATA PIPELINE")
    print("======================================", flush=True)

    # 1. Membuat schema dan tabel database
    log("START: Database Initialization")
    run_database_init()
    log("SUCCESS: Database Initialization")

    # 2. Extract data raw
    log("START: Extract Raw Data")
    run_extract()
    log("SUCCESS: Extract Raw Data")

    # 3. Load Bronze
    log("START: Load Bronze")
    run_bronze_pipeline()
    log("SUCCESS: Load Bronze")

    # 4. Transform Silver
    log("START: Transform Silver")
    run_silver_pipeline()
    log("SUCCESS: Transform Silver")

    # 5. Mart Gold
    log("START: Build Gold Mart")
    run_gold_pipeline()
    log("SUCCESS: Build Gold Mart")



if __name__ == "__main__":
    main()