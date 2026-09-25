-- Validation 1: Verify customer primary key uniqueness
SELECT 'stg_customers' AS table_name, customer_id AS key_value, COUNT(*) AS dup_count
FROM `sql-only-warehouse-v1.staging_aura.stg_customers`
GROUP BY customer_id HAVING COUNT(*) > 1

UNION ALL

-- Validation 2: Verify products primary key uniqueness
SELECT 'stg_products' AS table_name, product_id AS key_value, COUNT(*) AS dup_count
FROM `sql-only-warehouse-v1.staging_aura.stg_products`
GROUP BY product_id HAVING COUNT(*) > 1

UNION ALL

-- Validation 3: Verify orders primary key uniqueness
SELECT 'stg_orders' AS table_name, order_id AS key_value, COUNT(*) AS dup_count
FROM `sql-only-warehouse-v1.staging_aura.stg_orders`
GROUP BY order_id HAVING COUNT(*) > 1;