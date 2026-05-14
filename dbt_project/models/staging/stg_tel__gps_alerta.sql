select
  cast(_id as varchar) as id_alerta,
  cast(id_vehiculo_ops as number(38,0)) as id_vehiculo,
  cast(id_viaje_ops as number(38,0)) as id_viaje,
  cast(ts_alerta as timestamp_ntz) as ts_alerta,
  {{ clean_upper_text('tipo_alerta') }} as tipo_alerta,
  {{ clean_upper_text('nivel') }} as nivel_alerta,
  {{ clean_text('descripcion') }} as descripcion_alerta,
  coalesce(cast(atendida as number(1,0)), 0) as atendida_flag
from {{ source('tel', 'gps_alerta') }}
