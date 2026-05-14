select
  id_factura_detalle,
  id_factura,
  id_cliente,
  id_orden_servicio,
  id_envio,
  id_ruta,
  {{ date_key('fecha_emision') }} as id_fecha_emision,
  {{ date_key('fecha_vencimiento') }} as id_fecha_vencimiento,
  1 as cantidad_lineas,
  coalesce(cantidad, 0) as cantidad,
  coalesce(precio_unitario_bob, 0) as precio_unitario_bob,
  coalesce(total_linea_bob, 0) as total_linea_bob
from {{ ref('int_facturacion_base') }}
