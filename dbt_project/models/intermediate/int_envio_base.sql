with ruta_tarifa as (
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
  e.id_envio,
  e.id_orden_servicio,
  os.id_reserva_credito,
  cred.id_cuenta_credito,
  os.id_cliente,
  os.id_contrato,
  coalesce(os.id_tarifa_detalle, 0) as id_tarifa_detalle,
  coalesce(e.id_sucursal_origen, tar.id_sucursal_origen_ref) as id_sucursal_origen,
  coalesce(e.id_sucursal_destino, tar.id_sucursal_destino_ref) as id_sucursal_destino,
  coalesce(e.id_ruta_referencia, rt.id_ruta) as id_ruta,
  os.fecha_creacion,
  os.vigencia_hasta,
  e.fecha_registro,
  e.fecha_compromiso_listo_recojo,
  ec.fecha_cierre_envio,
  ec.fecha_cumplimiento_sla,
  os.estado_orden,
  ec.estado_final_codigo,
  e.peso_kg,
  e.volumen_m3,
  e.valor_declarado_bob,
  fact.monto_facturado_bob,
  fact.cantidad_lineas_facturadas
from {{ ref('stg_ops__envio') }} e
left join {{ ref('stg_comercial__orden_servicio') }} os
  on e.id_orden_servicio = os.id_orden_servicio
left join {{ ref('int_envio_cierre') }} ec
  on e.id_envio = ec.id_envio
left join {{ ref('int_tarifa_base') }} tar
  on os.id_tarifa_detalle = tar.id_tarifa_detalle
left join ruta_tarifa rt
  on os.id_tarifa_detalle = rt.id_tarifa_detalle
left join {{ ref('int_credito_asof_orden') }} cred
  on e.id_orden_servicio = cred.id_orden_servicio
left join {{ ref('int_facturacion_por_envio') }} fact
  on e.id_envio = fact.id_envio
