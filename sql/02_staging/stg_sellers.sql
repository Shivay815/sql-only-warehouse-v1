CREATE OR REPLACE VIEW `sql-only-warehouse-v1.staging_aura.stg_sellers` AS
WITH cleaned AS (
  SELECT
    TRIM(seller_id) AS seller_id,
    TRIM(seller_name) AS seller_name,
    UPPER(TRIM(country)) AS country,
    UPPER(TRIM(status)) AS status,
    SAFE_CAST(created_at AS TIMESTAMP) AS created_at,
    ROW_NUMBER() OVER (
      PARTITION BY TRIM(seller_id) 
      ORDER BY SAFE_CAST(created_at AS TIMESTAMP) DESC
    ) AS row_num
  FROM `sql-only-warehouse-v1.raw_aura.raw_sellers`
  WHERE seller_id IS NOT NULL AND TRIM(seller_id) != ''
)
SELECT
  seller_id,
  seller_name,
  country,
  status,
  created_at,
  CURRENT_TIMESTAMP() AS _stg_updated_at
FROM cleaned
WHERE row_num = 1;