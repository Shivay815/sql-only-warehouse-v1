CREATE OR REPLACE VIEW `sql-only-warehouse-v1.marts_aura.mart_fulfillment_performance` AS
SELECT
  carrier,
  FORMAT_TIMESTAMP('%Y-%m', shipped_at) AS shipping_month,
  COUNT(shipment_id) AS total_shipments,
  AVG(TIMESTAMP_DIFF(delivered_at, shipped_at, HOUR) / 24.0) AS avg_delivery_days,
  COUNT(CASE WHEN delivered_at IS NULL THEN 1 END) AS pending_deliveries
FROM `sql-only-warehouse-v1.staging_aura.stg_shipments`
GROUP BY carrier, shipping_month;