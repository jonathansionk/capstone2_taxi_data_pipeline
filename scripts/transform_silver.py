from pathlib import Path
from  sqlalchemy import create_engine, text

# koneksi Postgresql
engine = create_engine(
    "postgresql+psycopg2://taxi_user:taxi_pass@postgres:5432/taxi_db"
)

# Root Project
PROJECT_ROOT = Path(__file__).resolve().parents[1]

# lokasi file silver SQL
SILVER_SQL_FILE = (PROJECT_ROOT/ "db"/ "transform"/"03_silver_transform.sql")

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

# Function Menjalankan file silver SQL
def run_silver_pipeline():

    print("Starting Silver Pipeline...")

    if not SILVER_SQL_FILE.exists():
        raise FileNotFoundError(
            f"File SQL tidak ditemukan: {SILVER_SQL_FILE}"
        )

    sql_script = SILVER_SQL_FILE.read_text(
        encoding="utf-8"
    )

    raw_connection = engine.raw_connection()

    try:
        cursor = raw_connection.cursor()

        print("Running 03_silver_transform.sql...")

        cursor.execute(sql_script)

        raw_connection.commit()

        audit_log(
            "silver_transform",
            "success",
        )

        print("Silver Pipeline Success")

    except Exception as e:
        raw_connection.rollback()

        print("Silver Pipeline Error:", e)

        try:
            audit_log(
                "silver_transform",
                "failed",
            )
        except Exception as audit_error:
            print(
                "Audit log gagal disimpan:",
                audit_error,
            )

        raise

    finally:
        cursor.close()
        raw_connection.close()


if __name__ == "__main__":
    run_silver_pipeline()