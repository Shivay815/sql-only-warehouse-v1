CREATE OR REPLACE TABLE `sql-only-warehouse-v1.core_aura.dim_dates` AS
WITH date_spine AS (
  SELECT day
  FROM UNNEST(GENERATE_DATE_ARRAY('2025-01-01', '2028-12-31', INTERVAL 1 DAY)) AS day
)
SELECT
  CAST(FORMAT_DATE('%Y%m%d', day) AS INT64) AS date_key,
  day AS full_date,
  EXTRACT(YEAR FROM day) AS year,
  EXTRACT(QUARTER FROM day) AS quarter,
  EXTRACT(MONTH FROM day) AS month,
  FORMAT_DATE('%B', day) AS month_name,
  EXTRACT(DAY FROM day) AS day_of_month,
  EXTRACT(DAYOFWEEK FROM day) AS day_of_week,
  FORMAT_DATE('%A', day) AS day_name,
  CASE WHEN EXTRACT(DAYOFWEEK FROM day) IN (1, 7) THEN TRUE ELSE FALSE END AS is_weekend
FROM date_spine;