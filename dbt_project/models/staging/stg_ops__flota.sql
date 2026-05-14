select
  cast(id_flota as number(38,0)) as id_flota,
  {{ clean_text('nombre') }} as nombre_flota,
  {{ clean_upper_text('tipo_servicio') }} as tipo_servicio,
  cast(id_sucursal_base as number(38,0)) as id_sucursal_base
from {{ source('ops', 'flota') }}
