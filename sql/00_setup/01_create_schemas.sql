-- =============================================
-- File     : 01_create_schemas.sql
-- Project  : IndusLoan Analytics Platform
-- Author   : Dhiraj Kumar
-- Phase    : 1 - Foundation
-- Purpose  : Create all 6 schemas in IndusLoanDB
-- =============================================

USE IndusLoanDB;
GO

-- raw    = source data lands here, never touched
-- bronze = data gets cleaned and masked here
-- silver = business logic and transformations happen here
-- gold   = final star schema for reporting
-- rpt    = views that Power BI will connect to
-- audit  = all pipeline logs and tracking tables live here

CREATE SCHEMA raw;
CREATE SCHEMA bronze;
CREATE SCHEMA silver;
CREATE SCHEMA gold;
CREATE SCHEMA rpt;
CREATE SCHEMA audit;
GO