{{
    config(
        materialized='incremental',
        incremental_strategy='append',
        schema='raw'
    )
}}

with source as (
    
    select  

        household_id::string as household_id,
        submission_id::string as submission_id,
        household_ward_id::number as ward_id,
        household_head_name::string as household_head_name,
        phone_last4::string as phone_last4,
        hh_size_reported::number as hh_size_reported,
        water_filter_type::string as water_filter_type,
        primary_water_source::string as primary_water_source,
        has_toilet::boolean as has_toilet,

        {{ generate_audit_cols() }}

    from
        {{ ref('ext_kobo_source_flattened') }}

    {% if is_incremental() %}

        where {{ raw_incremental_load_filter() }}

    {% endif %}
) 
select * from source