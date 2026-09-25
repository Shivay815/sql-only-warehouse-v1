CREATE OR REPLACE VIEW `sql-only-warehouse-v1.marts_aura.mart_customer_ltv` AS
WITH customer_orders AS (
  SELECT
    c.customer_id,
    c.email,
    c.first_name,
    c.last_name,
    COUNT(DISTINCT f.order_id) AS total_lifetime_orders,
    SUM(f.item_gross_amount) AS total_lifetime_spend,
    MIN(d.full_date) AS first_order_date,
    MAX(d.full_date) AS most_recent_order_date
  FROM `sql-only-warehouse-v1.core_aura.fact_order_items` f
  INNER JOIN `sql-only-warehouse-v1.core_aura.dim_customers` c
    ON f.customer_skey = c.customer_skey
  INNER JOIN `sql-only-warehouse-v1.core_aura.dim_dates` d
    ON f.date_key = d.date_key
  GROUP BY 1, 2, 3, 4
)
SELECT
  customer_id,
  email,
  first_name,
  last_name,
  total_lifetime_orders,
  total_lifetime_spend AS ltv_gross_amount,
  first_order_date,
  most_recent_order_date,
  CASE 
    WHEN total_lifetime_orders > 1 THEN TRUE 
    ELSE FALSE 
  END AS is_repeat_buyer,
  DATE_DIFF(CURRENT_DATE(), most_recent_order_date, DAY) AS days_since_last_order
FROM customer_orders;