
{% macro wash_safe_primary_sources() %}
    (
        'piped_to_dwelling',
        'piped_to_yard',
        'public_tap',
        'borehole',
        'protected_well',
        'protected_spring',
        'rainwater',
        'bottled'
    )
    
{% endmacro %}


{% macro wash_safe_water_filters() %}
   (
        'boil',
        'chlorine',
        'sodis',
        'ceramic',
        'biosand',
        'ro_uv',
        'candle'
    )
{% endmacro %}


