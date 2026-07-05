-- Membuat Tabel Audit untuk menyimpan riwayat proses pipeline

CREATE TABLE IF NOT EXISTS audit.pipeline_run(
    run_id SERIAL PRIMARY KEY,

    step_name TEXT NOT NULL,

    status TEXT NOT NULL,

    run_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    error_message TEXT,

    CONSTRAINT cek_pipeline_run_status
        CHECK (status IN('success','failed'))



)

