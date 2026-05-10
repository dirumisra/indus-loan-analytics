-- =============================================
-- File     : 04_usp_run_dq_bronze.sql
-- Project  : IndusLoan Analytics Platform
-- Author   : Dhiraj Kumar
-- Phase    : 4 - Bronze DQ
-- Purpose  : Run 5 data quality rules on bronze
--            Log every result to audit.dq_results
--            CRITICAL failure stops the pipeline
--            WARNING failure logs but continues
-- =============================================

USE IndusLoanDB;
GO

-- =============================================

-- =============================================
-- Procedure Definition and Parameters
-- @p_run_id links every DQ result back to
-- the bronze load run that triggered this check
-- So we always know which load caused which result
-- @p_env tells us which environment we are in
-- =============================================
CREATE PROCEDURE bronze.usp_run_dq_bronze
    @p_run_id  INT,
    @p_env      VARCHAR(10)  = 'DEV'

AS
BEGIN
    -- =============================================
    -- DECLARE Variables
    -- @v_raw_count    = total rows in raw table
    -- @v_bronze_count = total rows in bronze table
    -- @v_fail_count   = rows failing each DQ rule
    -- @v_error_msg    = captures error if proc fails
    -- v_ prefix means this is an internal variable
    -- not a parameter passed from outside
    -- =============================================
    DECLARE @v_raw_count        INT;
    DECLARE @v_bronze_count     INT;
    DECLARE @v_fail_count       INT;
    DECLARE @v_error_msg        VARCHAR(MAX);

    -- =============================================
    -- Open TRY Block
    -- All 5 DQ rules run inside here
    -- If any CRITICAL rule fails
    -- CATCH block handles it
    -- =============================================

    BEGIN TRY
        -- =========================================
        -- DQ_B001 : Row Count Check
        -- Compare raw vs bronze row counts
        -- Any difference means rows were lost
        -- during bronze load
        -- Severity : WARNING
        -- Pipeline continues even if this fails
        -- =========================================

        -- Step 1 : Count raw rows
        SELECT @v_raw_count = COUNT(*)
        FROM raw.applications;

        -- Step 2 : Count bronze rows
        SELECT @v_bronze_count = COUNT(*)
        FROM bronze.applications;

        -- Step 3 : Calculate difference
        -- If raw count equals bronze count
        -- difference is zero = PASS
        -- If difference exists = FAIL

        SET @v_fail_count = @v_raw_count - @v_bronze_count;

        -- Step 4 : Log result to dq_results
        INSERT INTO audit.dq_results (
            run_id,
            layer,
            rule_id,
            rule_description,
            severity,
            result,
            expected_value,
            actual_value,
            rows_affected
        )
        VALUES (
            @p_run_id,
            'BRONZE',
            'DQ_B001',
            'Row count in bronze must match raw',
            'WARNING',
            CASE 
                WHEN @v_fail_count  = 0 THEN 'PASS'
                ELSE 'FAIL'
            END,
            CAST(@v_raw_count AS VARCHAR),
            CAST(@v_bronze_count AS VARCHAR),
            @v_fail_count
        );

        PRINT 'DQ_B001 completed — Raw: '
            + CAST(@v_raw_count AS VARCHAR)
            + ' Bronze: '
            + CAST(@v_bronze_count AS VARCHAR);

        -- =========================================
        -- DQ_B002 : Duplicate App_Id Check
        -- Every App_Id must appear exactly once
        -- in bronze.applications
        -- Duplicate App_Id corrupts all reports
        -- Severity : CRITICAL
        -- Pipeline STOPS if this fails
        -- =========================================

        -- Count App_Ids that appear more than once
        -- GROUP BY App_Id groups same App_Ids together
        -- HAVING COUNT > 1 filters only duplicates
        SELECT @v_fail_count = COUNT(*)
        FROM (
            SELECT App_Id
            FROM bronze.applications
            GROUP BY App_Id
            HAVING COUNT(*) > 1
        ) duplicates;

        -- Log result to dq_results
        INSERT INTO  audit.dq_results (
            run_id,
            layer,
            rule_id,
            rule_description,
            severity,
            result,
            expected_value,
            actual_value,
            rows_affected
        )
        VALUES (
            @p_run_id,
            'BRONZE',
            'DQ_B002',
            'No duplicate App_Id allowed in bronze',
            'CRITICAL',
            CASE WHEN @v_fail_count = 0
                THEN 'PASS'
                ELSE 'FAIL'
            END,
            '0 duplicates',
            CAST(@v_fail_count AS VARCHAR) + ' duplicates found',
            @v_fail_count
        );

        -- If duplicates found STOP the pipeline
        -- THROW raises error and jumps to CATCH

        IF @v_fail_count > 0 
        BEGIN
            THROW 50002,
                'DQ_B002 CRITICAL FAIL: Duplicate App_Id found in bronze',
                1;
        END

        PRINT 'DQ_B002 completed — Duplicates found: '
            + CAST(@v_fail_count AS VARCHAR);

        -- =========================================
        -- DQ_B003 : NULL App_Id Check
        -- Every row must have a valid App_Id
        -- NULL App_Id means row is untrackable
        -- Cannot link to any other table
        -- Severity : CRITICAL
        -- Pipeline STOPS if this fails
        -- =========================================

        -- Count rows where App_Id is NULL
        -- These rows are completely unusable
        SELECT @v_fail_count = COUNT(*)
        FROM bronze.applications
        WHERE App_Id IS NULL;

        -- Log result to dq_results
        INSERT INTO audit.dq_results(
            run_id,
            layer,
            rule_id,
            rule_description,
            severity,
            result,
            expected_value,
            actual_value,
            rows_affected
        )

        VALUES (
            @p_run_id,
            'BRONZE',
            'DQ_B003',
            'No NULL App_Id allowed in bronzer',
            'CRITICAL',
            CASE 
                WHEN @v_fail_count = 0
                THEN 'PASS'
                ELSE 'FAIL'
            END,
            '0 NULL App_Ids',
            CAST(@v_fail_count AS VARCHAR) + ' NULL App_Ids found',
            @v_fail_count
        );

        -- If NULL App_Id found STOP the pipeline
        IF @v_fail_count > 0
        BEGIN
            THROW 50003,
                'DQ_B003 CRITICAL FAIL: NULL App_Id found in bronze',
                1;
        END

        PRINT 'DQ_B003 completed — NULL App_Ids found: '
            + CAST(@v_fail_count AS VARCHAR);

        -- =========================================
        -- DQ_B004 : Valid Decision Values Check
        -- Decision column must contain only
        -- known valid values from source system
        -- Unknown values break Silver transform
        -- Severity : WARNING
        -- Pipeline continues but logs the issue
        -- =========================================

        -- Count rows with unrecognised Decision values
        -- NOT IN checks against all 13 known values
        -- NULL is allowed so we exclude it from check

        SELECT @v_fail_count = COUNT(*)
        FROM bronze.applications
        WHERE Decision NOT IN (
            'FINISH','DECLINED','CBLR','REJ',
            'IUND','QDE','PDOC','DUR','UND',
            'FIV','DUP','BDE'            
        )
        AND Decision IS NOT NULL;

        -- Log result to dq_results
        INSERT INTO audit.dq_results (
            run_id,
            layer,
            rule_id,
            rule_description,
            severity,
            result,
            expected_value,
            actual_value,
            rows_affected
        )

        VALUES (
            @p_run_id,
            'BRONZE',
            'DQ_B004',
            'Decision column must contain only valid known values',
            'WARNING',
            CASE
                WHEN @v_fail_count = 0 THEN 'PASS'
                ELSE 'FAIL'
            END,
            '0 invalid decisions',
            CAST(@v_fail_count AS VARCHAR) + ' invalid values found',
            @v_fail_count
        );

        -- WARNING only — do not stop pipeline
        -- Just log and continue to next rule

        PRINT 'DQ_B004 completed — Invalid Decision values: '
            + CAST(@v_fail_count AS VARCHAR);

        -- =========================================
        -- DQ_B005 : No Real PAN Leaked Check
        -- masked_pan in masked_attributes must NOT
        -- look like a real Indian PAN number
        -- Real PAN format: AAAAA9999A
        -- 5 letters + 4 digits + 1 letter
        -- If masked_pan matches this pattern
        -- masking procedure has a bug
        -- This is a critical security breach
        -- Severity : CRITICAL
        -- Pipeline STOPS immediately if fails
        -- =========================================

        -- Check masked_pan column for real PAN pattern
        -- LIKE pattern: 5 letters + 4 digits + 1 letter
        -- [A-Z] matches any capital letter
        -- [0-9] matches any digit
        SELECT @v_fail_count = COUNT(*)
        FROM bronze.masked_attributes
        WHERE masked_pan LIKE '[A-Z][A-Z][A-Z][A-Z][A-Z][0-9][0-9][0-9][0-9][A-Z]';

        -- Log result to dq_results
        INSERT INTO audit.dq_results (
            run_id,
            layer,
            rule_id,
            rule_description,
            severity,
            result,
            expected_value,
            actual_value,
            rows_affected
        )
        VALUES  (
            @p_run_id,
            'BRONZE',
            'DQ_B005',
            'No real PAN number must exist in masked_attributes',
            'CRITICAL',
            CASE 
                WHEN @v_fail_count = 0 THEN 'PASS'
                ELSE 'FAIL'
            END,
            '0 real PANs',
            CAST(@v_fail_count AS VARCHAR) + ' real PANs found',
            @v_fail_count
        );
        -- If real PAN found STOP immediately
        -- Security breach — no data moves forward
        IF @v_fail_count > 0
        BEGIN
            THROW 5005,
                'DQ_B005 CRITICAL FAIL: Real PAN found in masked_attributes — security breach',
                1;
        END

        PRINT 'DQ_B005 completed — Real PANs found: '
            + CAST(@v_fail_count AS VARCHAR);

        -- =========================================
        -- Close TRY Block
        -- If we reach here all 5 rules passed
        -- or only WARNING rules failed
        -- Pipeline can continue to Silver
        -- =========================================
        END TRY
        -- =========================================
        -- CATCH Block
        -- Only runs if CRITICAL rule failed
        -- Logs failure and stops pipeline
        -- =========================================
        BEGIN CATCH

            -- Capture exact error message
            SET @v_error_msg    =   ERROR_MESSAGE();

            PRINT 'DQ FAILED : ' + @v_error_msg;

            -- Update pipeline log with failure
            UPDATE audit.pipeline_run_log
            SET
                end_time        = GETDATE(),
                [status]        = 'DQ_FAILED',
                error_message   = @v_error_msg
            WHERE run_id = @p_run_id;

            -- Re-raise error to master pipeline    
            THROW;

        END CATCH
-- =========================================
-- Close Procedure
-- =========================================
END
GO

-- Execute DQ procedure
-- Pass run_id = 5 which is our successful bronze load
-- This links DQ results to that specific run
USE IndusLoanDB;
GO

EXEC bronze.usp_run_dq_bronze
    @p_run_id = 5,
    @p_env    = 'DEV';
GO