-- Reconciliation 1: Total Gross Sales in Mart vs Fact Table
SELECT 
  'Gross Revenue Check' AS reconciliation_name,
  (SELECT SUM(item_gross_amount) FROM `sql-only-warehouse-v1.core_aura.fact_order_items`) AS core_fact_total,
  (SELECT SUM(gross_revenue) FROM `sql-only-warehouse-v1.marts_aura.mart_daily_revenue`) AS mart_total,
  CASE WHEN (SELECT SUM(item_gross_amount) FROM `sql-only-warehouse-v1.core_aura.fact_order_items`) = 
            (SELECT SUM(gross_revenue) FROM `sql-only-warehouse-v1.marts_aura.mart_daily_revenue`)
       THEN 'PASS' ELSE 'FAIL' END AS status

UNION ALL

-- Reconciliation 2: LTV Total vs Fact Table Total
SELECT 
  'LTV Revenue Check' AS reconciliation_name,
  (SELECT SUM(item_gross_amount) FROM `sql-only-warehouse-v1.core_aura.fact_order_items`) AS core_fact_total,
  (SELECT SUM(ltv_gross_amount) FROM `sql-only-warehouse-v1.marts_aura.mart_customer_ltv`) AS mart_total,
  CASE WHEN (SELECT SUM(item_gross_amount) FROM `sql-only-warehouse-v1.core_aura.fact_order_items`) = 
            (SELECT SUM(ltv_gross_amount) FROM `sql-only-warehouse-v1.marts_aura.mart_customer_ltv`)
       THEN 'PASS' ELSE 'FAIL' END AS status;