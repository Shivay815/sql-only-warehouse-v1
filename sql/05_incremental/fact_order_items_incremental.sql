-- Step 1: Create physical partitioned and clustered fact table
CREATE TABLE IF NOT EXISTS `sql-only-warehouse-v1.core_aura.fact_order_items_inc`
(
  order_item_skey STRING,
  order_id STRING,
  order_item_id INT64,
  date_key INT64,
  product_skey STRING,
  seller_skey STRING,
  customer_skey STRING,
  customer_id STRING,
  product_id STRING,
  quantity INT64,
  price_at_purchase NUMERIC,
  item_gross_amount NUMERIC,
  _updated_at TIMESTAMP
)
PARTITION BY RANGE_BUCKET(date_key, GENERATE_ARRAY(20250101, 20301231, 10000))
CLUSTER BY order_id, product_id;