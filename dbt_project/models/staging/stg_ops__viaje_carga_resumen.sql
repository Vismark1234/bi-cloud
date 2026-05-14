select
  cast(id_viaje as number(38,0)) as id_viaje,
  cast(capacidad_kg as number(18,2)) as capacidad_kg,
  cast(peso_asignado_kg as number(18,2)) as peso_asignado_kg,
  cast(capacidad_disponible_kg as number(18,2)) as capacidad_disponible_kg,
  cast(sobrecapacidad_flag as number(1,0)) as sobrecapacidad_flag
from {{ source('ops', 'viaje_carga_resumen') }}
