# WASH: Analytics Engineering Project 

Contract-first analytics engineering project modelling Kobo-style WASH survey data in **Snowflake** using **dbt**.

This repo is intentionally “production-shaped”: it assumes the RAW tables already exist in Snowflake, and focuses on what an analytics engineer does next — standardise, validate, quarantine, integrate, publish marts, and monitor.

-- 

A programme team running a Kobo-based WASH survey already had RAW tables landing in Snowflake, but they needed reporting that was consistent and explainable day to day. The ask was straightforward: take what is arriving in RAW and turn it into something they can safely use for routine monitoring and decision-making.

They wanted one primary KPI they could trust and trend daily:

> [!IMPORTANT]
> Primary KPI: Safe drinking water by ward and day.

They also wanted to answer practical questions when the numbers moved:
- What changed since the last survey round, and which wards are driving it?
- What kinds of issues are showing up most often in the field data (missing keys, invalid categoricals, orphan relationships, out-of-range values)?
- How frequently are default or placeholder values being used for required fields, and is that concentrated in specific wards or teams?
- Are health outcomes being recorded as “unknown” more often in certain wards or by certain enumerators, making those slices less reliable for reporting?

## Workflow

I treated this as an analytics engineering problem. The goal was to make the KPI deterministic, auditable, and resilient to messy, event-scoped survey data.


Here is the approach I followed:

1) **Stakeholder Alignment**
   - Confirm what “safe drinking water” means in their programme context (safe source, safe filter/treatment).
   - Agree how to treat “unknown” values, especially for health outcomes.
   - Agree the reporting time basis that we can guarantee consistently in the warehouse.
   - Agree what should be excluded from downstream reporting.

2) **Data definition**
   - Fix the KPI grain.
   - Define which slicers must work everywhere and what “eligible” means for counting.
   - Write the KPI logic in a way that is deterministic and doesn’t rely on BI tool calculations.

3) **Data contracts**
   - Document canonical value sets, values allowed downstream.
   - Document the “safe lists” that define the KPI.
   - Document the rollup rules, including strict tri-state handling (`unknown` is not treated as `no`).
   - Put all of this in `docs/data-contract.md` so changes are intentional and reviewable.

4) **Build the dbt layers with guardrails**
   - **Staging (`stg_`)** standardises types and categoricals, enforces grains, and generates DQ flags.
   - **Quarantine (`__rejected`)** keeps bad rows visible and replayable without letting them pollute marts.
   - **Intermediate (`int_`)** produces join-safe integration models and rollups at stable grains.
   - **Marts (`fact_` / `dim_`)** publish KPI-ready outputs so downstream dashboards stay simple and consistent.

```
┌────────────────────────────────────────────────────────────────────────┐
│   RAW (Snowflake)                                                      │
│        │                                                               │
│        v                                                               │
│   STAGING (stg_*)                                                      │
│   - safe casting + trimming/lower                                      │
│   - canonicalisation (value sets)                                      │
│   - dedupe to declared grains (record_loaded_at + tie-break)           │
│   - DQ flags                                                           │
│        │                                                               │
│        ├──────────────>  __rejected / quarantine                       │
│        │                 - bad rows retained. Inspectable & replayable │
│        │                 - reason buckets derived with precedence      │
│        │                                                               │
│        v                                                               │
│   INTERMEDIATE (int_*)                                                 │
│   - join-safe integration models                                       │
│   - stable grains for downstream marts (household_id × submission_id)  │
│        │                                                               │
│        ├──────────────>  int_household_current_source                  │
│        │                 - 1 row per household_id                      │
│        │                                                               │
│        v                                                               │                     
|   SNAPSHOTS (snap_*)  [SCD2]                                           │                     
│   - snap_dim_household_current                                         │                      
│   - tracks household attribute history                                 │
│        │                                                               │                      
│        ├──────────────>  Point-in-time join models                     │                      
│        │                                                               │                      
│        │                                                               │                      
│        v                                                               │                      │                                                                        │                      
│   MARTS (fact_* / dim_*)                                               │                      
│   - fact_household_wash_event (event grain, KPI flags)                 │                      
│   - aggregates (ward/day KPI rollups)                                  │                      
│   - dim_household_current                                              │
│                                                                        │                      
└────────────────────────────────────────────────────────────────────────┘
                                    │
                                    v
  ┌────────────────────────────────────────────────────────────────────┐
  │ Monitoring                                                         │
  │  - totals, rejections, rejection rate                              │
  │  - rejection by reason bucket                                      │
  │  - unknown rates by ward/day                                       │
  └───────────────-────────────────────────────────────────────────────┘

```

The result is a KPI that is repeatable, auditable, and explainable: the definition is written down, enforced with tests, and supported by monitoring outputs so stakeholders can understand changes instead of guessing.


## The data domain

The RAW tables represent a Kobo-style form structure:

- `kobo_submission`  
  - grain: 1 row per `submission_id`
  - includes submission status, ward_id, location fields, timestamps, lineage

- `kobo_household`  
  - household section captured inside a submission (event-scoped)
  - households can appear in multiple submissions over time

- `kobo_member`  
  - repeat group for household members
  - grain is composite: `(household_id, submission_id, member_index)`

- `kobo_water_point`  
  - observations of water points
  - grain is composite: `(water_point_id, submission_id)` (depending on form design)

<img width="1313" height="641" alt="image" src="https://github.com/user-attachments/assets/7fe9e779-52ac-4f1c-b3e0-fd6988059e9a" />

---

## Repository structure

```
dataosphere/
  models/
    staging/           # stg_ models + __base and __rejected patterns
    intermediate/      # int_ integration and rollups
    marts/
      facts/           # KPI facts and aggregates
      dimentions/      # dimensions (current)
    monitoring/        # mon_ operational monitoring outputs
  snapshots/           # SCD2 snapshots (dbt snapshots)
  docs/
    data-contract.md
    monitoring-contract.md
```

## Key contracts

### Canonical value sets (enforced downstream)

- `stg_kobo_household.water_filter_type`
  - `none`, `boil`, `candle`, `chlorine`, `sodis`, `ceramic`, `biosand`, `cloth`, `ro_uv`, `other`, `unknown`

- `stg_kobo_household.primary_water_source` and `stg_kobo_water_point.source_type`
  - `piped_to_dwelling`, `piped_to_yard_plot`, `public_tap_standpipe`, `tubewell_borehole`,
    `protected_dug_well`, `unprotected_dug_well`, `protected_spring`, `unprotected_spring`,
    `rainwater`, `tanker_truck_cart`, `bottled_water`, `surface_water`, `other`, `unknown`

- `stg_kobo_member.member_sex`
  - `m`, `f`, `male`, `female`, `other`, `unknown`

- `stg_kobo_member.member_had_diarrhoea_14d` (tri-state)
  - `yes`, `no`, `unknown`
  - unknown is **not** treated as no (strict rule)

### Time basis

For this project’s reporting and monitoring:
- event timestamp: `record_loaded_at`
- event date: `event_date = DATE(record_loaded_at)`
- default reporting grain: `ward_id × event_date`
- timezone: treat as UTC (or convert before deriving date)


## KPI: Safe drinking water (household-event)

### KPI grain
- `household_id × submission_id`

### Input rules (safe lists)
Safe lists are version-controlled in macros:
- SAFE_PRIMARY_WATER_SOURCES
- SAFE_WATER_FILTER_TYPES

### Strict diarrhoea rule (tri-state)
At `household_id × submission_id`, compute:
- `member_count`
- `total_diarrhoea_yes_14d`
- `total_diarrhoea_no_14d`
- `total_diarrhoea_unknown_14d`

Consistency must hold:
- `member_count = yes + no + unknown`

Household is “no diarrhoea” only when:
- `member_count > 0`
- `yes = 0`
- `unknown = 0`
- `no = member_count`

Final KPI:
- `is_safe_drinking = safe_source AND safe_filter AND no_diarrhoea`


## Published marts

### `fact_household_wash_event`
Purpose:
- KPI-ready household-event table for safe drinking water reporting.

Grain:
- `household_id × submission_id`

Guaranteed slicers:
- `ward_id`
- `event_date`

Eligibility:
- `member_count >= 1`

Contract invariant (enforced by tests):
- `is_safe_drinking = has_safe_primary_source AND has_safe_water_filter AND has_no_diarrhoea_14d_members`


### `fact_agg_safe_drinking_ward_day`
Purpose:
- daily ward-level aggregate so BI tools don’t have to rebuild KPI logic.

Grain:
- `ward_id × event_date`

Must always be true:
- `household_events_safe <= household_events_total`
- `pct_safe between 0 and 1`


### `dim_household_current`
Purpose:
- current household attributes (latest known values), built as a “current view” of event-scoped household captures.

Grain:
- `household_id`

Usage note:
- joining event facts to current dim answers **current state** questions  
- it does not represent historical attribute values at the time of each event unless you do a point-in-time join via the snapshot table


## Snapshots (SCD2 household history)

This repo includes a dbt snapshot to track household attribute changes over time.

### What it’s for
- keep history of attribute changes (filter type, source type, toilet status, reported size, and location fields)
- enable point-in-time analysis when needed

Operationally:
- new RAW arrives
- you run dbt models (stg/int/marts)
- you run `dbt snapshot`
- snapshot compares current source rows and inserts new SCD2 versions when changes occur

---

## Monitoring and triage

Monitoring models are intentionally small, simple, and sliceable.

### What exists

- `mon_total_by_model_day`
  - daily base row counts
  - grain: `base_model_name × event_date`

- `mon_rejections_by_model_day`
  - daily rejected row counts
  - grain: `base_model_name × event_date`

- `mon_rejection_rate_day`
  - rejection rate derived from totals + rejections
  - grain: `base_model_name × event_date`

- `mon_rejection_by_reason_day`
  - “why” slicer for rejected rows
  - grain: `base_model_name × event_date × reason_bucket`
  - standard buckets: `missing_keys`, `orphan_fk`, `invalid_required_field`, `invalid_canonical`, `invalid_range`, `unknown_other`, `soft_deleted`, `other`

- `mon_unknown_diarrhoea_rate_ward_day`
  - tracks diarrhoea completeness issues by ward/day
  - grain: `ward_id × event_date`

---

## How to run

Install packages:
```bash
dbt deps
```

Parse (fast sanity check):
```bash
dbt parse
```

Build + test staging first:
```bash
dbt build --select tag:staging
```

Build everything:
```bash
dbt build
```

Run snapshots:
```bash
dbt snapshot
```

Run only monitoring:
```bash
dbt build --select tag:monitoring
```

---

## How to review changes

This repo is designed to make changes reviewable:

- KPI definitions live in:
  - `docs/data-contract.md`
  - macros for safe lists
  - dbt tests that lock invariants

---

### CI on pull requests 
- On every PR to `master`, CI runs:
  - `dbt deps`
  - `dbt debug`
  - `dbt build` for selected layers (staging / intermediate / marts / monitoring)
- CI writes to an isolated Snowflake schema per PR:
  - `DBT_CI_PR_<pr_number>`
- CI uses an env-var driven dbt profile stored in `dataosphere/ci/` .

### Docs published to GitHub Pages
- On every push to `master`, the workflow generates dbt docs and publishes them to GitHub Pages.
- This keeps documentation always up to date with the latest merged definitions (models, tests, exposures, contracts).


## Licence

MIT
