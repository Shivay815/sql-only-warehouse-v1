CREATE OR REPLACE VIEW `sql-only-warehouse-v1.marts_aura.mart_payment_performance` AS
SELECT
  payment_method,
  payment_status,
  COUNT(payment_id) AS total_transactions,
  SUM(amount) AS total_processed_amount,
  SAFE_DIVIDE(
    COUNT(CASE WHEN payment_status = 'SUCCESS' THEN 1 END), 
    COUNT(payment_id)
  ) * 100 AS success_rate_pct
FROM `sql-only-warehouse-v1.staging_aura.stg_payments`
GROUP BY payment_method, payment_status;