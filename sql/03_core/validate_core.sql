-- Check 1: Ensure fact row count matches staging row count (No fan-out)
SELECT 
  'row_count_check' AS test_name,
  (SELECT COUNT(*) FROM `sql-only-warehouse-v1.staging_aura.stg_order_items`) AS expected_count,
  (SELECT COUNT(*) FROM `sql-only-warehouse-v1.core_aura.fact_order_items`) AS actual_count,
  CASE WHEN (SELECT COUNT(*) FROM `sql-only-warehouse-v1.staging_aura.stg_order_items`) = 
            (SELECT COUNT(*) FROM `sql-only-warehouse-v1.core_aura.fact_order_items`)
       THEN 'PASS' ELSE 'FAIL' END AS status

UNION ALL

-- Check 2: Ensure total gross amount reconciles between staging and core
SELECT 
  'gross_amount_reconciliation' AS test_name,
  CAST((SELECT SUM(quantity * price_at_purchase) FROM `sql-only-warehouse-v1.staging_aura.stg_order_items`) AS INT64) AS expected_count,
  CAST((SELECT SUM(item_gross_amount) FROM `sql-only-warehouse-v1.core_aura.fact_order_items`) AS INT64) AS actual_count,
  CASE WHEN CAST((SELECT SUM(quantity * price_at_purchase) FROM `sql-only-warehouse-v1.staging_aura.stg_order_items`) AS INT64) = 
            CAST((SELECT SUM(item_gross_amount) FROM `sql-only-warehouse-v1.core_aura.fact_order_items`) AS INT64)
       THEN 'PASS' ELSE 'FAIL' END AS status;