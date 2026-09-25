CREATE OR REPLACE TABLE `sql-only-warehouse-v1.core_aura.dim_sellers` AS
SELECT
  TO_HEX(MD5(CONCAT('SEL_', seller_id))) AS seller_skey,
  seller_id,
  seller_name,
  country,
  status,
  created_at AS onboarded_at,
  CURRENT_TIMESTAMP() AS _updated_at
FROM `sql-only-warehouse-v1.staging_aura.stg_sellers`;