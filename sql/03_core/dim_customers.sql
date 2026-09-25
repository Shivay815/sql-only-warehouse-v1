CREATE OR REPLACE TABLE `sql-only-warehouse-v1.core_aura.dim_customers` AS
WITH customer_history AS (
  SELECT
    customer_id,
    email,
    first_name,
    last_name,
    updated_at AS valid_from,
    LEAD(updated_at) OVER (PARTITION BY customer_id ORDER BY updated_at ASC) AS next_updated_at
  FROM `sql-only-warehouse-v1.staging_aura.stg_customers`
)
SELECT
  TO_HEX(MD5(CONCAT(customer_id, '_', CAST(valid_from AS STRING)))) AS customer_skey,
  customer_id,
  email,
  first_name,
  last_name,
  valid_from,
  COALESCE(next_updated_at, TIMESTAMP('2099-12-31 23:59:59 UTC')) AS valid_to,
  CASE WHEN next_updated_at IS NULL THEN TRUE ELSE FALSE END AS is_current,
  CURRENT_TIMESTAMP() AS _updated_at
FROM customer_history;