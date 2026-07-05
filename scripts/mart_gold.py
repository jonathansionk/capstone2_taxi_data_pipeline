from pathlib import Path
from sqlalchemy import create_engine, text

# koneksi Postgresql
engine = create_engine(
    "postgresql+psycopg2://taxi_user:taxi_pass@postgres:5432/taxi_db"
)

# Root Project
PROJECT_ROOT = Path(__file__).resolve().parents[1]

# lokasi file Gold SQL
GOLD_SQL_FILE = (PROJECT_ROOT/ "db"/ "transform"/"04_gold_mart.sql")

# Function Mencatat log proese ke tabel audit
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
                );
                """
            ),
            {
                "step":step,
                "status": status,
            },
        )

# Function Menjalankan gold pipeline

def run_gold_pipeline():
    
    print("Starting Gold Pipeline...")

    if not GOLD_SQL_FILE.exists():
        raise FileNotFoundError(
            f"File SQL tidak ditemukan: {GOLD_SQL_FILE}"
        )

    sql_script = GOLD_SQL_FILE.read_text(
        encoding="utf-8"
    )

    raw_connection = None
    cursor = None

    try:
        raw_connection = engine.raw_connection()
        cursor = raw_connection.cursor()

        print("Running 04_gold_mart.sql...")

        # Menjalankan seluruh isi file SQL
        cursor.execute(sql_script)

        # Menyimpan perubahan ke database
        raw_connection.commit()

        # Mencatat status berhasil
        audit_log(
            "gold_mart",
            "success",
        )

        print("Gold Pipeline Success")

    except Exception as error:
        if raw_connection is not None:
            raw_connection.rollback()

        print("Gold Pipeline Error:", error)

        try:
            audit_log(
                "gold_mart",
                "failed",
            )
        except Exception as audit_error:
            print(
                "Audit log gagal disimpan:",
                audit_error,
            )

        raise

    finally:
        if cursor is not None:
            cursor.close()

        if raw_connection is not None:
            raw_connection.close()


if __name__ == "__main__":
    run_gold_pipeline()

