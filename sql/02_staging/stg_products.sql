CREATE OR REPLACE VIEW `sql-only-warehouse-v1.staging_aura.stg_products` AS
WITH cleaned AS (
  SELECT
    TRIM(product_id) AS product_id,
    TRIM(seller_id) AS seller_id,
    INITCAP(TRIM(category_name)) AS category_name,
    -- Handle negative or malformed prices by replacing with NULL
    CASE 
      WHEN SAFE_CAST(unit_price AS NUMERIC) < 0 THEN NULL
      ELSE SAFE_CAST(unit_price AS NUMERIC)
    END AS unit_price,
    SAFE_CAST(updated_at AS TIMESTAMP) AS updated_at,
    ROW_NUMBER() OVER (
      PARTITION BY TRIM(product_id) 
      ORDER BY SAFE_CAST(updated_at AS TIMESTAMP) DESC
    ) AS row_num
  FROM `sql-only-warehouse-v1.raw_aura.raw_products`
  WHERE product_id IS NOT NULL AND TRIM(product_id) != ''
)
SELECT
  product_id,
  seller_id,
  COALESCE(category_name, 'Uncategorized') AS category_name,
  unit_price,
  updated_at,
  CURRENT_TIMESTAMP() AS _stg_updated_at
FROM cleaned
WHERE row_num = 1;