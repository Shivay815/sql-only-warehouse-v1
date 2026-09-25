-- 1. Deploy the DQ Procedure
-- bq query --use_legacy_sql=false < sql/06_dq/sp_run_quality_checks.sql

-- 2. Execute DQ Procedure on clean warehouse (Expected: All PASS)
CALL `sql-only-warehouse-v1.dq_aura.sp_run_quality_checks`();

-- 3. Query audit log to confirm pass status
SELECT test_name, check_type, test_status, failure_reason 
FROM `sql-only-warehouse-v1.dq_aura.dq_test_results`
ORDER BY executed_at DESC 
LIMIT 10;