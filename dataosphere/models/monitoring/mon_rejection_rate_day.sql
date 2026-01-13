{{
    config(
        materialized='table',
        schema='monitoring'
    )
}}

with joined as (
    select 
        tot.base_model_name as model_name, 
        tot.event_date,
        tot.base_row_count, 
        coalesce(rej.rejected_row_count, 0) as rejected_row_count
    from
        {{ ref('mon_total_by_model_day') }} tot
    left join
        {{ ref('mon_rejections_by_model_day') }} rej
    on
        tot.base_model_name = rej.base_model_name
        and
        tot.event_date = rej.event_date
)
select
    *, 
    round(div0(rejected_row_count, base_row_count), 4) as rejection_rate
from
    joined
