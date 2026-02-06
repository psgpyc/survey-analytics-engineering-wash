{{ config(materialized='view') }}

with source as (
    select
        l.payload:submissions as submissions
    from {{ source('raw', 'landing') }} as l
),
flattened as (
    
    select
        -- submission metadata
        f.value:submission_id::string              as submission_id,
        f.value:submitted_at::string                as submitted_at,
        f.value:status::string                     as status,
        f.value:collected_at::string                as collected_at,
        f.value:enumerator_id::string              as enumerator_id,
        f.value:device_id::string                  as device_id,
        f.value:ward_id::number                    as ward_id,
        f.value:municipality::string               as municipality,
        f.value:district::string                   as district,
        f.value:gps_lat::float                     as gps_lat,
        f.value:gps_lon::float                     as gps_lon,
        f.value:consent::boolean                   as consent,

        -- household
        f.value:household:household_id::string           as household_id,
        f.value:household:ward_id::number                as household_ward_id,
        f.value:household:household_head_name::string    as household_head_name,
        f.value:household:phone_last4::string            as phone_last4,
        f.value:household:hh_size_reported::number       as hh_size_reported,
        f.value:household:water_filter_type::string      as water_filter_type,
        f.value:household:primary_water_source::string   as primary_water_source,
        f.value:household:has_toilet::boolean            as has_toilet,

        -- nested blobs
        f.value:household:members                        as members,
        f.value:water_point                              as water_point,

        -- audit cols
        f.value:_batch_id::string               as _batch_id,
        f.value:_is_deleted::boolean            as _is_deleted,
        f.value:_loaded_at::string              as _loaded_at,
        f.value:_source_file::string            as _source_file

    from source as s,
    lateral flatten(
        input => s.submissions,
        outer => true
    ) as f
)
select * from flattened