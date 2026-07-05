# Base image Python
FROM python:3.12-bookworm


# Mengatur zona waktu container
ENV TZ=Asia/Jakarta
ENV PYTHONUNBUFFERED=1


# Folder kerja di dalam container
WORKDIR /app


# Memasang timezone data
RUN apt-get update \
    && apt-get install -y --no-install-recommends tzdata \
    && rm -rf /var/lib/apt/lists/*


# Copy requirements terlebih dahulu
COPY requirements.txt /app/requirements.txt


# Install semua library Python
RUN python -m pip install --no-cache-dir \
    -r /app/requirements.txt


# Copy seluruh project ke container
COPY . /app


# Mengubah line ending Windows dan permission shell script
RUN sed -i 's/\r$//' /app/run_pipeline.sh \
    && chmod +x /app/run_pipeline.sh


# Command default container
CMD ["bash", "run_pipeline.sh"]