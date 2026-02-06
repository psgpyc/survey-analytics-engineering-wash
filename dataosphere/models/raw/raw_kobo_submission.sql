{{
    config(
        materialized='incremental',
        incremental_strategy='append',
        schema='raw'
    )
}}

with source as (
    select 

        submission_id as submission_id,
        status as status, 
        -- temp, until upstream fixes it
        'wash_hh_v3'::string as form_id,
        '3'::number as form_version,

        try_to_timestamp_ntz(submitted_at) as submitted_at, 
        try_to_timestamp_ntz(collected_at) as collected_at,

        enumerator_id as enumerator_id, 
        device_id as device_id,
        ward_id as ward_id,
        municipality as municipality,
        district as district,
        gps_lat as gps_lat,
        gps_lon as gps_lon,
        consent as consent, 

        {{ generate_audit_cols() }}
        
    from 
        {{ ref('ext_kobo_source_flattened') }}

    {% if is_incremental() %}

        where {{ raw_incremental_load_filter() }}

    {% endif %}
)
select * from source