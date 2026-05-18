# Supply Chain Analytics — Snowflake + Python

End-to-end analytics pipeline for the DataCo Supply Chain dataset. Raw CSV data is ingested from AWS S3 into Snowflake, cleaned and transformed through a three-layer architecture, and surfaced as Python-generated charts and an automated weekly markdown report.

---

## Architecture

```
Kaggle CSV (180,519 rows)
       │
       ▼
 AWS S3 Bucket
 (snowflake-supply-chain-rp)
       │
       ▼
 Snowflake External Stage
 (SUPPLY_CHAIN_S3_STAGE)
       │
       ▼
 RAW Schema
 RAW_DATACO_SUPPLY_CHAIN
 (all columns stored as VARCHAR —
  absorbs bad data without load failures)
       │
       ▼
 CLEAN Schema
 CLEAN_SUPPLY_CHAIN
 (columns cast to correct types via TRY_TO_*,
  PII fields removed, daily refresh task scheduled)
       │
       ▼
 ANALYTICS Schema
 ├── VW_REVENUE_BY_CATEGORY
 ├── VW_SHIPPING_PERFORMANCE
 └── VW_MONTHLY_REVENUE
       │
       ▼
 Python (pandas + matplotlib)
 ├── snowflake_extract.py  →  revenue_by_category.csv + chart
 └── weekly_report.py      →  3 charts + weekly_report.md
       │
       ▼
 Power BI Dashboard
```

---

## Key Business Insights

The pipeline is built to answer three core supply chain questions:

**Revenue & Profitability**
- Which product categories drive the most revenue and profit?
- Revenue and profit margin are tracked together so high-revenue but low-margin categories are visible immediately.

**Shipping & Delivery Risk**
- Late delivery risk is flagged at the order level and aggregated by shipping mode.
- The analysis identifies which fulfilment methods carry the highest late delivery percentage, enabling logistics decisions based on data rather than assumption.

**Revenue Trends Over Time**
- Monthly revenue and profit are tracked side by side.
- Month-over-month growth percentage is calculated using a `LAG()` window function, making seasonal patterns and growth inflection points easy to spot.

---

## Project Files

| File | Purpose |
|---|---|
| `01_SETUP.SQL.sql` | Creates warehouse, database, and schemas |
| `02_FILE_FORMAT.SQL.sql` | Defines the CSV file format for S3 ingestion |
| `03_storage_integration.sql` | Links Snowflake to the AWS S3 bucket via IAM |
| `04_raw_table.sql` | Creates the all-VARCHAR raw landing table |
| `05_copy_into.sql` | Loads the CSV from S3 into the raw table |
| `06_clean_layer.sql` | Builds the typed, PII-free clean table + validation queries |
| `07_analytics_views.sql` | Creates the three analytics views |
| `08_kpi_queries.sql` | Ad-hoc KPI queries (revenue, profit, top products) |
| `09_task_automation.sql` | Schedules a nightly task to rebuild the clean table |
| `snowflake_extract.py` | Extracts `VW_REVENUE_BY_CATEGORY` → CSV + bar chart |
| `weekly_report.py` | Pulls all three views → 3 charts + `weekly_report.md` |
| `PROJECT.sql` | Single-file version of all SQL steps combined |

---

## How to Run

### Prerequisites

- Snowflake account with `ACCOUNTADMIN` role (required for storage integration setup)
- AWS account with an S3 bucket and IAM role configured
- Python 3.8+

### 1 — Snowflake Setup (run SQL files in order)

Open each file in Snowflake's worksheet and execute in sequence:

```
01_SETUP.SQL.sql
02_FILE_FORMAT.SQL.sql
03_storage_integration.sql   ← requires AWS IAM trust relationship update (see note below)
04_raw_table.sql
05_copy_into.sql
06_clean_layer.sql
07_analytics_views.sql
08_kpi_queries.sql           ← optional, ad-hoc queries only
09_task_automation.sql
```

> **AWS IAM note:** After running `03_storage_integration.sql`, run `DESC STORAGE INTEGRATION S3_INT` and copy the `STORAGE_AWS_IAM_USER_ARN` and `STORAGE_AWS_EXTERNAL_ID` values. Paste them into the IAM role's trust relationship policy in AWS before proceeding.

### 2 — Install Python dependencies

```bash
pip install snowflake-connector-python pandas matplotlib
```

### 3 — Run the extract script

Pulls `VW_REVENUE_BY_CATEGORY`, saves a CSV, and generates a bar chart:

```bash
python snowflake_extract.py
```

Output: `revenue_by_category.csv`, `revenue_chart.png`

### 4 — Run the weekly report

Pulls all three views, generates three charts, and writes a markdown summary:

```bash
python weekly_report.py
```

Output: `chart_revenue_by_category.png`, `chart_shipping_performance.png`, `chart_monthly_revenue.png`, `weekly_report.md`

---

## Technologies

| Layer | Technology |
|---|---|
| Cloud storage | AWS S3 |
| Data warehouse | Snowflake |
| Orchestration | Snowflake Tasks (cron) |
| Data manipulation | Python 3, pandas |
| Visualisation | matplotlib |
| Reporting | Markdown |
| BI dashboard | Power BI |
| Dataset | [DataCo Supply Chain Dataset — Kaggle](https://www.kaggle.com/datasets/shashwatwork/dataco-smart-supply-chain-for-big-data-analysis) |
