select
  cast(id_viaje as number(38,0)) as id_viaje,
  cast(id_ruta as number(38,0)) as id_ruta,
  cast(id_vehiculo as number(38,0)) as id_vehiculo,
  cast(id_conductor as number(38,0)) as id_conductor,
  cast(fecha_salida_real as timestamp_ntz) as fecha_salida_real,
  cast(fecha_llegada_real as timestamp_ntz) as fecha_llegada_real,
  {{ clean_upper_text('estado_viaje') }} as estado_viaje
from {{ source('ops', 'viaje') }}
