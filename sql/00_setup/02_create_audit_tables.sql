-- =============================================
-- File     : 02_create_audit_tables.sql
-- Project  : IndusLoan Analytics Platform
-- Author   : Dhiraj Kumar
-- Phase    : 1 - Foundation
-- Purpose  : Create all 5 audit tables in correct
--            dependency order
-- =============================================

USE IndusLoanDB;
GO

-- TABLE 1
-- pipeline_run_log is created first because
-- all other audit tables reference run_id from this table

CREATE TABLE audit.pipeline_run_log (
    run_id            INT IDENTITY(1,1)  PRIMARY KEY,
    pipeline_name     VARCHAR(100)       NOT NULL,
    p_load_type       VARCHAR(10)        NULL,
    p_run_date        DATE               NULL,
    p_env             VARCHAR(10)        NULL,
    start_time        DATETIME           NOT NULL DEFAULT GETDATE(),
    end_time          DATETIME           NULL,
    duration_seconds  AS DATEDIFF(ss, start_time, end_time),
    status            VARCHAR(20)        NOT NULL DEFAULT 'RUNNING',
    rows_ingested     INT                NULL,
    rows_transformed  INT                NULL,
    rows_gold         INT                NULL,
    watermark_start   VARCHAR(100)       NULL,
    watermark_end     VARCHAR(100)       NULL,
    error_message     VARCHAR(MAX)       NULL,
    created_by        VARCHAR(100)       NOT NULL DEFAULT SYSTEM_USER
);
GO

-- TABLE 2
-- dq_results stores every data quality rule result
-- run_id links back to pipeline_run_log

CREATE TABLE audit.dq_results (
    dq_id            INT IDENTITY(1,1)  PRIMARY KEY,
    run_id           INT                NOT NULL,
    layer            VARCHAR(20)        NOT NULL,
    rule_id          VARCHAR(20)        NOT NULL,
    rule_description VARCHAR(500)       NOT NULL,
    severity         VARCHAR(10)        NOT NULL,
    result           CHAR(4)            NOT NULL,
    expected_value   VARCHAR(100)       NULL,
    actual_value     VARCHAR(100)       NULL,
    rows_affected    INT                NULL,
    checked_at       DATETIME           NOT NULL DEFAULT GETDATE(),

    CONSTRAINT FK_dq_results_run
        FOREIGN KEY (run_id)
        REFERENCES audit.pipeline_run_log(run_id)
);
GO

-- TABLE 3
-- watermark_control remembers where we stopped last time
-- One row per pipeline forever

CREATE TABLE audit.watermark_control (
    pipeline_name    VARCHAR(100)   NOT NULL,
    watermark_column VARCHAR(100)   NOT NULL,
    last_watermark   VARCHAR(100)   NOT NULL DEFAULT '0',
    last_run_id      INT            NULL,
    last_run_status  VARCHAR(20)    NULL,
    updated_at       DATETIME       NOT NULL DEFAULT GETDATE(),

    CONSTRAINT PK_watermark_control
        PRIMARY KEY (pipeline_name)
);
GO

-- TABLE 4
-- layer_reconciliation proves no rows were lost
-- between layers variance must always be zero

CREATE TABLE audit.layer_reconciliation (
    recon_id           INT IDENTITY(1,1)  PRIMARY KEY,
    run_id             INT                NOT NULL,
    layer              VARCHAR(20)        NOT NULL,
    source_layer       VARCHAR(20)        NOT NULL,
    source_row_count   INT                NOT NULL,
    target_row_count   INT                NOT NULL,
    rejected_row_count INT                NOT NULL DEFAULT 0,
    is_reconciled      BIT                NOT NULL DEFAULT 0,
    variance           AS (source_row_count - target_row_count - rejected_row_count),
    checked_at         DATETIME           NOT NULL DEFAULT GETDATE(),

    CONSTRAINT FK_layer_recon_run
        FOREIGN KEY (run_id)
        REFERENCES audit.pipeline_run_log(run_id)
);
GO

-- TABLE 5
-- column_lineage documents where every column came from
-- Built once, never changes

CREATE TABLE audit.column_lineage (
    lineage_id           INT IDENTITY(1,1)  PRIMARY KEY,
    target_column        VARCHAR(100)       NOT NULL,
    target_table         VARCHAR(200)       NOT NULL,
    source_columns       VARCHAR(500)       NULL,
    transformation_logic VARCHAR(MAX)       NULL,
    created_by_proc      VARCHAR(200)       NULL,
    layer                VARCHAR(20)        NOT NULL,
    is_pii_derived       BIT                NOT NULL DEFAULT 0,
    registered_at        DATETIME           NOT NULL DEFAULT GETDATE()
);
GO