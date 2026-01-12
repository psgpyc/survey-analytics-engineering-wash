# WASH Analytics Engineering (dbt + Snowflake)

Contract-first analytics engineering project for Kobo-style WASH survey data in Snowflake using dbt.

This repo demonstrates how to take **existing RAW tables in Snowflake** and build **join-safe, auditable, replayable** analytics models—starting with staging standardisation + data quality enforcement, moving through intermediate integration models, and producing BI-ready marts.

---

## What this repo shows

- **Contract-first sources** (`sources.yml`) with metadata + freshness expectations  
- **Staging models** (`stg_`) that:
  - cast to predictable data types (safe casting)
  - normalise categoricals (trim/lower + canonical sets)
  - dedupe to declared grains
  - generate data quality flags to support quarantine/replay
- **Data tests** with `store_failures` enabled for auditability
- **Rejected / quarantined patterns** to keep clean downstream marts while retaining bad records for triage and replay
- **A KPI-ready mart** for “safe drinking water” classification at household-event grain

---

## Architecture (high level)

`Snowflake RAW tables → dbt STAGING (stg_) → dbt INTERMEDIATE (int_) → dbt MARTS (dim_/fct_)`

Core principles:

- **Replayable modelling**: downstream models are derived and rebuildable  
- **Accountability**: failures are stored; rejected rows are inspectable  
- **Deterministic modelling**: typed + canonicalised staging reduces ambiguity  
- **Join-safe grains**: each model declares and enforces its grain via tests  

---

## Data domain

### RAW sources (Snowflake)
Kobo-style tables modelled as sources:

- `kobo_submission` — 1 row per submission  
- `kobo_household` — household section captured within a submission (event-scoped)  
- `kobo_member` — repeat-group members (composite grain)  
- `kobo_water_point` — water point observations (composite grain)  

> Note: household and member data are **event-scoped** (captured per submission). Households can appear across multiple submissions over time.

---

## dbt layers in this repo

### 1) Staging (`models/staging`)
Each staging model:

- casts to stable Snowflake types (safe casting where relevant)
- normalises strings (trim/lower)
- dedupes by declared grain using `record_loaded_at` ordering
- adds DQ flags to support quarantine/replay
- includes tests such as: `not_null`, `unique`, `relationships`, composite uniqueness, and expression checks

Main staging models:

- `stg_kobo_submission`
- `stg_kobo_household`
- `stg_kobo_member`
- `stg_kobo_water_point`

### 2) Intermediate (`models/intermediate`)
Intermediate models reshape staging outputs into analytical grains and rollups used by marts, for example:

- submission filters (e.g., submitted-only)
- household event tables (household + submission context)
- member health rollups at `household_id × submission_id`
- integration tables that feed downstream KPI facts

### 3) Marts (`models/marts`)
BI-ready facts/dimensions and KPI tables.

Current mart:

- `fact_household_wash_event` — household-event grain (`household_id × submission_id`) with safe drinking water flags and KPI classification

---

## KPI: “Safe drinking water” (high level)

Household-event is classified as safe when all hold:

- **safe primary water source** (canonical set)
- **safe water filter/treatment** (canonical set)
- **no diarrhoea in last 14 days** (member rollup; unknown treated as not-safe unless explicitly defined otherwise)

KPI logic is centralised using macros (safe lists) so definitions are explicit and version-controlled.

---

## How to run (local)

1) Install dbt packages
- `dbt deps`

2) Validate the project parses
- `dbt parse`

3) Build & test staging (recommended workflow)
- `dbt build --select tag:staging`

4) Run a single model
- `dbt run --select stg_kobo_submission`

5) Run tests for a model
- `dbt test --select stg_kobo_submission`

---

## Data quality strategy

- Source freshness checks ensure ingestion SLAs are met
- Contract tests ensure keys, relationships, and canonical values hold
- Store failures is enabled for audit tables, making bad records inspectable
- Rejected records can be routed to `__rejected` models for replay/triage

---

## Licence

MIT
