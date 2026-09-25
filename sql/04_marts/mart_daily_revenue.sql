CREATE OR REPLACE VIEW `sql-only-warehouse-v1.marts_aura.mart_daily_revenue` AS
WITH daily_sales AS (
  SELECT
    d.full_date AS order_date,
    p.category_name,
    COUNT(DISTINCT f.order_id) AS total_orders,
    SUM(f.quantity) AS total_units_sold,
    SUM(f.item_gross_amount) AS gross_revenue
  FROM `sql-only-warehouse-v1.core_aura.fact_order_items` f
  INNER JOIN `sql-only-warehouse-v1.core_aura.dim_dates` d
    ON f.date_key = d.date_key
  LEFT JOIN `sql-only-warehouse-v1.core_aura.dim_products` p
    ON f.product_skey = p.product_skey
  GROUP BY 1, 2
),
daily_refunds AS (
  SELECT
    DATE(r.refunded_at) AS refund_date,
    SUM(r.refund_amount) AS total_refunded_amount
  FROM `sql-only-warehouse-v1.staging_aura.stg_refunds` r
  GROUP BY 1
)
SELECT
  s.order_date,
  s.category_name,
  s.total_orders,
  s.total_units_sold,
  s.gross_revenue,
  COALESCE(r.total_refunded_amount, 0) AS daily_category_refunds,
  (s.gross_revenue - COALESCE(r.total_refunded_amount, 0)) AS net_revenue
FROM daily_sales s
LEFT JOIN daily_refunds r
  ON s.order_date = r.refund_date;