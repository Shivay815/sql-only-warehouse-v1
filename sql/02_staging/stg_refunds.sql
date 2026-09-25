CREATE OR REPLACE VIEW `sql-only-warehouse-v1.staging_aura.stg_refunds` AS
WITH cleaned AS (
  SELECT
    TRIM(refund_id) AS refund_id,
    TRIM(order_id) AS order_id,
    SAFE_CAST(refund_amount AS NUMERIC) AS refund_amount,
    UPPER(TRIM(reason)) AS reason,
    SAFE_CAST(refunded_at AS TIMESTAMP) AS refunded_at,
    ROW_NUMBER() OVER (
      PARTITION BY TRIM(refund_id) 
      ORDER BY SAFE_CAST(refunded_at AS TIMESTAMP) DESC
    ) AS row_num
  FROM `sql-only-warehouse-v1.raw_aura.raw_refunds`
  WHERE refund_id IS NOT NULL AND TRIM(refund_id) != ''
)
SELECT
  refund_id,
  order_id,
  refund_amount,
  COALESCE(reason, 'UNSPECIFIED') AS reason,
  refunded_at,
  CURRENT_TIMESTAMP() AS _stg_updated_at
FROM cleaned
WHERE row_num = 1;