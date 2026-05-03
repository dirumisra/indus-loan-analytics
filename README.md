# 🏦 IndusLoan Analytics Platform
### Personal Loan Acquisition Analytics | End-to-End Data Engineering Portfolio Project

![SQL Server](https://img.shields.io/badge/SQL%20Server-2019-CC2927?style=for-the-badge&logo=microsoft-sql-server&logoColor=white)
![Python](https://img.shields.io/badge/Python-3.10+-3776AB?style=for-the-badge&logo=python&logoColor=white)
![Power BI](https://img.shields.io/badge/Power%20BI-Reporting-F2C811?style=for-the-badge&logo=powerbi&logoColor=black)
![GitHub](https://img.shields.io/badge/GitHub-Version%20Controlled-181717?style=for-the-badge&logo=github&logoColor=white)
![Status](https://img.shields.io/badge/Status-In%20Progress-orange?style=for-the-badge)

---

## 📌 Project Overview

This project simulates a **production-grade Personal Loan Acquisition Data Pipeline**
modeled on real retail banking operations at IndusInd Bank (2016).

It demonstrates end-to-end data engineering competency covering:

- ✅ Medallion Architecture — Raw → Bronze → Silver → Gold → Reporting
- ✅ PII Masking and Data Privacy — RBI Compliance
- ✅ Watermark-based Incremental Loading — Full and Incremental modes
- ✅ Slowly Changing Dimension Type 2 — Agent history tracking
- ✅ Data Quality Framework — 11 rules across Bronze and Silver
- ✅ Star Schema Design — 2 Facts · 7 Dimensions · 5 Aggregates
- ✅ Data Governance — Full audit trail, lineage, reconciliation
- ✅ Power BI Reporting — Row Level Security, executive dashboards

---

## 🏗️ Architecture

```
╔══════════════════════════════════════════════════════════════════════════════╗
║                    INDUS LOAN ANALYTICS PLATFORM                            ║
║                    Medallion Architecture — 14 Phases                       ║
╚══════════════════════════════════════════════════════════════════════════════╝

  ┌─────────────────────┐
  │      SOURCE          │
  │  banksalesdata.csv   │  22,155 rows · 24 columns
  │  IndusInd Bank 2016  │  Real personal loan applications
  └──────────┬──────────┘
             │  BULK INSERT
             ▼
  ┌─────────────────────────────────────────────────────────────────┐
  │                        RAW LAYER                                │
  │                      raw.applications                           │
  │  • Append-only — data is never modified here                    │
  │  • All 24 columns stored as VARCHAR — no casting                │
  │  • Byte-perfect copy of source file                             │
  │  • NULL allowed everywhere — source data is messy               │
  └──────────┬──────────────────────────────────────────────────────┘
             │  usp_load_bronze (FULL / INCR)
             ▼
  ┌─────────────────────────────────────────────────────────────────┐
  │                      BRONZE LAYER                               │
  │                     bronze.applications                         │
  │  • Watermark applied — incremental load tracking                │
  │  • PII Masked — PAN hashed · Name → initials · DOB → year      │
  │  • Agent codes replaced with pseudonyms (AGT_00001)             │
  │  • Record hash added — SHA2_256 for deduplication               │
  │  • Audit columns added — batch_id · load_timestamp              │
  │  • 5 DQ rules checked — CRITICAL stops pipeline                 │
  └──────────┬──────────────────────────────────────────────────────┘
             │  usp_transform_silver
             ▼
  ┌─────────────────────────────────────────────────────────────────┐
  │                      SILVER LAYER                               │
  │                     silver.applications                         │
  │  • 14 derived columns built using CTE chain                     │
  │  • Data types cast — dates, amounts, integers                   │
  │  • final_status — Approved · Declined · In Process              │
  │  • tat_hours · tat_bucket — turnaround time analysis            │
  │  • loan_amount_band · city_tier — segmentation                  │
  │  • is_approved · is_declined · is_in_process — BIT flags        │
  │  • Decline codes exploded → silver.decline_codes_parsed         │
  │  • 6 DQ rules checked — row reconciliation logged               │
  └──────────┬──────────────────────────────────────────────────────┘
             │  usp_load_gold
             ▼
  ┌─────────────────────────────────────────────────────────────────┐
  │                    GOLD LAYER — STAR SCHEMA                     │
  │                                                                 │
  │   DIMENSIONS                        FACTS                       │
  │   ┌─────────────┐                  ┌──────────────────┐        │
  │   │  dim_date   │──────────────────│ fact_application │        │
  │   └─────────────┘                  │                  │        │
  │   ┌─────────────┐                  │  2 date keys     │        │
  │   │dim_customer │─────────────────│  7 dim keys      │        │
  │   └─────────────┘                  │  5 measures      │        │
  │   ┌─────────────┐                  └────────┬─────────┘        │
  │   │  dim_agent  │                           │                   │
  │   │  SCD Type 2 │                  ┌────────▼─────────┐        │
  │   └─────────────┘                  │fact_decline_bridge│        │
  │   ┌─────────────┐                  │  many-to-many    │        │
  │   │ dim_channel │                  │  decline codes   │        │
  │   └─────────────┘                  └──────────────────┘        │
  │   ┌─────────────┐                                               │
  │   │ dim_product │          AGGREGATES                           │
  │   └─────────────┘          ┌─────────────────────────┐         │
  │   ┌─────────────┐          │  agg_approval_funnel     │        │
  │   │  dim_branch │          │  agg_agent_scorecard     │        │
  │   └─────────────┘          │  agg_tat_analysis        │        │
  │   ┌──────────────┐         │  agg_channel_performance │        │
  │   │dim_decline   │         │  agg_city_performance    │        │
  │   │   reason     │         └─────────────────────────┘         │
  │   └─────────────┘                                               │
  └──────────┬──────────────────────────────────────────────────────┘
             │  rpt.* views
             ▼
  ┌─────────────────────────────────────────────────────────────────┐
  │                    REPORTING LAYER                               │
  │                       rpt.* Views                               │
  │  • Indexed views over gold aggregates                           │
  │  • Row Level Security — branch level access control             │
  │  • Power BI connects here only — never to gold directly         │
  └──────────┬──────────────────────────────────────────────────────┘
             ▼
  ┌─────────────────────────────────────────────────────────────────┐
  │                        POWER BI                                  │
  │  • Approval Funnel Dashboard                                    │
  │  • Agent Scorecard                                              │
  │  • TAT Analysis                                                 │
  │  • Channel Performance                                          │
  │  • City and Region Heatmap                                      │
  └─────────────────────────────────────────────────────────────────┘

  ╔══════════════════════════════════════════════════════════════════╗
  ║               AUDIT SCHEMA — DATA GOVERNANCE                    ║
  ║       Runs alongside every layer — tracks everything            ║
  ║                                                                 ║
  ║  pipeline_run_log → dq_results → watermark_control             ║
  ║  layer_reconciliation → column_lineage → agent_pseudonym        ║
  ╚══════════════════════════════════════════════════════════════════╝
```

---

## 📂 Repository Structure

```
indus-loan-analytics/
│
├── sql/
│   ├── 00_setup/                          ← Phase 1 Foundation
│   │   ├── 01_create_schemas.sql          ← 6 schemas
│   │   ├── 02_create_audit_tables.sql     ← 5 audit tables
│   │   ├── 03_seed_watermark.sql          ← 2 seed rows
│   │   └── 04_create_agent_pseudonym.sql  ← PII lookup table
│   │
│   ├── 01_raw/                            ← Phase 2 Raw Layer
│   │   └── 01_create_raw_table.sql        ← 24 column raw table
│   │
│   ├── 02_bronze/                         ← Phase 3-4 coming soon
│   ├── 03_silver/                         ← Phase 5-7 coming soon
│   ├── 04_gold/                           ← Phase 8-11 coming soon
│   └── 05_reporting/                      ← Phase 12 coming soon
│
├── data/
│   └── sample_100_rows.csv
│
├── docs/
├── .gitignore
└── README.md
```

---

## 🗄️ Database Design

### Audit Schema — Data Governance Layer

| Table | Purpose | Governance Pillar |
|-------|---------|-------------------|
| `pipeline_run_log` | Tracks every pipeline execution | Auditability |
| `dq_results` | Every DQ rule result — PASS or FAIL | Data Quality |
| `watermark_control` | Manages incremental load state | Completeness |
| `layer_reconciliation` | Proves zero row loss across layers | Reconciliation |
| `column_lineage` | Documents every column transformation | Traceability |
| `agent_pseudonym` | Real agent codes mapped to fake codes | PII Protection |

### Gold Layer — Star Schema

| Table | Type | Key Columns |
|-------|------|-------------|
| `fact_application` | Fact | loan_amount · tat_hours · is_approved |
| `fact_decline_bridge` | Bridge Fact | app_id · decline_code · is_primary |
| `dim_date` | Dimension | date · month · quarter · year |
| `dim_customer` | Dimension | segment · city · city_tier |
| `dim_agent` | SCD Type 2 | agent_code · branch · effective_from · effective_to |
| `dim_channel` | Dimension | channel_code · channel_type |
| `dim_product` | Dimension | product_code · scheme · fee_code |
| `dim_branch` | Dimension | branch_code · city · region |
| `dim_decline_reason` | Dimension | decline_code · category |

---

## ⚙️ Tech Stack

| Tool | Version | Purpose |
|------|---------|---------|
| SQL Server | 2019 | Core database engine |
| T-SQL | — | DDL · Stored Procedures · DQ Rules |
| SSMS | 19+ | Database development |
| VS Code | Latest | Code editor · Git integration |
| Python | 3.10+ | Synthetic data generation |
| Power BI | Desktop | Reporting · Dashboards · RLS |
| Git | Latest | Version control |
| GitHub | — | Remote repository |

---

## 🚀 Setup Guide

```bash
# Step 1 — Clone the repository
git clone https://github.com/dirumisra/indus-loan-analytics.git
cd indus-loan-analytics
```

```
# Step 2 — Run in SSMS in this exact order
1. sql/00_setup/01_create_schemas.sql
2. sql/00_setup/02_create_audit_tables.sql
3. sql/00_setup/03_seed_watermark.sql
4. sql/00_setup/04_create_agent_pseudonym.sql
5. sql/01_raw/01_create_raw_table.sql
```

---

## 📊 Source Data Profile

| Attribute | Value |
|-----------|-------|
| Source | IndusInd Bank Personal Loan Applications |
| Year | 2016 |
| Total Records | 22,155 rows |
| Total Columns | 24 columns |
| Decision Values | 13 unique — FINISH · DECLINED · CBLR · REJ... |
| Sourcing Channels | 16 unique — INH · DSA · BRANCH · PBA... |
| Products | 7 unique — LAA701 · LAA702 · PLCIBIL... |
| Campaign Types | 165 unique |
| Null Rate | Up to 64% in some columns |

---

## 📈 Phase Progress

| Phase | Description | Status |
|-------|-------------|--------|
| 1 | Foundation — DB · schemas · audit tables · seeds | ✅ Complete |
| 2 | Raw Layer — 24 column table · BULK INSERT | ✅ Complete |
| 3 | Bronze — PII masking · watermark · TRY/CATCH | ⏳ Pending |
| 4 | Bronze DQ — 5 rules · CRITICAL stop logic | ⏳ Pending |
| 5 | Silver — 14 derived columns · CTE chain | ⏳ Pending |
| 6 | Silver — decline code parser · STRING_SPLIT | ⏳ Pending |
| 7 | Silver DQ — 6 rules · row reconciliation | ⏳ Pending |
| 8 | Gold — 7 dimensions · MERGE statements | ⏳ Pending |
| 9 | Gold — SCD Type 2 · dim_agent | ⏳ Pending |
| 10 | Gold — fact_application · fact_decline_bridge | ⏳ Pending |
| 11 | Gold — 5 aggregation tables · RANK · LAG · NTILE | ⏳ Pending |
| 12 | Reporting — Power BI · RLS · rpt.* views | ⏳ Pending |
| 13 | Master pipeline orchestrator | ⏳ Pending |
| 14 | Testing · 5 test scripts · documentation | ⏳ Pending |

---

## 🏛️ Data Governance

| Framework | How We Implement It |
|-----------|-------------------|
| DAMA-DMBOK | Full audit trail · data quality · lineage |
| ISO 8000 | Layer reconciliation — variance must always be zero |
| RBI Guidelines | PII masking · audit retention · reproducible reports |

---

## 👤 Author

**Dhiraj Kumar**
Data Engineering Portfolio Project

[![GitHub](https://img.shields.io/badge/GitHub-dirumisra-181717?style=for-the-badge&logo=github)](https://github.com/dirumisra)
