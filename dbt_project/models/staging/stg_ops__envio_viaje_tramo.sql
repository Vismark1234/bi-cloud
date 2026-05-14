select
  cast(id_envio_viaje_tramo as number(38,0)) as id_envio_viaje_tramo,
  cast(id_envio as number(38,0)) as id_envio,
  cast(id_viaje as number(38,0)) as id_viaje,
  cast(secuencia_tramo as number(18,0)) as secuencia_tramo,
  cast(id_sucursal_carga as number(38,0)) as id_sucursal_carga,
  cast(id_sucursal_descarga as number(38,0)) as id_sucursal_descarga,
  cast(fecha_hora_carga as timestamp_ntz) as fecha_hora_carga,
  cast(fecha_hora_descarga as timestamp_ntz) as fecha_hora_descarga,
  cast(peso_asignado_kg as number(18,2)) as peso_asignado_kg
from {{ source('ops', 'envio_viaje_tramo') }}
