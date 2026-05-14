select
  cast(id_entidad as number(38,0)) as id_entidad,
  {{ clean_upper_text('tipo_entidad') }} as tipo_entidad,
  {{ clean_text('nombre_o_razon_social') }} as nombre_razon_social,
  {{ clean_upper_text('tipo_documento') }} as tipo_documento,
  {{ clean_text('numero_documento') }} as numero_documento,
  {{ clean_text('ciudad') }} as ciudad,
  {{ clean_upper_text('estado') }} as estado_entidad
from {{ source('comercial', 'entidad') }}
