select
  cast(id_orden_servicio as number(38,0)) as id_orden_servicio,
  cast(id_cliente as number(38,0)) as id_cliente,
  cast(id_contrato as number(38,0)) as id_contrato,
  cast(id_tarifa_detalle as number(38,0)) as id_tarifa_detalle,
  coalesce(cast(total_bob as number(18,4)), 0) as total_bob,
  cast(id_reserva_credito as number(38,0)) as id_reserva_credito,
  {{ clean_upper_text('estado') }} as estado_orden,
  cast(fecha_creacion as timestamp_ntz) as fecha_creacion,
  cast(vigencia_hasta as timestamp_ntz) as vigencia_hasta
from {{ source('comercial', 'orden_servicio') }}
