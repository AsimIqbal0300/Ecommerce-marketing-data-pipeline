# E-commerce Marketing Data Pipeline

## Overview

This project is an end-to-end data pipeline built to solve a real problem faced by digital marketing agencies: consolidating fragmented advertising and analytics data from multiple paid channels into a single, reliable source of truth for reporting.

E-commerce brands typically run ads across multiple platforms simultaneously — Google and Meta — while also tracking on-site behavior through GA4. Each of these platforms exposes data through its own API, its own schema, and its own quirks. Left unmanaged, this leads to scattered spreadsheets, inconsistent metrics, and dashboards that are painful to trust or maintain.

This pipeline automates the entire journey from raw platform data to a clean, business-ready reporting layer — removing manual data pulls and giving marketing and leadership teams a single, accurate view of paid performance.

## Architecture

```
Google Ads ─┐
Meta Ads ────┼──▶  Airbyte  ──▶  BigQuery  ──▶  dbt  ──▶  Power BI / Looker Studio
GA4 ─────────┘
   (Sources)      (Ingestion)   (Warehouse)  (Transform)      (Reporting)
```

**Flow summary:**
1. **Airbyte** extracts raw data from each advertising and analytics platform on a scheduled sync
2. Data lands in **BigQuery** as raw, untouched source tables
3. **dbt** transforms that raw data into clean, tested, analysis-ready models — standardizing fields, joining across sources, and building reusable metrics
4. **Power BI / Looker Studio** connects directly to the final dbt models to power live dashboards

## Data Sources

| Source | Data Captured |
|---|---|
| Google Ads | Campaign spend, clicks, impressions, conversions |
| Meta Ads | Campaign spend, clicks, impressions, conversions |
| GA4 | Website sessions, user behavior, on-site conversions |

## Tech Stack

- **Ingestion:** [Airbyte](https://airbyte.com/) — open-source data movement platform
- **Data Warehouse:** [Google BigQuery](https://cloud.google.com/bigquery)
- **Transformation:** [dbt](https://www.getdbt.com/) — SQL-based modeling, testing, and documentation
- **Visualization:** Power BI / Looker Studio
- **Version Control:** Git / GitHub

## What This Project Demonstrates

- **Multi-source ingestion** — connecting and syncing several distinct ad platform APIs alongside GA4 into a unified warehouse
- **Data modeling** — structuring raw data into staging and mart layers following dbt best practices, rather than querying raw tables directly
- **Data quality & testing** — applying dbt tests (e.g. not-null, unique, relationships) to catch broken or duplicate data before it reaches a dashboard
- **Cross-channel standardization** — unifying inconsistent naming and schemas across platforms (e.g. "spend" vs "cost", differing campaign ID formats) into one consistent structure
- **BI-ready output** — designing final models specifically for direct consumption by Power BI / Looker Studio, minimizing logic duplicated inside the dashboard layer

## Project Structure

```
models/
├── staging/        # 1:1 cleaned versions of raw source tables (per platform)
├── intermediate/   # Joins and business logic shared across marts
└── marts/          # Final, reporting-ready tables used by dashboards
```

## Why This Matters

Agencies and in-house marketing teams managing multiple brands or ad accounts face this exact challenge at scale — manually pulling reports from each platform doesn't scale past a handful of accounts. This project reflects the kind of pipeline architecture used to solve that problem properly: automated, tested, and built to grow as more brands or channels are added.

## Future Improvements

- Add orchestration (e.g. Dagster) to monitor and schedule syncs across all sources
- Incremental models in dbt to reduce processing cost as data volume grows
- CI/CD pipeline for automated dbt testing on every commit
- Support for additional channels (Snapchat Ads, TikTok Ads, Apple Ads)

---

**Author:** Asim Iqbal
**Contact:** [GitHub](https://github.com/AsimIqbal0300)
