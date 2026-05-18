# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Snowflake supply chain analytics pipeline built on the DataCo Supply Chain Dataset (Kaggle CSV). Data flows from S3 into Snowflake through a three-layer medallion architecture, ultimately powering a Power BI dashboard.

**Full pipeline:**
```
Kaggle CSV → Amazon S3 → Snowflake External Stage → RAW table → CLEAN table → Analytics Views → Power BI
```

## Architecture

The Snowflake database `SUPPLY_CHAIN_DB` has three schemas:

| Schema | Purpose |
|---|---|
| `RAW` | All-VARCHAR ingestion table + CSV file format + S3 external stage |
| `CLEAN` | Type-cast table built with `TRY_TO_*` functions; also drops PII columns |
| `ANALYTICS` | Aggregated views consumed by Power BI |

**Scripts must be executed in numbered order (01 → 09).** Each file is a discrete setup step; `PROJECT.sql` is a consolidated single-file version of all steps.

### Key design decisions

- **Raw layer is all VARCHAR** — absorbs malformed data without load failures; `ON_ERROR = 'CONTINUE'` in the COPY INTO.
- **`TRY_TO_*` casting in the clean layer** — safe casts that return NULL instead of erroring; date format is `'MM/DD/YYYY HH24:MI'`.
- **PII is dropped in the clean layer** — `customer_email`, `customer_fname`, `customer_lname`, `customer_password`, `customer_street`, `customer_zipcode`, `latitude`, `longitude`, and card/product IDs are present in RAW but excluded from CLEAN.
- **`DAILY_REFRESH_TASK`** (in `09_task_automation.sql`) runs `CRON 0 0 * * * UTC` to rebuild the clean table nightly. Note: this task's SELECT is a reduced column set compared to the full clean table in `06_clean_layer.sql` — it omits `DEPARTMENT_ID`, `DEPARTMENT_NAME`, `ORDER_CUSTOMER_ID`, and all `ORDER_ITEM_*` detail columns.

### Analytics views (`SUPPLY_CHAIN_DB.ANALYTICS`)

| View | What it answers |
|---|---|
| `VW_SHIPPING_PERFORMANCE` | Late delivery rate and average shipping days by shipping mode |
| `VW_REVENUE_BY_CATEGORY` | Total revenue and profit by product category |
| `VW_MONTHLY_REVENUE` | Month-over-month revenue and profit (used with `LAG()` for growth %) |

## AWS / Snowflake Integration Setup

The S3 storage integration requires a manual two-step handshake:

1. Run `DESC STORAGE INTEGRATION S3_INT` in Snowflake to get `STORAGE_AWS_IAM_USER_ARN` and `STORAGE_AWS_EXTERNAL_ID`.
2. Update the IAM role's trust relationship in AWS with those values (template in `PROJECT_ORIGINAL.sql` lines 86–102).

- S3 bucket: `s3://snowflake-supply-chain-rp/`
- Source file: `DataCoSupplyChainDataset.csv`
- IAM role ARN: `arn:aws:iam::066113723620:role/snowflake_supplychain`

## Useful Commands

Run these in Snowflake's worksheet or SnowSQL.

**Verify stage files loaded:**
```sql
LIST @SUPPLY_CHAIN_DB.RAW.SUPPLY_CHAIN_S3_STAGE;
```

**Validate row counts match between layers:**
```sql
SELECT COUNT(*) FROM SUPPLY_CHAIN_DB.RAW.RAW_DATACO_SUPPLY_CHAIN;   -- expect 180,519
SELECT COUNT(*) FROM SUPPLY_CHAIN_DB.CLEAN.CLEAN_SUPPLY_CHAIN;
```

**Check data types after cleaning:**
```sql
DESC TABLE SUPPLY_CHAIN_DB.CLEAN.CLEAN_SUPPLY_CHAIN;
```

**Check task status:**
```sql
SHOW TASKS IN SUPPLY_CHAIN_DB.CLEAN;
```

**Manually resume the daily refresh task (required after creation):**
```sql
ALTER TASK SUPPLY_CHAIN_DB.CLEAN.DAILY_REFRESH_TASK RESUME;
```
