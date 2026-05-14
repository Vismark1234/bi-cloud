select
  cast(id_factura_detalle as number(38,0)) as id_factura_detalle,
  cast(id_factura as number(38,0)) as id_factura,
  cast(id_envio_ops as number(38,0)) as id_envio,
  cast(id_orden_servicio as number(38,0)) as id_orden_servicio,
  cast(cantidad as number(18,2)) as cantidad,
  cast(precio_unitario_bob as number(18,4)) as precio_unitario_bob,
  cast(total_linea_bob as number(18,4)) as total_linea_bob
from {{ source('fin', 'factura_detalle') }}
