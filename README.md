# E-commerce Marketing Data Pipeline

An end-to-end analytics engineering pipeline that ingests paid advertising and web analytics data for a GCC e-commerce client, transforms it through a layered dbt architecture, and delivers a CEO-facing Power BI dashboard.

**Stack:** Airbyte → BigQuery → dbt → Power BI

---

## Table of Contents
- [Overview](#overview)
- [Architecture](#architecture)
- [Data Sources](#data-sources)
- [Ingestion Layer — Airbyte](#ingestion-layer--airbyte)
- [Warehouse — BigQuery](#warehouse--bigquery)
- [Transformation Layer — dbt](#transformation-layer--dbt)
- [Data Model](#data-model)
- [Testing](#testing)
- [Documentation](#documentation)
- [Dashboard — Power BI](#dashboard--power-bi)
- [Key Challenges & Decisions](#key-challenges--decisions)
- [Project Structure](#project-structure)
- [Future Improvements](#future-improvements)

---

## Overview

A GCC e-commerce client runs paid advertising across Google Ads and Meta Ads, alongside GA4 for on-site behavior tracking. Each platform exposes data through its own API, schema, and naming conventions. This project consolidates all three into a single, tested, dimensionally-modeled source of truth, and surfaces it through an executive-level Power BI report.

The goal was not just to move data from A to B, but to build the pipeline the way a real analytics engineering team would: layered transformations, explicit business logic, data quality tests, and documentation — not a single monolithic query.

---

## Architecture

```
┌─────────────┐   ┌─────────────┐   ┌─────────────┐
│ Google Ads  │   │  Meta Ads   │   │    GA4      │
└──────┬──────┘   └──────┬──────┘   └──────┬──────┘
       │                 │                 │
       └────────┬────────┴────────┬────────┘
                │  Airbyte (scheduled sync)
                ▼
        ┌───────────────────┐
        │  BigQuery (raw)    │
        │  Google_Ads        │
        │  Meta_Ads          │
        │  Analytics_dump    │
        └─────────┬──────────┘
                  │  dbt
                  ▼
        ┌───────────────────┐
        │     staging/       │  1:1 cleanup, source() only
        └─────────┬──────────┘
                  ▼
        ┌───────────────────┐
        │   intermediate/    │  channel mapping, currency
        │                    │  conversion, union, join
        └─────────┬──────────┘
                  ▼
        ┌───────────────────┐
        │      marts/        │  dim_campaign_table
        │                    │  dim_date_table
        │                    │  fact_combinedtable_paid_ga4
        └─────────┬──────────┘
                  │
                  ▼
        ┌───────────────────┐
        │     Power BI        │
        │  Star schema model  │
        │  Executive dashboard│
        └───────────────────┘
```

---

## Data Sources

| Source | Data Captured | Grain |
|---|---|---|
| Google Ads | Campaign name, impressions, clicks, cost, revenue, orders | Date × Campaign |
| Meta Ads | Campaign name, impressions, clicks, cost, revenue, orders | Date × Campaign |
| GA4 | Source/medium, session campaign, sessions, orders, revenue, add-to-cart, checkout, view-item | Date × Campaign × Source/Medium |

---

## Ingestion Layer — Airbyte

Airbyte was chosen over the client's existing no-code tool for its ability to scale beyond one-off, manually configured connections as data volume and source count grow. Each source (Google Ads, Meta Ads, GA4) is a separate Airbyte connection, syncing into a dedicated BigQuery destination dataset on a scheduled basis.

**Setup included:**
- BigQuery service account provisioning, scoped to `BigQuery Data Editor` + `BigQuery Job User` (not broader `Owner`/`Editor` roles)
- Destination dataset creation and location alignment (`us-central1`) to avoid cross-region query issues
- Sync mode configuration (Full Refresh, with primary-key handling per stream)

---

## Warehouse — BigQuery

Raw data lands untouched in a dedicated dataset. A separate **personal development dataset** is used for dbt's dev environment, kept isolated from the raw ingestion dataset to avoid any risk of dbt writes affecting source data.

---

## Transformation Layer — dbt

The project follows a three-layer dbt architecture, each with a distinct responsibility:

### `staging/`
One model per raw source table. Each model does only light, mechanical cleanup — no business logic, no joins. This is the only layer permitted to use `source()`; every other layer uses `ref()`.

- `stg_google_ads.sql`
- `stg_meta_ads.sql`
- `stg_ga4.sql`

### `intermediate/`
Business logic lives here: channel classification (mapping raw source/medium values to `Google` / `Meta` / `Others`), currency conversion (USD → SAR), and combining sources.

- `int_google_ads_channel_currency.sql`
- `int_meta_ads_channel_currency.sql`
- `int_ga4_channel_currency.sql`
- `int_paid_channel_union.sql` — unions Google + Meta into one paid-channel table
- `int_paid_union_ga4.sql` — full outer join of paid data and GA4 data

### `marts/`
Final, BI-ready star schema.

- `dim_campaign_table.sql` — one row per unique campaign, with derived market, objective, funnel, category, campaign_type, and budget_type (see [Key Challenges](#key-challenges--decisions))
- `dim_date_table.sql` — generated calendar dimension, dynamically bounded from a fixed start date to one month past the latest fact data
- `fact_combinedtable_paid_ga4.sql` — the fact table; one row per date × campaign_channel_key, holding every performance measure

---

## Data Model

Star schema, connected in Power BI via relationships (not pre-joined in dbt):

```
              ┌────────────────────┐
              │  dim_campaign_table │
              │  campaign_channel_key (PK)
              │  campaign_name
              │  channel
              │  market / objective
              │  funnel / category
              │  campaign_type / budget_type
              └──────────┬─────────┘
                         │ 1
                         │
                         │ *
┌────────────────────────┴─────────────────────────┐
│         fact_combinedtable_paid_ga4                │
│  date, campaign_channel_key, channel               │
│  impressions, clicks, cost                         │
│  revenue_paid, orders_paid                         │
│  sessions, orders_ga4, revenue_ga4                 │
│  add_to_cart, begin_checkout, view_item            │
└────────────────────────┬─────────────────────────┘
                         │ *
                         │
                         │ 1
              ┌──────────┴─────────┐
              │   dim_date_table    │
              │  date (PK)          │
              │  year / quarter     │
              │  month / month_name │
              │  day / day_name     │
              │  weekend_days       │
              └────────────────────┘
```

Relationships: One-to-many, single cross-filter direction (dim → fact) on both sides — standard star-schema practice for predictable filter propagation.

---

## Testing

Every mart model has an associated `schema.yml` with column-level tests:

- **`unique` + `not_null`** on every primary/composite key (`campaign_channel_key`, `date`)
- **`accepted_values`** on categorical fields (`channel`, `objective`, `category`, `budget_type`, `funnel`) to catch unexpected values from upstream mapping logic
- **`not_null`** on every measure column, even where `COALESCE` is applied upstream — verifying the guarantee holds, rather than assuming it does

Run the full suite:
```
dbt test
```

---

## Documentation

Every model and column carries a `description:` in its `schema.yml`, generated into browsable docs via:
```
dbt docs generate
dbt docs serve
```

---

## Dashboard — Power BI

**Page 1 — Executive Overview**
- 8 scorecards: Clicks, Cost, Orders, Revenue, AOV, CPO, CVR, ROAS
- Period-over-period comparison measures (dynamic trailing-N-day, not fixed calendar month)
- Cost & Revenue trend over time
- ROAS / Revenue / Cost by Channel
- Revenue, Cost, ROAS by Market
- Conversion funnel (Sessions → Add to Cart → Checkout → Orders)
- Orders by Category

**Page 2 — Detailed Breakdown**
- Performance by Date
- Performance by Campaign (Campaign Type → Campaign Name)
- Performance by Channel

**Filters:** Campaign Type, Channel, Market, Objective — applied consistently across both pages.

---

## Key Challenges & Decisions

**1. Type coercion from Airbyte-ingested columns**
Numeric fields (revenue, cost, impressions, clicks, sessions) frequently arrived as STRING rather than a numeric type. Every aggregation required explicit `CAST(... AS FLOAT64)` before use — a pattern applied consistently once identified, rather than patched per-error.

**2. Many-to-many relationship in Power BI**
`dim_campaign_table` was built with `SELECT DISTINCT campaign_name, channel, ...`, which deduplicates on the full row combination — not on `campaign_name` alone. GA4 sessions with `NULL` or `(referral)` campaign names existed under both `Google` and `Meta` channels, meaning `campaign_name` alone was not unique. Resolved by introducing a composite `campaign_channel_key` (concatenation of campaign_name + channel), used as the relationship key instead.

**3. Case-sensitivity causing silent duplicate keys**
The same real campaign existed in the source data under two different casings (e.g. `Ramadan-Male` vs `ramadan-male`). Since `campaign_channel_key` was built from un-lowercased inputs at the aggregation (`GROUP BY`) stage, this fragmented both the fact table's numbers and the dimension table's uniqueness. Fixed by lowercasing `campaign_name` and `channel` at the earliest point they are read — before any `GROUP BY` — so every downstream layer inherits already-normalized values.

**4. NULL propagation in `CONCAT()`**
BigQuery's `CONCAT()` returns `NULL` if any argument is `NULL`, rather than treating `NULL` as an empty string. Every value fed into the composite key is wrapped in `COALESCE(..., '__NULL__')` to guarantee the key is always a real, comparable string.

**5. Campaign classification via regex, not a lookup table**
Market, campaign type, objective, category, budget type, and funnel are all derived from pattern-matching against `campaign_name` (per a mapping specification from the marketing team), using `REGEXP_CONTAINS`. Ambiguous or unmapped values default to `'Other'` rather than null, keeping every row classifiable.

**6. GA4 attribution gaps**
Some GA4 sessions carry a paid medium (e.g. `google / cpc`) but no resolvable campaign name (`NULL` or GA4's own placeholder values like `(referral)`). Rather than dropping this — which would silently remove real revenue and sessions — these are retained and explicitly labeled, preserving accurate totals while keeping the gap visible rather than hidden.

**7. Full outer join, deliberately**
Paid and GA4 data are combined via `FULL OUTER JOIN` with `COALESCE` fallbacks to zero, rather than a `LEFT JOIN`, so that neither paid-only nor GA4-only activity is silently excluded.

---

## Project Structure

```
models/
├── staging/
│   ├── sources.yml
│   ├── stg_google_ads.sql
│   ├── stg_meta_ads.sql
│   └── stg_ga4.sql
├── intermediate/
│   ├── int_google_ads_channel_currency.sql
│   ├── int_meta_ads_channel_currency.sql
│   ├── int_ga4_channel_currency.sql
│   ├── int_paid_channel_union.sql
│   ├── int_paid_union_ga4.sql
│   └── schema.yml
└── marts/
    ├── dim_campaign_table.sql
    ├── dim_date_table.sql
    ├── fact_combinedtable_paid_ga4.sql
    └── schema.yml
```


**Author:** Asim Iqbal
**GitHub:** [AsimIqbal0300](https://github.com/AsimIqbal0300)
