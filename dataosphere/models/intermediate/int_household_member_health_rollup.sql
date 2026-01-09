{{config(materialized='view')}}

with grouped as (
    select
        household_id,
        submission_id,
        count(distinct member_index) as member_count,
        sum(cast(member_had_diarrhoea_14d as number(1,0))) as diarrhoea_case_count_14d,
        boolor_agg(member_has_diarrhoea_14d) as has_any_diarrhoea_14d_members,
    from
        {{ ref('stg_kobo_member') }}
    group by
        household_id, submission_id
), set_dq_flags as (
    select
        *,
        (NOT has_any_diarrhoea_14d_members) as has_no_diarrhoea_14d_members
        (member_count > 15) as dq_invalid_member_count,
        (
            diarrhoea_case_count_14d < 0
            or
            diarrhoea_case_count_14d > member_count
        ) as dq_invalid_diarrhoea_case_count,

        (
            (diarrhoea_case_count_14d  = 0 
            and
            has_no_diarrhoea_14d_members = false)
            or
            (
                diarrhoea_case_count_14d > 0
                and
                has_no_diarrhoea_14d_members = true 

            )
        ) as dq_diarrhoea_flag_inconsistent
    from    
        grouped
)
select * from set_dq_flags