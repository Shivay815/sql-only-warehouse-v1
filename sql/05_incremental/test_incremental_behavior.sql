-- Step 1: Initial Load (Backfill year 2025)
CALL `sql-only-warehouse-v1.core_aura.sp_merge_fact_order_items`(
  TIMESTAMP('2025-01-01 00:00:00 UTC'), 
  TIMESTAMP('2026-01-01 00:00:00 UTC')
);

-- Step 2: Capture row count after initial load
CREATE TEMP TABLE initial_count AS 
SELECT COUNT(*) as cnt, SUM(item_gross_amount) as gross FROM `sql-only-warehouse-v1.core_aura.fact_order_items_inc`;

-- Step 3: Test Idempotency (Re-run the EXACT same batch)
CALL `sql-only-warehouse-v1.core_aura.sp_merge_fact_order_items`(
  TIMESTAMP('2025-01-01 00:00:00 UTC'), 
  TIMESTAMP('2026-01-01 00:00:00 UTC')
);

-- Step 4: Verify that count and gross revenue remained identical (No duplicates)
SELECT
  'Idempotency Check' AS test_name,
  ic.cnt AS initial_row_count,
  inc.cnt AS post_rerun_row_count,
  CASE WHEN ic.cnt = inc.cnt AND ic.gross = inc.gross THEN 'PASS' ELSE 'FAIL' END AS status
FROM initial_count ic
CROSS JOIN (
  SELECT COUNT(*) as cnt, SUM(item_gross_amount) as gross FROM `sql-only-warehouse-v1.core_aura.fact_order_items_inc`
) inc;