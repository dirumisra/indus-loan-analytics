-- =============================================
-- File     : 02_bulk_insert_raw.sql
-- Project  : IndusLoan Analytics Platform
-- Author   : Dhiraj Kumar
-- Phase    : 2 - Raw Load
-- Purpose  : Load banksalesdata.csv into raw.applications
--            FIRSTROW = 2 skips the header row
--            FIELDTERMINATOR = comma separated file
--            FIELDQUOTE handles quoted fields like
--            "DVX183, DPX046" in Decline_Code column
--            TABLOCK = faster load by locking table
--            All 22155 rows should load successfully
-- =============================================

USE IndusLoanDB;
GO

-- First clear any partial rows from previous attempt
TRUNCATE TABLE raw.applications;
GO

-- Load CSV with FIELDQUOTE to handle quoted commas
BULK INSERT raw.applications
FROM 'C:\IndusLoan\data\banksalesdata.csv'
WITH (
    FIRSTROW         = 2,
    FIELDTERMINATOR  = ',',
    ROWTERMINATOR    = '\n',
    FIELDQUOTE       = '"',
    TABLOCK
);
GO

-- Verify row count after load
-- Expected result : 22155 rows
SELECT COUNT(*) AS total_rows 
FROM raw.applications;
GO

-- Check how many duplicate rows exist
WITH CTE AS (
    SELECT *,
        ROW_NUMBER() OVER(PARTITION BY app_id
        ORDER BY(SELECT NULL)
    ) AS rn
    FROM [raw].applications
)
SELECT COUNT(*) AS duplicate_raws
FROM CTE
WHERE rn >1;

-- Using CTE to remove duplicate rows
-- PARTITION BY App_Id and PAN_No means
-- if same App_Id and PAN_No appears more than once
-- ROW_NUMBER gives first occurrence rn = 1
-- second occurrence rn = 2 and so on
-- We DELETE everything where rn > 1
-- keeping only the first occurrence of each record
WITH CTE AS (
    SELECT *,
        ROW_NUMBER() OVER(PARTITION BY app_id
        ORDER BY (SELECT NULL)
        ) AS rn
    FROM [raw].applications
)
DELETE  FROM CTE
WHERE rn >1;

-- Final row count check

SELECT COUNT(*) FROM [raw].applications