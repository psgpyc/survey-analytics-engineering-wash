{{
    config(
        materialized='view',
        schema='intermediate'
    )

}}

with grouped as (
    select
        household_id,
        submission_id,
        count(distinct member_index) as member_count,
        SUM(
            cast(member_had_diarrhoea_14d = 'yes' as number(1,0))
        ) as total_diarrhoea_case_count_14d,
        SUM(
            cast(member_had_diarrhoea_14d = 'no' as number(1,0))
        ) as total_no_diarrhoea_count_14d,
        SUM(
            cast(member_had_diarrhoea_14d = 'unknown' as number(1,0))
        ) as total_unknown_diarrhoea_count_14d
    from
        {{ ref('stg_kobo_member') }}
    group by
        household_id, submission_id

), add_recorded_count as (
    select
        *,
        (
            total_diarrhoea_case_count_14d 
            + total_no_diarrhoea_count_14d 
            + total_unknown_diarrhoea_count_14d
        ) as total_recorded_cases
    from
        grouped

), set_dq_flags as (
    select
        *,
        (member_count > 15) as dq_invalid_member_count,
        (total_recorded_cases > member_count) as dq_invalid_diarrhoea_case_count,
        (
            total_diarrhoea_case_count_14d = 0
            and
            total_unknown_diarrhoea_count_14d = 0
            and
            (total_no_diarrhoea_count_14d > 0 and total_no_diarrhoea_count_14d = member_count)
    
        ) as has_no_diarrhoea_14d_members
    from    
        add_recorded_count
)
select * from set_dq_flags