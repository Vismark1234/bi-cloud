select
  cast(_id as varchar) as id_track,
  cast(id_vehiculo_ops as number(38,0)) as id_vehiculo,
  cast(id_viaje_ops as number(38,0)) as id_viaje,
  cast(id_conductor_ops as number(38,0)) as id_conductor,
  cast(ts as timestamp_ntz) as ts_track,
  cast(vel_kmh as number(18,4)) as velocidad_kmh,
  cast(temp_motor_c as number(18,4)) as temp_motor_c,
  cast(combustible_pct as number(18,4)) as combustible_pct,
  {{ clean_upper_text('evento') }} as evento_track
from {{ source('tel', 'gps_track') }}
