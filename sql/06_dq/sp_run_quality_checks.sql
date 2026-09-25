-- 1. Create Data Quality Audit Log Table
CREATE TABLE IF NOT EXISTS `sql-only-warehouse-v1.dq_aura.dq_test_results` (
  test_run_id STRING,
  test_name STRING,
  check_type STRING,
  target_table STRING,
  failed_records INT64,
  test_status STRING,
  failure_reason STRING,
  executed_at TIMESTAMP
);

-- 2. Master Quality Runner Procedure
CREATE OR REPLACE PROCEDURE `sql-only-warehouse-v1.dq_aura.sp_run_quality_checks`()
BEGIN
  DECLARE v_run_id STRING;
  DECLARE v_failed_count INT64;
  
  SET v_run_id = CAST(GENERATE_UUID() AS STRING);

  -- Insert Results into Audit Log
  INSERT INTO `sql-only-warehouse-v1.dq_aura.dq_test_results`
  
  -- CHECK 1: Schema - Primary Key Uniqueness on fact_order_items
  SELECT 
    v_run_id,
    'pk_uniqueness_fact_order_items' AS test_name,
    'SCHEMA' AS check_type,
    'core_aura.fact_order_items' AS target_table,
    COUNT(*) - COUNT(DISTINCT order_item_skey) AS failed_records,
    CASE WHEN COUNT(*) = COUNT(DISTINCT order_item_skey) THEN 'PASS' ELSE 'FAIL' END AS test_status,
    'Duplicate primary key order_item_skey detected in fact table' AS failure_reason,
    CURRENT_TIMESTAMP() AS executed_at
  FROM `sql-only-warehouse-v1.core_aura.fact_order_items`

  UNION ALL

  -- CHECK 2: Schema - Required Non-Null Keys
  SELECT 
    v_run_id,
    'not_null_customer_skey' AS test_name,
    'SCHEMA' AS check_type,
    'core_aura.fact_order_items' AS target_table,
    COUNTCASE WHEN customer_skey IS NULL THEN 1 END AS failed_records,
    CASE WHEN COUNTCASE WHEN customer_skey IS NULL THEN 1 END = 0 THEN 'PASS' ELSE 'FAIL' END AS test_status,
    'NULL customer_skey found in fact_order_items' AS failure_reason,
    CURRENT_TIMESTAMP() AS executed_at
  FROM `sql-only-warehouse-v1.core_aura.fact_order_items`

  UNION ALL

  -- CHECK 3: Schema - Foreign Key Referential Integrity
  SELECT 
    v_run_id,
    'referential_integrity_product_fk' AS test_name,
    'SCHEMA' AS check_type,
    'core_aura.fact_order_items' AS target_table,
    COUNT(*) AS failed_records,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS test_status,
    'Foreign key product_skey does not resolve to dim_products' AS failure_reason,
    CURRENT_TIMESTAMP() AS executed_at
  FROM `sql-only-warehouse-v1.core_aura.fact_order_items` f
  LEFT JOIN `sql-only-warehouse-v1.core_aura.dim_products` p
    ON f.product_skey = p.product_skey
  WHERE f.product_skey IS NOT NULL AND p.product_skey IS NULL

  UNION ALL

  -- CHECK 4: Business - Accepted Values Range for Payment Status
  SELECT 
    v_run_id,
    'accepted_values_payment_status' AS test_name,
    'BUSINESS' AS check_type,
    'staging_aura.stg_payments' AS target_table,
    COUNT(*) AS failed_records,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS test_status,
    'Unexpected payment_status values detected' AS failure_reason,
    CURRENT_TIMESTAMP() AS executed_at
  FROM `sql-only-warehouse-v1.staging_aura.stg_payments`
  WHERE payment_status NOT IN ('SUCCESS', 'FAILED', 'PENDING', 'REFUNDED', 'CANCELLED')

  UNION ALL

  -- CHECK 5: Business - Impossible Delivery Dates
  SELECT 
    v_run_id,
    'impossible_shipment_dates' AS test_name,
    'BUSINESS' AS check_type,
    'staging_aura.stg_shipments' AS target_table,
    COUNT(*) AS failed_records,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS test_status,
    'delivered_at timestamp occurs before shipped_at timestamp' AS failure_reason,
    CURRENT_TIMESTAMP() AS executed_at
  FROM `sql-only-warehouse-v1.staging_aura.stg_shipments`
  WHERE delivered_at < shipped_at

  UNION ALL

  -- CHECK 6: Business - Invalid Negative Prices or Quantities
  SELECT 
    v_run_id,
    'invalid_negative_measures' AS test_name,
    'BUSINESS' AS check_type,
    'core_aura.fact_order_items' AS target_table,
    COUNT(*) AS failed_records,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS test_status,
    'Negative or zero quantity or price detected in fact table' AS failure_reason,
    CURRENT_TIMESTAMP() AS executed_at
  FROM `sql-only-warehouse-v1.core_aura.fact_order_items`
  WHERE quantity <= 0 OR price_at_purchase < 0

  UNION ALL

  -- CHECK 7: Business - Layer Reconciliation (Staging vs Marts)
  SELECT 
    v_run_id,
    'reconciliation_staging_vs_marts' AS test_name,
    'BUSINESS' AS check_type,
    'marts_aura.mart_daily_revenue' AS target_table,
    ABS(
      COALESCE((SELECT SUM(quantity * price_at_purchase) FROM `sql-only-warehouse-v1.staging_aura.stg_order_items`), 0) -
      COALESCE((SELECT SUM(gross_revenue) FROM `sql-only-warehouse-v1.marts_aura.mart_daily_revenue`), 0)
    ) AS failed_records,
    CASE WHEN ABS(
      COALESCE((SELECT SUM(quantity * price_at_purchase) FROM `sql-only-warehouse-v1.staging_aura.stg_order_items`), 0) -
      COALESCE((SELECT SUM(gross_revenue) FROM `sql-only-warehouse-v1.marts_aura.mart_daily_revenue`), 0)
    ) = 0 THEN 'PASS' ELSE 'FAIL' END AS status,
    'Gross revenue sum mismatch between staging_aura and marts_aura' AS failure_reason,
    CURRENT_TIMESTAMP() AS executed_at;

  -- Raise Error if any test failed
  SELECT COUNT(*) INTO v_failed_count 
  FROM `sql-only-warehouse-v1.dq_aura.dq_test_results` 
  WHERE test_run_id = v_run_id AND test_status = 'FAIL';

  IF v_failed_count > 0 THEN
    ERROR(CONCAT('Data Quality Suite Failure: ', CAST(v_failed_count AS STRING), ' test(s) failed. Query dq_aura.dq_test_results for run_id: ', v_run_id));
  END IF;
END;