CREATE OR REPLACE VIEW `sql-only-warehouse-v1.staging_aura.stg_shipments` AS
WITH cleaned AS (
  SELECT
    TRIM(shipment_id) AS shipment_id,
    TRIM(order_id) AS order_id,
    UPPER(TRIM(carrier)) AS carrier,
    SAFE_CAST(shipped_at AS TIMESTAMP) AS shipped_at,
    SAFE_CAST(delivered_at AS TIMESTAMP) AS delivered_at,
    ROW_NUMBER() OVER (
      PARTITION BY TRIM(shipment_id) 
      ORDER BY SAFE_CAST(shipped_at AS TIMESTAMP) DESC
    ) AS row_num
  FROM `sql-only-warehouse-v1.raw_aura.raw_shipments`
  WHERE shipment_id IS NOT NULL AND TRIM(shipment_id) != ''
)
SELECT
  shipment_id,
  order_id,
  carrier,
  shipped_at,
  delivered_at,
  CURRENT_TIMESTAMP() AS _stg_updated_at
FROM cleaned
WHERE row_num = 1;