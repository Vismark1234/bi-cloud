select
  cast(id_gasto as number(38,0)) as id_gasto,
  cast(id_viaje as number(38,0)) as id_viaje,
  {{ clean_upper_text('tipo_gasto') }} as tipo_gasto,
  cast(monto_bob as number(18,4)) as monto_bob,
  cast(fecha_hora_gasto as timestamp_ntz) as fecha_hora_gasto
from {{ source('ops', 'viaje_gasto_operativo') }}
