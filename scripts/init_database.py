from pathlib import Path
from sqlalchemy import create_engine

# Mengkoneksikan Database
DATABASE_URL = (
    "postgresql+psycopg2://taxi_user:taxi_pass@postgres:5432/taxi_db"
)

engine = create_engine(DATABASE_URL)

# Path sql

SQL_ROOT = Path(__file__).resolve().parents[1]

SQL_FILES = [
    SQL_ROOT/"db"/"init"/"01_schema.sql",
    SQL_ROOT/"db"/"init"/"02_bronze_load.sql",
    SQL_ROOT/"db"/"init"/"05_audit.sql"
]

# mengeksekusi SQL

def execute_sql_file(sql_file: Path) -> None:

    if not sql_file.exists():
        raise FileNotFoundError(f'File SQL tidak ditemukan: {sql_file}')
    
    sql_query = sql_file.read_text(encoding="utf-8")

    connection = engine.raw_connection()

    try:
        cursor = connection.cursor()
        cursor.execute(sql_query)
        connection.commit()
        cursor.close()
        print(f'Succes: {sql_file.name}')

    except Exception:
        connection.rollback()
        raise
    finally:
        connection.close()

# membuat function untuk menjalankan database

def run_database_init() -> None:

    for sql_file in SQL_FILES:
        execute_sql_file(sql_file)

if __name__ == "__main__":
    run_database_init()