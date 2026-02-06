{% macro generate_audit_cols(loaded_at_expr='_loaded_at', 
                             batch_id_expr='_batch_id', 
                             source_file_expr='_source_file', 
                             is_deleted_expr='_is_deleted') %}

    try_to_timestamp_ntz({{ loaded_at_expr }}) as _loaded_at,
    {{ batch_id_expr }}::string as _batch_id,
    {{ source_file_expr }}::string as _source_file,
    try_to_boolean({{ is_deleted_expr }}) as _is_deleted
    
{% endmacro %}