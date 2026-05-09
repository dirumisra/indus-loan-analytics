-- =============================================
-- File     : 01_create_bronze_table.sql
-- Project  : IndusLoan Analytics Platform
-- Author   : Dhiraj Kumar
-- Phase    : 3 - Bronze Layer
-- Purpose  : Create bronze.applications table
--            Bronze adds 8 audit and masking columns
--            on top of raw 24 columns
--            Total = 32 columns
--            All original columns kept as VARCHAR
--            Masking happens in load procedure
-- =============================================

USE IndusLoanDB;
GO

CREATE TABLE bronze.applications (
    -- ==========================================
    -- SECTION 1 : Audit columns added by Bronze
    -- These do not exist in raw layer
    -- ==========================================
    
    -- Unique ID for each pipeline run
    -- Links this row to audit.pipeline_run_log
    batch_id            INT             NOT NULL,

    -- Exact time this row was loaded into Bronze
    load_timestamp      DATETIME        NOT NULL      DEFAULT GETDATE(),

     -- SHA2_256 fingerprint of entire row
    -- Used to detect if same row loaded twice
    record_hash         VARBINARY(32)   NOT NULL,

    -- ==========================================
    -- SECTION 2 : Original columns from Raw
    -- Kept exactly as they came from source
    -- ==========================================

    App_Id                  VARCHAR(20)     NULL,
    Customer_Name           VARCHAR(200)    NULL,
    Date_Of_Birth           VARCHAR(20)     NULL,
    PAN_No                  VARCHAR(20)     NULL,
    Product                 VARCHAR(20)     NULL,
    Campaign_Type           VARCHAR(100)    NULL,
    Decision                VARCHAR(20)     NULL,
    Decision_Date           VARCHAR(30)     NULL,
    Stage                   VARCHAR(100)    NULL,
    Decline_Code            VARCHAR(200)    NULL,
    Sourcing_Channel        VARCHAR(50)     NULL,
    DSA_Code                VARCHAR(20)     NULL,
    DSE_Code                VARCHAR(20)     NULL,
    Secondary_DSE_Code      VARCHAR(20)     NULL,
    Scheme_Id               VARCHAR(50)     NULL,
    Appl_Running_Serial_No  VARCHAR(30)     NULL,
    Signed_Date             VARCHAR(30)     NULL,
    Sourcing_Branch_Code    VARCHAR(20)     NULL,
    Residence_City          VARCHAR(100)    NULL,
    Fee_Code                VARCHAR(20)     NULL,
    Loan_Amount             VARCHAR(20)     NULL,
    Mailing_City            VARCHAR(100)    NULL,
    Type_Of_Organization    VARCHAR(100)    NULL,
    You_Are                 VARCHAR(50)     NULL,

    -- ==========================================
    -- SECTION 3 : Masked columns added by Bronze
    -- These replace PII with safe values
    -- Original PII columns kept above for audit
    -- ==========================================

    -- Customer name reduced to initials only
    -- Example: RAJEEV RAMADHAR SINGH → R.S
    masked_name             VARCHAR(20)         NULL,

    -- PAN number replaced with SHA2_256 hash
    -- Original PAN is never stored in Silver or Gold
    masked_pan              VARCHAR(20)         NULL,

    -- Only birth year extracted from full DOB
    -- Example: 07-05-75 → 1975
    birth_year          INT         NULL,

    -- DSE code replaced with pseudonym
    -- Example: C27500 → AGT_00001
    masked_dse_code      VARCHAR(20)    NULL,

    -- Secondary DSE code also replaced
    -- Example: 38188 → AGT_00002
    masked_secondary_dse   VARCHAR(20)   NULL
);
GO

PRINT 'TABLE bronze.applications created — 32 columns';
GO


-- =============================================
-- ALTER : Remove masking columns from bronze
-- These columns will move to separate table
-- bronze.masked_attributes
-- Learning : ALTER TABLE DROP COLUMN syntax
-- =============================================

-- Remove masked_name column
ALTER TABLE bronze.applications
DROP COLUMN masked_name;
GO

-- Remove masked_pan column
ALTER TABLE bronze.applications
DROP COLUMN masked_pan;
GO

-- Remove birth_year column
ALTER TABLE bronze.applications
DROP COLUMN birth_year;
GO

-- Remove masked_dse_code column
ALTER TABLE bronze.applications
DROP COLUMN masked_dse_code;
GO

-- Remove masked_secondary_dse column
ALTER TABLE bronze.applications
DROP COLUMN masked_secondary_dse;
GO

-- Verify remaining columns
-- Expected : 27 columns
SELECT 
    column_id,
    name        AS column_name,
    max_length
FROM sys.columns
WHERE object_id = OBJECT_ID('bronze.applications')
ORDER BY column_id;
GO

-- =============================================
-- File     : 02_create_masked_attributes.sql
-- Project  : IndusLoan Analytics Platform
-- Author   : Dhiraj Kumar
-- Phase    : 3 - Bronze Layer
-- Purpose  : Create bronze.masked_attributes table
--            Stores all PII masked values separately
--            Linked to bronze.applications via App_Id
--            Silver layer joins here for masked values
--            Analytics team never needs bronze.applications
--            PII auditors only need this table
-- Design   : Dhiraj Kumar (proposed separate dim approach)
-- =============================================

USE IndusLoanDB;
GO

CREATE TABLE bronze.masked_attributes (

    -- App_Id links back to bronze.applications
    -- One row per application — same as fact table
    App_Id                  VARCHAR(20)     NOT NULL,

    -- Customer name reduced to initials only
    -- Example: RAJEEV RAMADHAR SINGH → R.S
    masked_name             VARCHAR(20)     NULL,

    -- PAN number replaced with SHA2_256 hash
    -- Original PAN never travels beyond this table
    masked_pan              VARCHAR(64)     NULL,

    -- Only birth year extracted from full DOB
    -- Example: 07-05-75 → 1975
    birth_year              INT             NULL,

    -- DSE code replaced with pseudonym from
    -- audit.agent_pseudonym lookup table
    -- Example: C27500 → AGT_00001
    masked_dse_code         VARCHAR(20)     NULL,

    -- Secondary DSE also pseudonymised
    -- Example: 38188 → AGT_00002
    masked_secondary_dse    VARCHAR(20)     NULL,

    -- When this masking record was created
    masked_at               DATETIME        NOT NULL  DEFAULT GETDATE(),

    -- Primary key on App_Id
    -- One masking record per application only
    CONSTRAINT PK_masked_attributes 
        PRIMARY KEY (App_Id)
);
GO

PRINT 'TABLE bronze.masked_attributes created — 7 columns';
GO

-- Verify table structure
SELECT  
    column_id,
    name        AS column_name,
    max_length
FROM sys.columns
WHERE object_id = OBJECT_ID('bronze.masked_attributes')
ORDER BY column_id;
GO