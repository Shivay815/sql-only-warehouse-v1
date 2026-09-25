CREATE OR REPLACE TABLE `sql-only-warehouse-v1.core_aura.dim_products` AS
SELECT
  TO_HEX(MD5(CONCAT('PRD_', product_id))) AS product_skey,
  product_id,
  TO_HEX(MD5(CONCAT('SEL_', seller_id))) AS seller_skey,
  seller_id,
  category_name,
  unit_price,
  updated_at AS catalog_updated_at,
  CURRENT_TIMESTAMP() AS _updated_at
FROM `sql-only-warehouse-v1.staging_aura.stg_products`;