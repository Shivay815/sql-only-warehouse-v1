CREATE OR REPLACE VIEW `sql-only-warehouse-v1.staging_aura.stg_orders` AS
WITH cleaned AS (
  SELECT
    TRIM(order_id) AS order_id,
    TRIM(customer_id) AS customer_id,
    UPPER(TRIM(order_status)) AS order_status,
    SAFE_CAST(order_placed_at AS TIMESTAMP) AS order_placed_at,
    SAFE_CAST(total_amount AS NUMERIC) AS total_amount,
    ROW_NUMBER() OVER (
      PARTITION BY TRIM(order_id) 
      ORDER BY SAFE_CAST(order_placed_at AS TIMESTAMP) DESC
    ) AS row_num
  FROM `sql-only-warehouse-v1.raw_aura.raw_orders`
  WHERE order_id IS NOT NULL AND TRIM(order_id) != ''
)
SELECT
  order_id,
  customer_id,
  order_status,
  order_placed_at,
  total_amount,
  CURRENT_TIMESTAMP() AS _stg_updated_at
FROM cleaned
WHERE row_num = 1;