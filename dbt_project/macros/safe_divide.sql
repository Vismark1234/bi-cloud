{% macro safe_divide(numerator, denominator, default_value=0) -%}
coalesce(({{ numerator }}) / nullif(({{ denominator }}), 0), {{ default_value }})
{%- endmacro %}
