with rutas_tarifa as (
  select
    t.id_tarifa_detalle,
    r.id_ruta
  from {{ ref('int_tarifa_base') }} t
  left join {{ ref('int_ruta_base') }} r
    on t.id_sucursal_origen_ref = r.id_sucursal_origen
   and t.id_sucursal_destino_ref = r.id_sucursal_destino
  qualify row_number() over (
    partition by t.id_tarifa_detalle
    order by r.id_ruta
  ) = 1
)
select
  fd.id_factura_detalle,
  fd.id_factura,
  coalesce(f.id_cliente, os.id_cliente) as id_cliente,
  fd.id_orden_servicio,
  fd.id_envio,
  coalesce(en.id_ruta_referencia, rt.id_ruta) as id_ruta,
  f.fecha_emision,
  f.fecha_vencimiento,
  fd.cantidad,
  fd.precio_unitario_bob,
  fd.total_linea_bob
from {{ ref('stg_fin__factura_detalle') }} fd
left join {{ ref('stg_fin__factura') }} f
  on fd.id_factura = f.id_factura
left join {{ ref('stg_comercial__orden_servicio') }} os
  on fd.id_orden_servicio = os.id_orden_servicio
left join {{ ref('stg_ops__envio') }} en
  on fd.id_envio = en.id_envio
left join rutas_tarifa rt
  on os.id_tarifa_detalle = rt.id_tarifa_detalle
