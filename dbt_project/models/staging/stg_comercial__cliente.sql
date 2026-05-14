select
  cast(id_cliente as number(38,0)) as id_cliente,
  cast(id_entidad as number(38,0)) as id_entidad,
  {{ clean_upper_text('segmento') }} as segmento,
  cast(fecha_alta as date) as fecha_alta
from {{ source('comercial', 'cliente') }}
