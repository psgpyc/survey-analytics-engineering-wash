{{
    config(
        materialized='table',
        schema='monitoring'
    )
}}

with unioned as (

    select
        '{{ ref('stg_kobo_submission__base').identifier}}' as model_name,
        to_date(record_loaded_at) as event_date,
        count(*) as base_row_count
    from
        {{ref('stg_kobo_submission__base')}}
    group by 1,2

    union all

    select
        '{{ ref('stg_kobo_household__base').identifier}}' as model_name,
        to_date(record_loaded_at) as event_date,
        count(*) as base_row_count
    from
        {{ref('stg_kobo_household__base')}}
    group by 1,2

    union all

    select
        '{{ ref('stg_kobo_member__base').identifier}}' as model_name,
        to_date(record_loaded_at) as event_date,
        count(*) as base_row_count
    from
        {{ref('stg_kobo_member__base')}}
    group by 1,2

    union all

    select
        '{{ ref('stg_kobo_water_point__base').identifier}}' as model_name,
        to_date(record_loaded_at) as event_date,
        count(*) as base_row_count
    from
        {{ref('stg_kobo_water_point__base')}}
    group by 1,2

)
select 
    *,
    cast(split(model_name, '__')[0] as string) as base_model_name

from 
    unioned