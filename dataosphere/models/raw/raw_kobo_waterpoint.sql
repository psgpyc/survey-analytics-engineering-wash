{{
    config(
        materialized='incremental',
        incremental_strategy='append',
        schema='raw'
    )
}}

with source as (
    select  
        submission_id::string as submission_id,
        water_point:water_point_id::string as water_point_id,
        water_point:ward_id::number as ward_id,
        water_point:source_type::string as source_type, 
        water_point:functional::boolean as functional, 
        water_point:distance_minutes::number as distance_minutes,
        water_point:gps_lat::double as gps_lat,
        water_point:gps_lon::double as gps_lon,
        water_point:submission_id::string as fla_submission_id,
        {{
            generate_audit_cols()
        }}    
    from    
        {{ ref('ext_kobo_source_flattened') }} 

    {% if is_incremental() %}
        where {{ raw_incremental_load_filter() }}
    {% endif %}
)
select 
    * 
from 
    source