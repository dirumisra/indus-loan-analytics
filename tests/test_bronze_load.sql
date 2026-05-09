-- =============================================
-- File     : test_bronze_load.sql
-- Project  : IndusLoan Analytics Platform
-- Author   : Dhiraj Kumar
-- Purpose  : Verify Bronze load ran correctly
--            Run after usp_load_bronze executes
-- =============================================

USE IndusLoanDB;
GO

-- =========================================
-- Test 1 : Row count check
-- Bronze should have 22154 rows
-- =========================================

SELECT 
    'bronze.applications' AS table_name,
    COUNT(*)              AS row_count
FROM bronze.applications;

-- =========================================
-- Test 2 : Masked attributes row count
-- Should match bronze row count exactly
-- =========================================

SELECT 
    'bronze.masked_attributes'   AS  table_name,
    COUNT(*)            AS      row_count
FROM bronze.masked_attributes;

-- =========================================
-- Test 3 : Pipeline log check
-- Should show latest run as SUCCESS
-- =========================================
SELECT
    run_id,
    pipeline_name,
    status,
    rows_ingested,
    watermark_start,
    watermark_end,
    duration_seconds
FROM audit.pipeline_run_log
WHERE pipeline_name = 'bronze_load'
ORDER BY run_id DESC;
GO

-- =========================================
-- Test 4 : Watermark check
-- Should show last_watermark = 2070048
-- last_run_status = SUCCESS
-- =========================================
SELECT
    pipeline_name,
    last_watermark,
    last_run_status,
    updated_at
FROM audit.watermark_control;
GO

-- =========================================
-- Test 5 : Sample masked data check
-- Verify PII is masked correctly
-- Name should show initials only
-- PAN should show hash not real value
-- =========================================
SELECT TOP 5
    b.App_Id,
    b.Customer_Name,
    m.masked_name,
    b.PAN_No,
    m.masked_pan,
    b.Date_Of_Birth,
    m.birth_year,
    b.DSE_Code,
    m.masked_dse_code
FROM bronze.applications b
JOIN bronze.masked_attributes m
    ON b.App_Id = m.App_Id;
GO