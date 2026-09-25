CREATE OR REPLACE PROCEDURE `sql-only-warehouse-v1.core_aura.sp_merge_fact_order_items`(
  p_start_timestamp TIMESTAMP,
  p_end_timestamp TIMESTAMP
)
BEGIN
  -- Execute Merge using Watermark range
  MERGE `sql-only-warehouse-v1.core_aura.fact_order_items_inc` T
  USING (
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
        (oi.quantity * oi.price_at_purchase) AS item_gross_amount,
        GREATEST(
          COALESCE(SAFE_CAST(o.order_placed_at AS TIMESTAMP), TIMESTAMP('1970-01-01')),
          COALESCE(oi._stg_updated_at, TIMESTAMP('1970-01-01'))
        ) AS record_updated_at
      FROM `sql-only-warehouse-v1.staging_aura.stg_order_items` oi
      INNER JOIN `sql-only-warehouse-v1.staging_aura.stg_orders` o
        ON oi.order_id = o.order_id
      WHERE o.order_placed_at >= p_start_timestamp 
        AND o.order_placed_at < p_end_timestamp
    )
    SELECT
      TO_HEX(MD5(CONCAT(b.order_id, '_', CAST(b.order_item_id AS STRING)))) AS order_item_skey,
      b.order_id,
      b.order_item_id,
      b.date_key,
      p.product_skey,
      p.seller_skey,
      COALESCE(c.customer_skey, TO_HEX(MD5(CONCAT(b.customer_id, '_UNKNOWN')))) AS customer_skey,
      b.customer_id,
      b.product_id,
      b.quantity,
      b.price_at_purchase,
      b.item_gross_amount,
      CURRENT_TIMESTAMP() AS _updated_at
    FROM base_items b
    LEFT JOIN `sql-only-warehouse-v1.core_aura.dim_products` p
      ON b.product_id = p.product_id
    LEFT JOIN `sql-only-warehouse-v1.core_aura.dim_customers` c
      ON b.customer_id = c.customer_id
     AND b.order_placed_at >= c.valid_from 
     AND b.order_placed_at < c.valid_to
  ) S
  ON T.order_item_skey = S.order_item_skey
  WHEN MATCHED THEN
    UPDATE SET
      quantity = S.quantity,
      price_at_purchase = S.price_at_purchase,
      item_gross_amount = S.item_gross_amount,
      customer_skey = S.customer_skey,
      product_skey = S.product_skey,
      _updated_at = S._updated_at
  WHEN NOT MATCHED THEN
    INSERT (
      order_item_skey, order_id, order_item_id, date_key, product_skey,
      seller_skey, customer_skey, customer_id, product_id, quantity,
      price_at_purchase, item_gross_amount, _updated_at
    )
    VALUES (
      S.order_item_skey, S.order_id, S.order_item_id, S.date_key, S.product_skey,
      S.seller_skey, S.customer_skey, S.customer_id, S.product_id, S.quantity,
      S.price_at_purchase, S.item_gross_amount, S._updated_at
    );
END;