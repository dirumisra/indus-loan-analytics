-- =============================================
-- File     : 03_seed_watermark.sql
-- Project  : IndusLoan Analytics Platform
-- Author   : Dhiraj Kumar
-- Phase    : 1 - Foundation
-- Purpose  : Seed initial 2 rows into watermark_control
--            last_watermark starts at 0 which means
--            first run will load ALL rows from source
-- =============================================

USE IndusLoanDB;
GO

-- applications pipeline watermark on App_Id
-- agent_master pipeline watermark on dsa_code

INSERT INTO audit.watermark_control
    (pipeline_name, watermark_column, last_watermark)
VALUES
    ('applications', 'App_Id',   '0'),
    ('agent_master', 'dsa_code', '0');
GO