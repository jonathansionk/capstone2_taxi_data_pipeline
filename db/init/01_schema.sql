-- Membuat Schema Database
CREATE SCHEMA IF NOT EXISTS bronze;
CREATE SCHEMA IF NOT EXISTS silver;
CREATE SCHEMA IF NOT EXISTS gold;
CREATE SCHEMA IF NOT EXISTS audit;

-- Membuat seacrh path
SET search_path TO bronze, silver, gold, audit;