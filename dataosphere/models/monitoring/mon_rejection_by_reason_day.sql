{{
  config(
    materialized='table',
    schema='monitoring'
  )
}}

with rejected_rows as (

    select
        '{{ ref('stg_kobo_submission__rejected').identifier }}' as model_name,
        cast(split('{{ ref('stg_kobo_submission__rejected').identifier }}', '__')[0] as string) as base_model_name,
        to_date(record_loaded_at) as event_date,

        case
            when dq_missing_submission_id then 'missing_keys'

            when dq_submitted_missing_submitted_at then 'invalid_required_field'

            when dq_invalid_gps then 'invalid_range'

            when is_deleted then 'soft_deleted'

            else 'other'

        end as reason_bucket

    from {{ ref('stg_kobo_submission__rejected') }}


    union all

    select
        '{{ ref('stg_kobo_household__rejected').identifier }}' as model_name,
        cast(split('{{ ref('stg_kobo_household__rejected').identifier }}', '__')[0] as string) as base_model_name,
        to_date(record_loaded_at) as event_date,

        case
            when dq_missing_blank_household_id or dq_missing_blank_submission_id then 'missing_keys'

            when dq_orphan_submission_id then 'orphan_fk'

            when dq_invalid_water_filter_type or dq_invalid_primary_water_source then 'invalid_canonical'

            when dq_invalid_hh_size then 'invalid_range'

            when dq_unknown_other_filter_type or dq_unknown_other_primary_water_source then 'unknown_other'

            when is_deleted then 'soft_deleted'

            else 'other'

        end as reason_bucket

    from {{ ref('stg_kobo_household__rejected') }}


    union all


    select
        '{{ ref('stg_kobo_member__rejected').identifier }}' as model_name,
        cast(split('{{ ref('stg_kobo_member__rejected').identifier }}', '__')[0] as string) as base_model_name,
        to_date(record_loaded_at) as event_date,

        case
            when dq_missing_household_id or dq_missing_submission_id or dq_missing_member_index then 'missing_keys'

            when dq_orphan_household_id or dq_orphan_submission_id then 'orphan_fk'

            when dq_invalid_member_sex then 'invalid_canonical'

            when dq_invalid_age_in_years then 'invalid_range'

            when dq_blank_member_name  then 'unknown_other'  

            when is_deleted then 'soft_deleted'

            else 'other'

        end as reason_bucket

    from {{ ref('stg_kobo_member__rejected') }}


    union all

    select
        '{{ ref('stg_kobo_water_point__rejected').identifier }}' as model_name,
        cast(split('{{ ref('stg_kobo_water_point__rejected').identifier}}', '__')[0] as string) as base_model_name,
        to_date(record_loaded_at) as event_date,

        case
            when dq_missing_blank_water_point_id or dq_missing_blank_submission_id then 'missing_keys'

            when dq_orphan_submission_id then 'orphan_fk'

            when dq_missing_blank_source_type then 'invalid_canonical'

            when dq_negative_distance_minutes then 'invalid_range'

            when is_deleted then 'soft_deleted'

            else 'other'

        end as reason_bucket

    from {{ ref('stg_kobo_water_point__rejected') }}

),

final as (
    select
        base_model_name,
        event_date,
        reason_bucket,
        count(*) as rejected_rows
    from rejected_rows
    group by base_model_name, event_date, reason_bucket
)

select * from final
