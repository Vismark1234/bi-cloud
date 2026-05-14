with detalles as (
  select
    fd.id_factura_detalle,
    fd.id_factura,
    fd.id_envio,
    fd.id_orden_servicio,
    fd.cantidad,
    fd.precio_unitario_bob,
    fd.total_linea_bob,
    f.fecha_emision
  from {{ ref('stg_fin__factura_detalle') }} fd
  left join {{ ref('stg_fin__factura') }} f
    on fd.id_factura = f.id_factura
),
detalle_envio_canonico as (
  select
    id_factura_detalle,
    id_factura,
    id_envio,
    id_orden_servicio,
    cantidad,
    precio_unitario_bob,
    total_linea_bob,
    fecha_emision
  from detalles
  where id_envio is not null
  qualify row_number() over (
    partition by id_envio
    order by fecha_emision desc nulls last, id_factura desc, id_factura_detalle desc
  ) = 1
),
detalle_orden_sin_envio as (
  select
    id_factura_detalle,
    id_factura,
    id_envio,
    id_orden_servicio,
    cantidad,
    precio_unitario_bob,
    total_linea_bob,
    fecha_emision
  from detalles
  where id_envio is null
    and id_orden_servicio is not null
)
select * from detalle_envio_canonico
union all
select * from detalle_orden_sin_envio
