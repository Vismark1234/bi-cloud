{% macro clean_upper_text(expr, default="'NO_DEFINIDO'") -%}
upper({{ clean_text(expr, default) }})
{%- endmacro %}
