{% macro clean_text(expr, default="'NO_DEFINIDO'") -%}
coalesce(nullif(trim(cast({{ expr }} as varchar)), ''), {{ default }})
{%- endmacro %}

