{{
    config(
        materialized='view',
        schema='intermediate'
    )
}}

with source as (
    select
        *
    from
        {{ref('stg_kobo_submission')}}
    where
        status = 'submitted' 
)
select * from source

