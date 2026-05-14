select
  cast(id_ruta as number(38,0)) as id_ruta,
  {{ clean_text('codigo_ruta') }} as codigo_ruta,
  cast(id_origen_sucursal as number(38,0)) as id_sucursal_origen,
  cast(id_destino_sucursal as number(38,0)) as id_sucursal_destino,
  cast(distancia_km as number(18,2)) as distancia_km
from {{ source('ops', 'ruta') }}
