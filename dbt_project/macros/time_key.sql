{% macro time_key(expr) -%}
(date_part(hour, {{ expr }}) * 100) + date_part(minute, {{ expr }})
{%- endmacro %}
