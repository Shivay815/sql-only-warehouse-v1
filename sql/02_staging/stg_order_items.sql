CREATE OR REPLACE VIEW `sql-only-warehouse-v1.staging_aura.stg_order_items` AS
WITH cleaned AS (
  SELECT
    TRIM(order_id) AS order_id,
    SAFE_CAST(order_item_id AS INT64) AS order_item_id,
    TRIM(product_id) AS product_id,
    SAFE_CAST(quantity AS INT64) AS quantity,
    SAFE_CAST(price_at_purchase AS NUMERIC) AS price_at_purchase,
    ROW_NUMBER() OVER (
      PARTITION BY TRIM(order_id), SAFE_CAST(order_item_id AS INT64) 
      ORDER BY TRIM(order_id)
    ) AS row_num
  FROM `sql-only-warehouse-v1.raw_aura.raw_order_items`
  WHERE order_id IS NOT NULL AND order_item_id IS NOT NULL
)
SELECT
  order_id,
  order_item_id,
  product_id,
  quantity,
  price_at_purchase,
  CURRENT_TIMESTAMP() AS _stg_updated_at
FROM cleaned
WHERE row_num = 1;