CREATE OR REPLACE VIEW `sql-only-warehouse-v1.staging_aura.stg_payments` AS
WITH cleaned AS (
  SELECT
    TRIM(payment_id) AS payment_id,
    TRIM(order_id) AS order_id,
    UPPER(TRIM(payment_method)) AS payment_method,
    UPPER(TRIM(payment_status)) AS payment_status,
    SAFE_CAST(amount AS NUMERIC) AS amount,
    SAFE_CAST(processed_at AS TIMESTAMP) AS processed_at,
    ROW_NUMBER() OVER (
      PARTITION BY TRIM(payment_id) 
      ORDER BY SAFE_CAST(processed_at AS TIMESTAMP) DESC
    ) AS row_num
  FROM `sql-only-warehouse-v1.raw_aura.raw_payments`
  WHERE payment_id IS NOT NULL AND TRIM(payment_id) != ''
)
SELECT
  payment_id,
  order_id,
  payment_method,
  payment_status,
  amount,
  processed_at,
  CURRENT_TIMESTAMP() AS _stg_updated_at
FROM cleaned
WHERE row_num = 1;