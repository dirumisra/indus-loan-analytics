-- =============================================
-- File     : 04_create_agent_pseudonym.sql
-- Project  : IndusLoan Analytics Platform
-- Author   : Dhiraj Kumar
-- Phase    : 1 - Foundation
-- Purpose  : Create agent pseudonym table
--            This table protects agent identity
--            Real code C27500 becomes AGT_00001
--            Table starts empty and fills automatically
--            when Bronze load runs for first time
-- =============================================

USE IndusLoanDB;
GO

CREATE TABLE audit.agent_pseudonym (
    real_code    VARCHAR(20)   NOT NULL,
    pseudo_code  VARCHAR(20)   NOT NULL,
    created_at   DATETIME      NOT NULL  DEFAULT GETDATE(),

    -- same agent can never get two different fake codes
    CONSTRAINT PK_agent_pseudonym
        PRIMARY KEY (real_code),

    -- two agents can never share the same fake code
    CONSTRAINT UQ_agent_pseudonym_pseudo
        UNIQUE (pseudo_code)
);
GO

-- =============================================
-- File     : 01_create_raw_table.sql
-- Project  : IndusLoan Analytics Platform
-- Author   : Dhiraj Kumar
-- Phase    : 1 - Foundation
-- Purpose  : Create raw.applications table
--            This is first landing table for source data
--            All columns are VARCHAR — no casting here
--            Matches banksalesdata.csv exactly — 24 columns
--            NULL allowed in every column
--            Raw layer is never modified after data lands
-- =============================================

USE IndusLoanDB;
GO

CREATE TABLE raw.applications (

    -- Customer identity columns
    App_Id                  VARCHAR(20),
    Customer_Name           VARCHAR(200),
    Date_Of_Birth           VARCHAR(20),
    PAN_No                  VARCHAR(20),

    -- Product information
    Product                 VARCHAR(20),
    Campaign_Type           VARCHAR(100),
    Scheme_Id               VARCHAR(50),
    Fee_Code                VARCHAR(20),

    -- Decision information
    Decision                VARCHAR(20),
    Decision_Date           VARCHAR(30),
    Stage                   VARCHAR(100),
    Decline_Code            VARCHAR(200),

    -- Channel and agent information
    Sourcing_Channel        VARCHAR(50),
    DSA_Code                VARCHAR(20),
    DSE_Code                VARCHAR(20),
    Secondary_DSE_Code      VARCHAR(20),

    -- Application tracking
    Appl_Running_Serial_No  VARCHAR(30),
    Signed_Date             VARCHAR(30),

    -- Location information
    Sourcing_Branch_Code    VARCHAR(20),
    Residence_City          VARCHAR(100),
    Mailing_City            VARCHAR(100),

    -- Financial information
    Loan_Amount             VARCHAR(20),

    -- Customer profile
    Type_Of_Organization    VARCHAR(100),
    You_Are                 VARCHAR(50)
);
GO