-- Step 1: Create a staging landing table with string/raw column definitions
CREATE OR REPLACE TEMP TABLE tmp_customers_landing (
  customer_id STRING,
  email STRING,
  first_name STRING,
  last_name STRING,
  created_at STRING,
  updated_at STRING
);

-- Note: In production pipelines, files are loaded into BigQuery using `bq load` CLI or GCS triggers.
-- For local CSV practice, we insert landing data directly or use external table loads:

INSERT INTO `sql-only-warehouse-v1.raw_aura.raw_customers` (
  customer_id,
  email,
  first_name,
  last_name,
  created_at,
  updated_at,
  _ingested_at,
  _source_file
)
SELECT 
  customer_id,
  email,
  first_name,
  last_name,
  created_at,
  updated_at,
  CURRENT_TIMESTAMP() AS _ingested_at,
  'customers.csv' AS _source_file
FROM tmp_customers_landing;