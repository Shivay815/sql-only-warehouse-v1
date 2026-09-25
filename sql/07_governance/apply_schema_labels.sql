-- Apply Table Descriptions to Gold Marts
ALTER VIEW `sql-only-warehouse-v1.marts_aura.mart_daily_revenue`
SET OPTIONS(
  description="Gold mart serving daily gross/net revenue aggregated by product category. Reconciles with core_aura.fact_order_items."
);

ALTER VIEW `sql-only-warehouse-v1.marts_aura.mart_customer_ltv`
SET OPTIONS(
  description="Gold mart tracking customer lifetime value, order frequency, and repeat buyer status. Contains sensitive PII attributes."
);

ALTER TABLE `sql-only-warehouse-v1.core_aura.fact_order_items`
SET OPTIONS(
  description="Core transactional fact table with item-level grain (1 row per order item). Partitioned by date_key."
);
