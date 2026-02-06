{{
    config(
        materialized='incremental',
        incremental_strategy='append',
        schema='raw'
    )
}}

with source as (

    select 
        ext.household_id::string as household_id,
        ext.submission_id::string as submission_id,
        fla.value:member_index::number as member_index, 
        fla.value:member_name::string as member_name, 
        fla.value:sex::string as sex, 
        fla.value:age_years::number as age_years, 
        fla.value:had_diarrhoea_14d::boolean as had_diarrhoea_14d,
        fla.value:submission_id::string as fla_submission_id,
        fla.value:household_id::string as fla_household_id,

        {{
            generate_audit_cols(loaded_at_expr='ext._loaded_at', 
                                      batch_id_expr='ext._batch_id', 
                                      source_file_expr='ext._source_file', 
                                      is_deleted_expr='ext._is_deleted')
        }}    
    from
        {{ ref('ext_kobo_source_flattened')}} as ext,
    lateral
        flatten(
            input => ext.members,
            outer => true
        ) as fla

    {% if is_incremental() %}
        where {{ raw_incremental_load_filter() }}
    {% endif %}
)
select 
    *
from 
    source