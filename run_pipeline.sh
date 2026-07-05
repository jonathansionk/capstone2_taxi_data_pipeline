#!/bin/bash

set -u
set -o pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cd "$PROJECT_ROOT" || exit 1

mkdir -p logs

LOG_FILE="./logs/pipeline.log"

# Menghapus isi log lama
: > "$LOG_FILE"


log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" \
        | tee -a "$LOG_FILE"
}


echo "======================================" | tee -a "$LOG_FILE"
log "Starting Database Pipeline"
echo "======================================" | tee -a "$LOG_FILE"

log "Checking PostgreSQL Database....."

# PostgreSQL sudah dinyatakan sehat oleh Docker Compose
log "PostgreSQL Database is Ready"

log "Running main.py....."

python -u -m scripts.main 2>&1 | tee -a "$LOG_FILE"

PYTHON_STATUS=${PIPESTATUS[0]}


if [ "$PYTHON_STATUS" -eq 0 ]; then
    log "Database Pipeline Completed Successfully"
else
    log "Database Pipeline Failed"
    log "Exit Code: $PYTHON_STATUS"

    echo "======================================" | tee -a "$LOG_FILE"

    exit "$PYTHON_STATUS"
fi

echo "======================================" | tee -a "$LOG_FILE"