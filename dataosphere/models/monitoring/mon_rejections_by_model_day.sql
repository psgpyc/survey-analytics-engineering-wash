{{
    config(
        materialized='table',
        schema='monitoring'
    )
}}

with unioned as (

    select
        '{{ ref('stg_kobo_submission__rejected').identifier}}' as model_name,
        to_date(record_loaded_at) as event_date,
        count(*) as rejected_row_count
    from
        {{ref('stg_kobo_submission__rejected')}}
    group by 1,2

    union all

    select
        '{{ ref('stg_kobo_household__rejected').identifier}}' as model_name,
        to_date(record_loaded_at) as event_date,
        count(*) as rejected_row_count
    from
        {{ref('stg_kobo_household__rejected')}}
    group by 1,2

    union all

    select
        '{{ ref('stg_kobo_member__rejected').identifier}}' as model_name,
        to_date(record_loaded_at) as event_date,
        count(*) as rejected_row_count
    from
        {{ref('stg_kobo_member__rejected')}}
    group by 1,2

    union all

    select
        '{{ ref('stg_kobo_water_point__rejected').identifier}}' as model_name,
        to_date(record_loaded_at) as event_date,
        count(*) as rejected_row_count
    from
        {{ref('stg_kobo_water_point__rejected')}}
    group by 1,2

)
select 
    *,
    cast(split(model_name, '__')[0] as string) as base_model_name
from 
    unioned