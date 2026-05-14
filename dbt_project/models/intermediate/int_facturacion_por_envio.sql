select
  id_envio,
  max(id_orden_servicio) as id_orden_servicio,
  sum(total_linea_bob) as monto_facturado_bob,
  count(*) as cantidad_lineas_facturadas
from {{ ref('int_facturacion_detalle_canonica') }}
where id_envio is not null
group by 1
