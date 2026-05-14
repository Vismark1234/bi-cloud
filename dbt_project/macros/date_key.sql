{% macro date_key(expr) -%}
to_number(to_char(cast({{ expr }} as date), 'YYYYMMDD'))
{%- endmacro %}
