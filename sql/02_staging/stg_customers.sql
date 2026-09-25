CREATE OR REPLACE VIEW `sql-only-warehouse-v1.staging_aura.stg_customers` AS
WITH cleaned AS (
  SELECT
    TRIM(customer_id) AS customer_id,
    -- Validate email pattern basic rule; set invalid email format to NULL
    CASE 
      WHEN REGEXP_CONTAINS(TRIM(email), r'^[^@]+@[^@]+\.[^@]+$') THEN LOWER(TRIM(email))
      ELSE NULL
    END AS email,
    INITCAP(TRIM(first_name)) AS first_name,
    INITCAP(TRIM(last_name)) AS last_name,
    SAFE_CAST(created_at AS TIMESTAMP) AS created_at,
    SAFE_CAST(updated_at AS TIMESTAMP) AS updated_at,
    ROW_NUMBER() OVER (
      PARTITION BY TRIM(customer_id) 
      ORDER BY SAFE_CAST(updated_at AS TIMESTAMP) DESC
    ) AS row_num
  FROM `sql-only-warehouse-v1.raw_aura.raw_customers`
  WHERE customer_id IS NOT NULL AND TRIM(customer_id) != ''
)
SELECT
  customer_id,
  email,
  first_name,
  last_name,
  created_at,
  updated_at,
  CURRENT_TIMESTAMP() AS _stg_updated_at
FROM cleaned
WHERE row_num = 1;