CREATE OR REPLACE TABLE `sql-only-warehouse-v1.core_aura.fact_order_items` AS
WITH base_items AS (
  SELECT
    oi.order_id,
    oi.order_item_id,
    oi.product_id,
    o.customer_id,
    o.order_placed_at,
    CAST(FORMAT_DATE('%Y%m%d', DATE(o.order_placed_at)) AS INT64) AS date_key,
    oi.quantity,
    oi.price_at_purchase,
    (oi.quantity * oi.price_at_purchase) AS item_gross_amount
  FROM `sql-only-warehouse-v1.staging_aura.stg_order_items` oi
  INNER JOIN `sql-only-warehouse-v1.staging_aura.stg_orders` o
    ON oi.order_id = o.order_id
)
SELECT
  -- Composite Surrogate Key
  TO_HEX(MD5(CONCAT(b.order_id, '_', CAST(b.order_item_id AS STRING)))) AS order_item_skey,
  b.order_id,
  b.order_item_id,
  
  -- Foreign Keys (pointing to Dimensions)
  b.date_key,
  p.product_skey,
  p.seller_skey,
  -- Point to SCD Type 2 dimension matching the event timestamp
  COALESCE(c.customer_skey, TO_HEX(MD5(CONCAT(b.customer_id, '_UNKNOWN')))) AS customer_skey,
  
  -- Degenerate Dimensions & Degenerate Attributes
  b.customer_id,
  b.product_id,
  
  -- Measures
  b.quantity,
  b.price_at_purchase,
  b.item_gross_amount,
  
  CURRENT_TIMESTAMP() AS _created_at
FROM base_items b
LEFT JOIN `sql-only-warehouse-v1.core_aura.dim_products` p
  ON b.product_id = p.product_id
LEFT JOIN `sql-only-warehouse-v1.core_aura.dim_customers` c
  ON b.customer_id = c.customer_id
 AND b.order_placed_at >= c.valid_from 
 AND b.order_placed_at < c.valid_to;