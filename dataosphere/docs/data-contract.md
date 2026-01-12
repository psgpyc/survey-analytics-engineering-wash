## Overview

This document defines the canonical value sets and KPI-building rules used throughout the WASH analytics models. The goal is to ensure that:
- categorical values are consistent across forms and tables
- indicators are deterministic and auditable
- changes to definitions are explicit and version-controlled

---

## Canonical sets (categorical fields)

### 1) Household `water_filter_type` (canonical)
Used in: `stg_kobo_household.water_filter_type`

Canonical values:
- `none`
- `boil`
- `candle`
- `chlorine`
- `sodis`
- `ceramic`
- `biosand`
- `cloth`
- `ro_uv`
- `other`
- `unknown`

Notes:
- This is a normalised reporting set. If Kobo collects more granular variants, they should be mapped into these categories upstream (staging standardisation) or in a dedicated mapping layer.
- `other` and `unknown` are valid categories but are **not safe** for KPI purposes unless explicitly reclassified in a documented mapping rule.

---

### 2) Household `primary_water_source` (canonical)
Used in: `stg_kobo_household.primary_water_source`

Canonical values (cleaned; no duplicates):
- `piped_to_dwelling`
- `piped_to_yard_plot`
- `public_tap_standpipe`
- `tubewell_borehole`
- `protected_dug_well`
- `unprotected_dug_well`
- `protected_spring`
- `unprotected_spring`
- `rainwater`
- `tanker_truck_cart`
- `bottled_water`
- `surface_water`
- `other`
- `unknown`

Notes:
- We do **not** use ambiguous categories like `spring` or `tapstand` alongside `protected_spring/unprotected_spring` and `public_tap_standpipe`. If those appear upstream, they must be mapped to canonical values.

---

### 3) Water point `source_type` (canonical)
Used in: `stg_kobo_water_point.source_type`

Canonical values (aligned to household `primary_water_source`):
- `piped_to_dwelling`
- `piped_to_yard_plot`
- `public_tap_standpipe`
- `tubewell_borehole`
- `protected_dug_well`
- `unprotected_dug_well`
- `protected_spring`
- `unprotected_spring`
- `rainwater`
- `tanker_truck_cart`
- `bottled_water`
- `surface_water`
- `other`
- `unknown`

Notes:
- The water point classification uses the same canonical categories as household reporting to support consistent aggregation and comparison.

---

### 4) Member sex (canonical)
Used in: `stg_kobo_member.member_sex`

Canonical values:
- `m`
- `f`
- `male`
- `female`
- `other`
- `unknown`

---

### 5) Member diarrhoea (tri-state canonical)
Used in: `stg_kobo_member.member_had_diarrhoea_14d`

Canonical values (tri-state):
- `yes`
- `no`
- `unknown`

Notes:
- `unknown` means the response was missing, invalid, unparseable, or otherwise not confidently classified.
- KPI logic must **not** treat `unknown` as `no`.

---

## Safe drinking water definitions (KPI contract)

### KPI goal
Measure the number (and % where denominator is available) of households with “safe drinking water” by ward and period.

### KPI grain
All household KPI classification is performed at grain:
- `household_id × submission_id` (household survey event)

---

## Safe drinking water (household-level) definition

A household survey event is classified as safe if **ALL** conditions hold:

### 1) Safe primary water source
- `has_safe_primary_source = primary_water_source IN SAFE_PRIMARY_WATER_SOURCES`

### 2) Safe water treatment / filter
- `has_safe_water_filter = water_filter_type IN SAFE_WATER_FILTER_TYPES`

### 3) No diarrhoea in last 14 days (strict tri-state rule)
Derived from member roster records at grain `household_id × submission_id`:

Let:
- `member_count = count(distinct member_index)` (or an equivalent stable member grain)
- `total_diarrhoea_case_count_14d = sum(member_had_diarrhoea_14d = 'yes')`
- `total_no_diarrhoea_count_14d = sum(member_had_diarrhoea_14d = 'no')`
- `total_unknown_diarrhoea_count_14d = sum(member_had_diarrhoea_14d = 'unknown')`

Then:
- `has_no_diarrhoea_14d_members = (
    total_diarrhoea_case_count_14d = 0
    AND total_unknown_diarrhoea_count_14d = 0
    AND total_no_diarrhoea_count_14d = member_count
  )`

Interpretation:
- If **any** member is `unknown`, the household cannot be asserted as “no diarrhoea”.
- If `member_count = 0`, the household cannot be asserted as “no diarrhoea” for KPI purposes.

### Final KPI flag
- `is_safe_drinking = has_safe_primary_source AND has_safe_water_filter AND has_no_diarrhoea_14d_members`

---

## Reporting period (time basis)

The period is defined from a single, explicit timestamp to ensure consistent aggregation across models and dashboards.

- **Event timestamp:** `submitted_at` (from submission context).
  - Represents when the form was submitted on the device (closest to “when the survey event happened”).
  - Preferred over ingestion time.
- **Event date:** `event_date = DATE(submitted_at)`
- **Reporting period grain (default):** daily (`ward_id × event_date`)
- **Timezone rule:** treat timestamps as UTC (or explicitly convert to UTC before deriving `event_date`).
- **Eligibility rule:** if `submitted_at` is null, the record is **not eligible** for period-based KPI reporting unless explicitly handled (e.g., quarantine or separate “unknown date” bucket).

---

## Safe lists used by the KPI

### SAFE_PRIMARY_WATER_SOURCES (household-level)
Default “safe” set for reporting in this project:
- `piped_to_dwelling`
- `piped_to_yard_plot`
- `public_tap_standpipe`
- `tubewell_borehole`
- `protected_dug_well`
- `protected_spring`
- `rainwater`
- `bottled_water`

Notes:
- This list is a project-level definition. If stakeholders change the definition, update here first and version-control the change.

---

### SAFE_WATER_FILTER_TYPES (household-level)
Default “safe” set for reporting in this project:
- `boil`
- `chlorine`
- `sodis`
- `ceramic`
- `biosand`
- `ro_uv`

Notes:
- `candle` is excluded by default (effectiveness varies by product/maintenance). Include only if stakeholders explicitly accept it as safe.
- `cloth` is excluded (generally not sufficient).
- `none`, `other`, `unknown` are not safe.

---

## Diarrhoea rollup contract (member → household × submission)

### Field used
- `stg_kobo_member.member_had_diarrhoea_14d` (tri-state: `yes` / `no` / `unknown`)

### Rollup outputs (required)
At grain `household_id × submission_id`:
- `member_count`
- `total_diarrhoea_case_count_14d`
- `total_no_diarrhoea_count_14d`
- `total_unknown_diarrhoea_count_14d`
- `has_no_diarrhoea_14d_members`

### Consistency rule (must hold)
- `member_count = total_diarrhoea_case_count_14d + total_no_diarrhoea_count_14d + total_unknown_diarrhoea_count_14d`

### Missing member data handling (strict)
- If member records are missing for a `household_id × submission_id`, do not infer “no diarrhoea”.
- KPI-safe classification requires:
  - `member_count > 0`
  - `total_unknown_diarrhoea_count_14d = 0`
  - `total_diarrhoea_case_count_14d = 0`
  - `total_no_diarrhoea_count_14d = member_count`

